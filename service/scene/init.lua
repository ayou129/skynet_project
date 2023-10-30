local skynet = require("skynet")
local s = require("service")

local balls = {} -- index player_id
function getBall()
    local m = {
        player_id = nil,
        agent = nil,
        node = nil,
        x = math.random(0, 100),
        y = math.random(0, 100),
        size = 2,
        speed_x = 0, -- x方向移动速度
        speed_y = 0, -- y方向移动速度
    }
    return m
end

-- 球列表：辅助方法，收集所有的球，构建ball_list协议
local function ball_list_msg()
    local msg = { "ball_list" }
    for i, v in pairs(balls) do
        table.insert(msg, v.player_id)
        table.insert(msg, v.x)
        table.insert(msg, v.y)
        table.insert(msg, v.size)
    end
    return msg
end

local foods = {} -- index food_id
local food_count = 0 -- 食物数量
local food_current_id = 0
function getFood()
    local m = {
        id = nil,
        x = math.random(0, 100),
        y = math.random(0, 100)
    }
    return m
end

-- 食物列表：辅助方法，收集所有的球，构建ball_list协议
local function food_list_msg ()
    local msg = { "food_list" }
    for i, v in pairs(foods) do
        table.insert(msg, v.id)
        table.insert(msg, v.x)
        table.insert(msg, v.y)
    end
    return msg
end

-- 广播给所有人
function broadcast(msg)
    for i, v in pairs(balls) do
        s.send(v.node, v.agent, "send", msg)
    end
end

s.resp.enter = function(addr, player_id, node, agent)
    print("scene init enter")
    if balls[player_id] then
        skynet.error("enter fail", player_id)
        return false
    end

    local ball = getBall()
    ball.player_id = player_id
    ball.agent = agent
    ball.node = node

    -- 将球加入到球列表
    balls[player_id] = ball

    -- 广播给所有人
    local enter_msg = { "enter", player_id, ball.x, ball.y, ball.size }
    broadcast(enter_msg)

    -- 回应
    local ret_msg = { "enter", 0, "进入成功" }
    s.send(ball.node, agent, "send", ret_msg)

    -- 发送战场消息
    s.send(ball.node, agent, "send", ball_list_msg())
    s.send(ball.node, agent, "send", food_list_msg())
    return true
end

s.resp.leave = function(addr, player_id)
    if not balls[player_id] then
        return false
    end
    balls[player_id] = nil

    local leave_msg = { "leave", player_id }
    broadcast(leave_msg)
end

s.resp.shift = function(addr, player_id, x, y)
    local b = balls[player_id]
    if not b then
        return false
    end
    b.speed_x = x
    b.speed_y = y
end

function move_update()
    local zhen = 0.2
    for i, v in pairs(balls) do
        if v.speed_x ~= 0 or v.speed_y ~= 0 then
            v.x = v.x + v.speed_x * zhen
            v.y = v.y + v.speed_y * zhen
            local msg = { "move", v.player_id, v.x, v.y }
            broadcast(msg)
        end
    end
end
function food_update()
    if food_count > 50 then
        return
    end

    food_count = food_count + 1
    food_current_id = food_current_id + 1

    local food = getFood()
    food.id = food_current_id
    foods[food_current_id] = food

    local msg = { "food_add", food.id, food.x, food.y }
    broadcast(msg)
end
function eat_update ()
    -- 如果 food球的位置进入到了圆球中，那么就吃掉
    for player_id, food in pairs(foods) do
        for food_id, ball in pairs(balls) do
            local dx = food.x - ball.x
            local dy = food.y - ball.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < ball.size then
                -- 吃掉
                ball.size = ball.size + 1
                food_count = food_count - 1
                foods[food_id] = nil
                local msg = { "food_eat", food_id, b.size }
                broadcast(msg)
            end
        end
    end
end
function update(frame)
    food_update()
    move_update()
    eat_update()
end

--s.resp.move = function(addr, player_id, x, y)
--
--end

s.init = function()
    skynet.fork(function()
        -- 保持帧率执行
        local s_time = skynet.now()
        local frame = 0
        while true do
            local is_ok, err = pcall(update, frame)
            if not is_ok then
                skynet.error(err)
            end
            local e_time = skynet.now()

            -- 每次循环后需要等待的时间 0.2s
            local wait_time = frame * 20 - (e_time - s_time)
            if wait_time <= 0 then
                wait_time = 2
            end
            skynet.sleep(wait_time)
        end
    end)
end

s.start(...)
