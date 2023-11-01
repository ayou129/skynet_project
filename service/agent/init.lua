local skynet = require("skynet")
local s = require("service")

s.client = {}
s.gate = nil

require "scene"

s.resp.client = function(addr, cmd, msg)
    s.gate = addr
    local ret_msg = ""
    if s.client[cmd] then
        ret_msg = s.client[cmd](msg, addr)
        if ret_msg then
            skynet.send(addr, "lua", "send", s.id, ret_msg)
        end
    else
        ret_msg = { "ret_err", -1, "request not found" }
        skynet.error("request not found", cmd)
    end
end

s.resp.kick = function(addr)
    s.leave_scene()
    --在此处保存角色数据
    skynet.sleep(200)
end

s.resp.exit = function(addr)
    skynet.exit()
end

s.client.work = function(msg)
    s.data.coin = s.data.coin + 1
    return {
        "work",
        s.data.coin
    }
end

s.resp.send = function(addr, msg)
    skynet.send(s.gate, "lua", "send", s.id, msg)
end

s.init = function()
    -- db 加载用户数据，这里使用模拟十句
    s.data = {
        coin = 100,
        hp = 200,
        last_login_time = 1582725978
    }

    -- 定时唤醒

end

s.start(...)