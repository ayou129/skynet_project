return {
    -- 集群
    cluster = {
        node1 = "127.0.0.1:9701",
        node2 = "127.0.0.1:9801",
    },
    -- agentmgr 全局唯一服务 在节点1这个节点上
    agentmgr = {
        node = "node1"
    },
    -- scene
    scene = {
        node1 = {
            1001, 1002 -- 战斗场景1001、1002 在node1这
        },
        -- node2 = {1003}, -- 战斗场景1003 在node2这
    },
    -- 节点1
    node1 = {
        gateway = {
            port = 9702,
            maxclient = 1024,
            nodelay = true,
        },
        login = {
            port = 9711,
            maxclient = 1024,
            nodelay = true,
        },
    },
    -- 节点2
    node2 = {
        gateway = {
            port = 9802,
            maxclient = 1024,
            nodelay = true,
        },
        login = {
            port = 9811,
            maxclient = 1024,
            nodelay = true,
        },
    }
}