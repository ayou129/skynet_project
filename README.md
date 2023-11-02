# skynet_project

start cmd
~~~
cd /Users/liguoxin/Desktop/web/learn/skynet_project

./skynet/skynet ./etc/config.node1

./skynet/skynet ./etc/config.node2

# 连接debug_console
telnet 127.0.0.1 8888

# 连接 node1 ，login,123,123
telnet 127.0.0.1 9702

# 连接 admin， stop
telnet 127.0.0.1 8889
~~~



gateway：网关
- conns：所有连接的fd
- gate_players：所有连接的在线玩家

agent_mgr：agent管理
- players：所有在线的玩家

node_mgr：节点管理服务 创建服务

login：登录agent

scene：副本agent


## 使用 protobuf

### macox
#### install pbc and lua-protobuf

~~~
brew install protobuf
brew install pbc
brew info pbc
-- find path = /opt/homebrew/Cellar/pbc/0.5.14/lib

cd ./luaclib
git clone git@github.com:cloudwu/pbc.git
cd pbc
make

cd pbc/binding/lua53
-- make前看清楚当前os
---- OS：macox
$(CC) $(CFLAGS) $(SHARED) -o $@ -I../.. -I$(LUADIR) -L../../build /opt/homebrew/Cellar/pbc/0.5.14/lib/libpbc.dylib
make


cp protobuf.so ../../../../luaclib
cp protobuf.lua ../../../../lualib

-- 编proto
protoc --descriptor_set_out login.pb login.proto
~~~

## Mysql
~~~
    pb.register_file("login.pb")
    
    -- 存储
    local data = {
        coin = 100,
        hp = 200
    }
    data = pb.encode("", data)
    local sql = string.format("insert into baseinfo(player_id, data) value (%d, '%s')", 109, "test", mysql.quote_sql_str(data))
    local res = db:query(sql)
    
    -- 读取
    local sql = string.format("select * from baseinfo where player_id = 109")
    local res = db:query(sql)
    if res[1] then
        local data = pb.decode("", res[1].data)
        print(data.coin)
        print(data.hp)
    end
~~~

## 关服
admin/console
> telnet 127.0.0.1 8888

## 常用逻辑
每天第一次登录逻辑
~~~

function get_data(timestamp)
    local day = (timestamp + 3600 * 8) / (3600 * 24)
    return math.ceil(day)
end

s.init = function()

    -- 获取和更新 登录时间
    local last_day = get_data(s.data.last_login_time)
    local day = get_data(os.time())
    s.data.last_login_time = os.time()

    -- 判断每天第一次登录
    if day > last_day then
        -- 每天第一次登录逻辑
        --first_login_day()
    end
end
~~~

定时唤醒
~~~
-- 开启服务器时间 从数据库读取
-- 关闭服务器时保存
local last_check_time = 1582935650

-- 1970年1月1日是星期四，所以我们要减去这个偏移量
function get_week_by_thu2040(timestamp)
    local week = (timestamp + 3600 * 8 - 3600 * 20 - 40 * 60) / (3600 * 24 * 7)
    return math.ceil(week)
end

function timer()
    local last = get_week_by_thu2040(last_check_time)
    local now = get_week_by_thu2040(os.time())
    last_check_time = os.time()
    if now > last then
        -- 开启活动
        --open_activity()
    end
end
~~~