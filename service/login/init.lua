local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")


s.client = {}
s.client.login = function(fd, msg, source)
    local player_id = tonumber(msg[2])
    local pw = tostring(msg[3])
    local gate = source
    local node = skynet.getenv("node")
    -- 校验账号密码
    if pw ~= 123 then
        return {
            "login",
            -1,
            "密码错误"
        }
    end
    local is_ok, agent = skynet.call(gate, "lua", "agent_mgr", fd, player_id, node, gate)
    if not is_ok then
        return {
            "login",
            -1,
            "请求mgr失败"
        }
    end
    local is_ok = skynet.call(gate, "lua", "sure_agent", fd, player_id, agent)
    if not is_ok then
        return {
            "login",
            -1,
            "gate注册失败"
        }
    end
    skynet.error("login success" .. player_id)
    return {
        "login",
        0,
        "登录成功"
    }
end

function s.init()
    --skynet.error("login init")
end

s.start(...)