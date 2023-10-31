local skynet = require("skynet")
local socket = require("skynet.socket")
--local protobuf = require("protobuf")
local s = require("service")
local runconfig = require("runconfig")

-- socket fd 通过 gateway -> conn，通过pid 找到player agent

conns = {}
gate_players = {}
s.client = {}
local closing = false

function conn()
    local m = {
        fd = nil, -- index
        player_id = nil
    }
    return m
end

s.resp.shutdown = function()
    closing = true
end

function gatePlayer()
    local m = {
        player_id = nil, -- index
        agent = nil,
        conn = nil
    }
    return m
end


-- 解码 msg_str = 'login,101,102'
local protobuf_str_unpack = function(msg_str)
    -- TODO
end

-- 编码 lua表 -> ,关联的字符串
local protobuf_str_pack = function(cmd, msg)
    -- TODO
end

local str_unpack = function(msg_str)
    local msg = {}
    while true do
        local arg, rest = string.match(msg_str, "(.-),(.*)")
        if arg then
            msg_str = rest
            table.insert(msg, arg)
        else
            table.insert(msg, msg_str)
            break
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

function process_msg(fd, msg_str)
    local cmd, msg = str_unpack(msg_str)
    skynet.error("recv " .. fd .. " [" .. cmd .. "] {" .. table.concat(msg, ",") .. "}")

    local conn = conns[fd]
    local player_id = conn.player_id

    if not player_id then
        -- 未登录，gate -> login agent，设置gate_players
        local node = skynet.getenv("node")
        local node_cfg = runconfig[node]
        local login_id = math.random(1, #node_cfg.login)
        local login = "login" .. login_id
        skynet.send(login, "lua", "client", fd, cmd, msg)
    else
        local gate_player = gate_players[player_id]
        local agent = gate_player.agent
        skynet.send(agent, "lua", "client", cmd, msg)
    end
end

local process_buff = function(fd, buff)
    while true do
        -- 取出第一条消息 和 剩余的部分
        local msg_str, rest = string.match(buff, "^(.-)\r\n(.*)")
        if msg_str then
            buff = rest
            process_msg(fd, msg_str)
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
        skynet.call("agent_mgr", "lua", "kick", player_id, reason)
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
    print('connect fd', fd, addr)
    if closing then
        skynet.error("[Gateway ban!] fd:" .. fd .. " addr:" .. addr)
        return
    end

    skynet.error("[Gateway connect] fd:" .. fd .. " addr:" .. addr)
    local c = conn()

    conns[fd] = c
    c.fd = fd

    -- 接收客户端消息
    skynet.fork(recv_loop, fd)
end

-- 向指定fd发送消息
s.resp.send_by_fd = function(addr, fd, msg)
    if not conns[fd] then
        return
    end

    local buff = str_pack(msg[1], msg)
    skynet.error("[Gateway send] fd:" .. fd .. " buff:" .. buff)
    socket.write(fd, buff)
end

-- 向指定玩家发送消息
s.resp.send = function(addr, player_id, msg)
    local gate_player = gate_players[player_id]
    if gate_player == nil then
        return
    end

    local gate_player_conn = gate_player.conn
    if gate_player_conn == nil then
        return
    end

    s.resp.send_by_fd(nil, gate_player_conn.fd, msg)
end

-- 登录成功；绑定网关和agent
s.resp.login_success = function(addr, fd, player_id, agent)
    local conn = conns[fd]
    if not conn then
        -- 登录过程中已经下线
        skynet.call("agent_mgr", "lua", "kick", player_id, "未完成登录，将其下线")
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

-- 踢出
s.resp.kick = function(addr, player_id)
    local gate_player = gate_players[player_id]
    if not gate_player then
        return
    end

    gate_players[player_id] = nil

    local old_conn = gate_player.conn
    if not old_conn then
        return
    end
    conns[old_conn.fd] = nil

    disconnect(old_conn.fd)
    socket.close(old_conn.fd)
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
s.resp.client = function(addr, fd, cmd, msg)
    if s.client[cmd] then
        local ret_msg = s.client[cmd](fd, msg, addr)
        skynet.send(addr, "lua", "send_by_fd", fd, ret_msg)
    else
        skynet.error("s.resp.client fail : [" .. cmd .. "]")
    end
end

-- ... 为传入的参数，skynet.newservice('服务类型', '参数1', '参数2') 传入的参数
s.start(...)