# skynet_project

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