local skynet = require("skynet")
local s = require("service")

s.resp.client = function(source, cmd, msg)
    s.gate = source
    if s.client[cmd] then
        local ret_msg = s.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", s.id, ret_msg)
        end
    else
        skynet.error("s.resp.client fail! cmd:" .. cmd)
    end
end
s.resp.kick = function(source)
    -- 保存角色数据
end
s.resp.exit = function(source)
    skynet.exit()
end

s.client.work = function(msg)
    s.data.coin = s.data.coin + 1
    return {
        "work",
        s.data.coin
    }
end

s.init = function()
    -- db 加载用户数据，这里使用模拟十句
    s.data = {
        coin = 100,
        hp = 200
    }
end

s.start(...)