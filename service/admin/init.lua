local skynet = require("skynet")
local s = require("service")
local socket = require("skynet.socket")
local runconfig = require("runconfig")

local stop = function()
    -- 通知每个集群下的每个网关shutdown，阻止所有新的请求
    for node, _ in pairs(runconfig.cluster) do
        local node_config = runconfig[node]
        for i, v in pairs(node_config.gateway or {}) do
            print('gate shutdown', node, i)
            s.call(node, "gateway" .. i, "shutdown")
        end
    end

    -- 通过agent_mgr找到所有玩家，逐个下线所有玩家，并保存数据
    local agent_mgr_node = runconfig.agent_mgr.node
    while true do
        print('admin exec shutdown agent_mgr_node:', agent_mgr_node)
        local online_number = s.call(agent_mgr_node, "agent_mgr", "shutdown", 1)
        if online_number <= 0 then
            break
        end
        skynet.sleep(100)
    end

    -- 保存全局数据

    -- 关闭节点
end

local connect = function(fd, addr)
    socket.start(fd)
    socket.write(fd, "Welcome to skynet\n")
    while true do
        local cmd = socket.readline(fd, "\r\n")
        if cmd == 'stop' then
            -- 关服
            stop()
            socket.write(fd, "stop ok!\n")
        else
            socket.write(fd, "error cmd\n")
        end
    end
end

s.init = function()
    --skynet.newservice('debug_console', 8888)
    local listen_fd = socket.listen("0.0.0.0", 8889)
    socket.start(listen_fd, connect)
end

s.start(...)