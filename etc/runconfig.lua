return {
    -- 集群
    cluster = {
        node1 = "127.0.0.1:9701",
        node2 = "127.0.0.1:9801",
    },
    -- agent_mgr 全局唯一服务 在节点1这个节点上
    agent_mgr = {
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
            [1] = { port = 9702 },
            [2] = { port = 9703 },
        },
        login = {
            [1] = {},
            [2] = {},
        },
    },
    -- 节点2
    node2 = {
        gateway = {
            [1] = { port = 9802 },
            [2] = { port = 9803 },
        },
        login = {
            [1] = {},
            [2] = {},
        },
    }
}