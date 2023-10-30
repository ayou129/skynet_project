local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")

s.client = {}

s.resp.client = function(addr, fd, cmd, msg)
    local ret_msg = ""
    if s.client[cmd] then
        ret_msg = s.client[cmd](fd, msg, addr)
    else
        ret_msg = { "ret_err", -1, "request not found" }
        skynet.error("request not found", cmd)
    end
    skynet.send(addr, "lua", "send_by_fd", fd, ret_msg)
end

s.client.login = function(fd, msg, addr)
    local player_id = tonumber(msg[2])
    local pw = tostring(msg[3])
    local gate = addr
    local node = skynet.getenv("node")
    -- 校验账号密码
    print(msg)
    if pw ~= "123" then
        return {
            "login",
            -1,
            "密码错误"
        }
    end

    --print("发送 agent_mgr")
    local is_ok, agent = skynet.call("agent_mgr", "lua", "req_login", player_id, node, gate)
    if not is_ok then
        return {
            "login",
            -1,
            "请求mgr失败"
        }
    end

    -- print("回应网关")
    local login_success = skynet.call(gate, "lua", "login_success", fd, player_id, agent)
    if not login_success then
        return {
            "login",
            -1,
            "gate注册失败"
        }
    end
    --print(3)
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