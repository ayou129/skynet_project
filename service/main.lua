local skynet = require("skynet")
local runonfig = require("runconfig")

skynet.start(function()
    print(1)
    skynet.error("Server start. node1:" .. runonfig.cluster.node1)
    --skynet.newservice("debug_console", 8000)
    skynet.exit()
end)