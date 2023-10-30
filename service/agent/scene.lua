local skynet = require("skynet")
local runconfig = require "runconfig"
local s = require("service")
local node = skynet.getenv("node")

s.scene_node = nil -- scene_node
s.scene_name = nil -- scene_name

local function random_scene()
    local nodes = {}
    for i, v in pairs(runconfig.scene) do
        table.insert(nodes, i)
        if runconfig.scene[node] then
            -- 提高同一节点的概率
            table.insert(nodes, node)
        end
    end

    -- 生成一个随机数 idx，该数在 1 和 nodes 表格的长度之间。
    local idx = math.random(1, #nodes)
    local scene_node = nodes[idx]

    -- 具体场景
    local scene_list = runconfig.scene[scene_node]
    local idx = math.random(1, #scene_list)
    local scene_id = scene_list[idx]
    return scene_node, scene_id

end

s.leave_scene = function()
    -- 不在场景
    if not s.scene_name then
        return
    end
    s.call(s.scene_node, s.scene_name, "leave", s.id)
    s.scene_node = nil
    s.scene_name = nil
end

s.client.enter = function(msg)
    print('agent scene enter')
    if s.scene_name then
        return { "enter", 1, "已在游戏" }
    end
    local scene_node, scene_id = random_scene()
    local scene_name = "scene" .. scene_id
    local is_ok = s.call(scene_node, scene_name, "enter", scene_id, node, skynet.self())
    if not is_ok then
        return { "enter", 1, "进入游戏失败" }
    end
    s.scene_node = scene_node
    s.scene_name = scene_name
    return nil
end

s.client.shift = function(msg)
    if not s.scene_name then
        return
    end
    local x = tonumber(msg[2]) or 0
    local y = tonumber(msg[3]) or 0
    s.call(s.scene_node, s.scene_name, "shift", s.id, x, y)
end

s.init = function()
    skynet.error("agent scene")
end
s.start(...)