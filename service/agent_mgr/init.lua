local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")

-- 状态(枚举 lua表)
STATUS = {
    LOGIN = 1,
    PLAYING = 2,
    OFFLINE = 3
}

-- 玩家列表
local players = {} -- player_id -> mgrPlayer

function mgrPlayer()
    local m = {
        player_id = nil,
        node = nil, -- 玩家对应 gateway 和 agent 所在的节点
        agent = nil, -- 玩家对应的agent服务的id
        status = nil,
        gate = nil, -- 玩家对应的gate服务的id
    }
    return m
end

function s.init()

end

s.resp.req_login = function(addr, player_id, node, gate)
    local mplayer = players[player_id]

    -- 登录过程中 禁止操作
    if mplayer and mplayer.start == STATUS.OFFLINE then
        skynet.error("玩家已经下线，重新登录")
        return false
    end
    if mplayer and mplayer.start == STATUS.LOGIN then
        skynet.error("玩家已经登录，不能重复登录")
        return false
    end

    if mplayer then
        print("在线，顶替")
        local player_node = mplayer.node
        local player_agent = mplayer.agent
        local player_gate = mplayer.gate
        mplayer.start = STATUS.OFFLINE
        -- 踢出
        s.call(player_node, player_agent, "kick")

        -- 关闭 agent服务
        s.send(player_node, player_agent, "exit")

        -- 发给 player_id 消息
        s.send(player_node, player_gate, "send", player_id, { "kick", "你被顶替下线" })

        -- 踢出用户结束fd
        s.call(player_node, player_gate, "kick", player_id)
    end

    -- 上线
    print("将该用户信息 记录到 mgr_players")
    local player = mgrPlayer()
    player.player_id = player_id
    player.node = node
    player.gate = gate
    player.status = STATUS.LOGIN
    player.agent = nil

    -- 引用关系，下方修改也生效
    players[player_id] = player

    print("给改用户建立一个agent，并且绑定gate&agent", node)
    local agent = s.call(node, "node_mgr", 'newservice', "agent", "agent", player_id)
    player.agent = agent
    player.status = STATUS.LOGIN

    print("req_login over")
    return true, agent
end

s.resp.kick = function(addr, player_id, reason)
    local mplayer = players[player_id]
    if not mplayer then
        skynet.error("玩家不存在")
        return false
    end

    --if mplayer.status ~= STATUS.PLAYING then
    --    skynet.error("玩家不在线")
    --    return false
    --end

    local player_node = mplayer.node
    local player_agent = mplayer.agent
    local player_gate = mplayer.gate
    mplayer.start = STATUS.OFFLINE
    -- 踢出
    s.call(player_node, player_agent, "kick")

    -- 退出
    s.send(player_node, player_agent, "exit")

    s.send(player_node, player_gate, "kick", player_id)

    players[player_id] = nil

    return true
end

s.resp.shutdown = function(addr, number)
    print("agent_mgr shutdown", addr,number)
    local count = 0
    for player_id, mplayer in pairs(players) do
        --if mplayer.status == STATUS.PLAYING then
        count = count + 1
        --end
    end

    local exec_count = 0
    for player_id, mplayer in pairs(players) do
        print("user kick player_id ", player_id)
        skynet.fork(s.resp.kick, nil, player_id, "服务器关闭")
        exec_count = exec_count + 1
        if exec_count >= number then
            break
        end
    end
    local ret = count - exec_count
    if ret <= 0 then
        ret = 0
    end
    return ret
end

s.start(...)
