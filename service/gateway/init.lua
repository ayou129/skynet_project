local skynet = require("skynet")
local s = require("service")

function s.init()
    skynet.error("[Gateway init] name:" .. s.name .. " id:" .. s.id)
end

s.start(...)