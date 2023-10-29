local skynet = require("skynet")
--local s = require("service")
local runconfig = require("runconfig")
local cluster = require("skynet.cluster")
local skynet_manager = require "skynet.manager" -- 下方的部分API需要用到

skynet.start(function()
    -- 初始化
    local node = skynet.getenv("node")
    local node_cfg = runconfig[node]

    -- 节点
    local debug_console = skynet.newservice('debug_console', '0.0.0.0', 8888)
    local node_mgr = skynet.newservice('node_mgr', "node_mgr", 0)
    skynet.name(".node_mgr", node_mgr) -- 设置别名 name,address
    --
    -- 集群
    cluster.reload(runconfig.cluster)
    cluster.open(node)

    -- Gateway
    for i, v in ipairs(node_cfg.gateway or {}) do
        local service = skynet.newservice('gateway', 'gateway', i)
        skynet.name("gateway" .. i, service) -- 设置别名 name,address
    end

    -- login
    for i, v in ipairs(node_cfg.login or {}) do
        local service = skynet.newservice('login', 'login', i)
        skynet.name("login" .. i, service) -- 设置别名 name,address
    end

    -- agent_mgr
    local agent_mgr_node = runconfig.agent_mgr.node
    if node == agent_mgr_node then
        local service = skynet.newservice('agent_mgr', 'agent_mgr', 0)
        skynet.name("agent_mgr", service) -- 设置别名 name,address
    else
        -- 放到集群代理对象中，可以正常通信
        local proxy = cluster.proxy(agent_mgr_node, "agent_mgr")
        skynet.name("agent_mgr", proxy) -- 设置别名 name,address
    end

    --print(1)
    --skynet.error("Server start. node1:" .. runconfig.cluster.node1)
    --skynet.newservice('gateway', 'gateway', 1)
    ----skynet.newservice("debug_console", 8000)
    --skynet.exit()
end)