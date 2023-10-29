local skynet = require("skynet")
local socket = require("skynet.socket")
local s = require("service")
local runconfig = require("runconfig")

-- socket fd 通过 gateway -> conn，通过pid 找到player agent

conns = {}
gate_players = {}
s.client = {}

function conn()
    local m = {
        fd = nil, -- index
        player_id = nil
    }
    return m
end

function gatePlayer()
    local m = {
        player_id = nil, -- index
        agent = nil,
        conn = nil
    }
    return m
end


-- 解码 msgstr = 'login,101,102'
local str_unpack = function(msgstr)
    local msg = {}
    while true do
        local arg, rest = string.match(msgstr, "(.-),(.*)")
        if arg then
            msgstr = rest
            table.insert(msg, arg)
        else
            table.insert(msg, msgstr)
            return msg
        end
    end
    -- cmd login
    -- msg {
    --    [1] = 'login',
    --    [2] = '101',
    --    [3] = '102'
    -- }
    return msg[1], msg
end

-- 编码 lua表 -> ,关联的字符串
local str_pack = function(cmd, msg)
    return table.concat(msg, ",") .. "\r\n"
end

function process_msg(fd, msgstr)
    print(fd, msgstr)
end

local process_buff = function(fd, buff)
    while true do
        -- 取出第一条消息 和 剩余的部分
        local msgstr, rest = string.match(buff, "^(.-)\r\n(.*)")
        if msgstr then
            buff = rest
            process_msg(fd, msgstr)
        else
            return buff
        end
    end
end

local disconnect = function(fd)
    local c = conns[fd]
    if not c then
        return
    end
    local player_id = c.player_id

    if not player_id then
        -- 还没完成登录
        return
    else
        -- 已经在游戏中
        gate_players[player_id] = nil
        local reason = "网络断开"
        skynet.call("agent_mgr", "lua", "reqkick", player_id, reason)
    end
end

function recv_loop(fd)
    socket.start(fd)
    local readbuff = ""
    while true do
        local str = socket.read(fd)
        if str then
            readbuff = readbuff .. str
            readbuff = process_buff(fd, readbuff)
        else
            skynet.error("[socket close] fd:" .. fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

local connect = function(fd, addr)
    skynet.error("[Gateway connect] fd:" .. fd .. " addr:" .. addr)
    local c = conn()
    c.fd = fd

    -- 接收客户端消息
    skynet.fork(recv_loop, fd)
end


s.resp.send_by_fd = function(source, fd, msg)
    if not conns[fd] then
        return
    end

    local buff = str_pack(msg[1], msg)
    skynet.error("[Gateway send] fd:" .. fd .. " buff:" .. buff)
    socket.write(fd, buff)
end

s.resp.send = function(source, player_id, msg)
    local p = gate_players[player_id]
    if p == nil then
        return
    end

    local c = gate_player.conn
    if c == nil then
        return
    end

    s.resp.send_by_fd(nil, c.fd, msg)
end

-- 关联 fd 和 player_id
s.resp.sure_agent = function(source, fd, player_id, agent)
    local conn = conns[fd]
    if not conn then
        -- 登录过程中已经下线
        skynet.call("agent_mgr", "lua", "reqkick", player_id, "未完成登录，将其下线")
        return false
    end

    conn.player_id = player_id
    local gate_player = gatePlayer()
    gate_player.player_id = player_id
    gate_player.agent = agent
    gate_player.conn = conn
    gate_players[player_id] = gate_player
    return true
end

function s.init()
    skynet.error("[Gateway init] name:" .. s.name .. " id:" .. s.id)

    local node = skynet.getenv("node")
    local node_cfg = runconfig[node]
    local port = node_cfg.gateway[s.id].port

    local listen_fd = socket.listen("0.0.0.0", port)
    skynet.error("[Gateway listen] port:" .. port)
    socket.start(listen_fd, connect)
end

-- 功能1.根据cmd 找到s.client.cmd 方法，并调用
-- 功能2.将s.client.cmd 方法的返回值，通过gateway返回给客户端
s.resp.client = function(source, fd, cmd, msg)
    if s.client[cmd] then
        local ret_msg = s.client[cmd](fd, msg, source)
        skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
    else
        skynet.error("s.resp.client fail : [" .. cmd .. "]")
    end
end

-- ... 为传入的参数，skynet.newservice('服务类型', '参数1', '参数2') 传入的参数
s.start(...)