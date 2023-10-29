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

s.resp.reqlogin = function(source, player_id, node, gate)
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

    -- 在线，顶替
    if mplayer then
        local pnode = mplayer.node
        local pagent = mplayer.agent
        local pgate = mplayer.gate
        mplayer.start = STATUS.OFFLINE
        -- 踢出
        s.call(pnode, pagent, "kick")

        -- 退出
        s.send(pnode, pagent, "exit")

        s.send(pnode, pgate, "send", player_id, { "kick", "你被顶替下线" })

        s.call(pnode, pgate, "kick", player_id)
    end

    -- 上线
    ---- 将该用户信息 记录到 mgr_players
    local player = mgrPlayer()
    player.player_id = player_id
    player.node = node
    player.gate = gate
    player.status = STATUS.LOGIN
    player.agent = nil
    players[player_id] = player

    ---- 给改用户建立一个agent，并且绑定gate&agent
    local agent = s.call(node, "node_mgr", 'newservice', "agent", "agent", player_id)
    player.agent = agent
    player.status = STATUS.LOGIN

    return true, agent
end

s.resp.reqkick = function(source, player_id, reason)
    local mplayer = players[player_id]
    if not mplayer then
        skynet.error("玩家不存在")
        return false
    end

    if mplayer.status ~= STATUS.PLAYING then
        skynet.error("玩家不在线")
        return false
    end

    local pnode = mplayer.node
    local pagent = mplayer.agent
    local pgate = mplayer.gate
    mplayer.start = STATUS.OFFLINE
    -- 踢出
    s.call(pnode, pagent, "kick")

    -- 退出
    s.send(pnode, pagent, "exit")

    s.send(pnode, pgate, "kick", player_id)

    players[player_id] = nil

    return true
end

s.start(...)
