---
--- docker.lua
--- Created by gaoc.
--- DateTime: 3/21/19 5:11 PM
---


local docker = { _version = "0.1" }
local util = require('util')
local rpc = require('rpc')

docker.workspace = '~/containers'
docker.bridgename = 'fnfn_bridge'
docker.rootrpchost = '127.0.0.1'
docker.rootrpcport = 6911
docker.forks = {}
docker.hosts = {
    fork1 = {
        forkid = '3aa54fdfa879c6ac1d0dc17439ff512e26421af91c8526d5678cb5e20a560a94',
        phost = 'root',
        pport = 6815,
        rpcport = 6912
    },
    fork2 = {
        forkid = '4e6c8b83731dafbf55f151c659db74936ebfc85c855053476f71025afcdd56f1',
        phost = 'root',
        pport = 6815,
        rpcport = 6913
    }
}

local existdir = function(path)
    if os.execute('cd ' .. path .. ' > /dev/null 2>&1') then
        return true
    end
    return false
end

local mkdir = function(path)
    if os.execute('mkdir -p ' .. path .. ' > /dev/null 2>&1') then
        return true
    end
    return false
end

local setnetwork = function()
    os.execute('docker network create --driver bridge ' .. docker.bridgename .. '> /dev/null 2>&1')
end

local sleep = function (n)
    os.execute("sleep " .. n)
end

function docker.test()
    if os.execute('docker container run hello-world > /dev/null 2>&1') then
        return true
    end
    return false
end

function docker.initenv()
    setnetwork()
    if not os.execute('docker pull fissionandfusion/multiverse > /dev/null 2>&1') then
        return 1
    end
    if not existdir(docker.workspace) then
        if not mkdir(docker.workspace) then
            return 2
        end
    end
    return 0
end

function docker.rootnode(name, remotehost, remoteport, rpcport)
    local path = docker.workspace .. '/' .. name .. '/'
    if not existdir(path) then
        if not mkdir(path) then
            return 1
        end
    end
    local args = 'multiverse' ..
            ' -rpclisten4' ..
            ' -rpcallowip="*.*.*.*"' ..
            ' -addnode=' .. remotehost ..
            ' -port=' .. remoteport ..
            ' -dbpallowip="*.*.*.*"' ..
            ' -enablesupernode=true' ..
            ' -enableforknode=false'
    -- local cmd = 'docker run --rm -d --name ' .. name .. ' --network ' .. docker.bridgename .. ' -p ' .. rpcport .. ':6812 -v ' .. path .. ':/home fissionandfusion/multiverse:latest ' .. args .. ''
    local cmd = 'docker run --rm -d --name ' .. name .. ' --network ' .. docker.bridgename .. ' -p ' .. rpcport .. ':6812 -v ' .. path .. ':/home multiverse:latest ' .. args .. ''
    if not os.execute(cmd) then
        return 2
    end
    return 0
end

function docker.forknode(name, forkid, dbpparenthost, rpcport)
    local path = docker.workspace .. '/' .. name .. '/'
    if not existdir(path) then
        if not mkdir(path) then
            return 1
        end
    end
    local args = 'multiverse' ..
            ' -dbpallowip="*.*.*.*"' ..
            ' -dbpparentnodeip=' .. dbpparenthost ..
            ' -addfork=' .. forkid ..
            ' -enablesupernode=true' ..
            ' -enableforknode=true'
    -- local cmd = 'docker run --rm -d --name ' .. name .. ' --network ' .. docker.bridgename .. ' -p ' .. rpcport .. ':6812 -v ' .. path .. ':/home fissionandfusion/multiverse:latest ' .. args .. ''
    local cmd = 'docker run --rm -d --name ' .. name .. ' --network ' .. docker.bridgename .. ' -p ' .. rpcport .. ':6812 -v ' .. path .. ':/home multiverse:latest ' .. args .. ''
    if not os.execute(cmd) then
        return 2
    end
    docker.forks[name] = forkid;
    return 0
end

function docker.startfnode(name)
    local host = docker.hosts[name]
    docker.forknode(name, host['forkid'], host['phost'], host['rpcport'])
end

function docker.purge(name)
    docker.stopnode(name)
    local path = docker.workspace .. '/' .. name .. '/'
    local args = 'multiverse -purge'
    local cmd = 'docker run --rm -d --name ' .. name .. ' -v ' .. path .. ':/home fissionandfusion/multiverse:latest ' .. args .. ''
    os.execute(cmd)
end

function docker.purgeall()
    for k, v in pairs(docker.forks) do
        docker.purge(k)
    end
end

function docker.stopnode(name)
    local cmd = 'docker container stop ' .. name
    os.execute(cmd)
    docker.forks[name] = nil
end

function docker.start()
    docker.rootnode('root', 'node', 6811, docker.rootrpcport)

    docker.forks = {}
    for k, v in pairs(docker.hosts) do
        docker.forknode(k, v["forkid"], v["phost"], v["rpcport"])
    end
end

function docker.stop()
    err, ret = rpc.callhost('stop', docker.rootrpchost, docker.rootrpcport)
end

local forkcount = function()
    local i = 0
    for k, v in pairs(docker.forks) do
        i = i + 1
    end

    return i
end

function docker.listfork_test()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('listfork', docker.rootrpchost, docker.rootrpcport)
        if 0 == err then
           count = count + 1
        end
        i = i + 1
    until(i >= 10000)
    print('listfork testing, normal:' .. count)
end

function docker.getforkcount_test1()
    docker.stop()
    sleep(3)
    docker.start()

    sleep(3)

    local err
    local ret

    repeat
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
    until (err == 0)

    assert((forkcount() + 1) == ret, 'test failed! ret:' .. ret .. ', count:' .. (forkcount() + 1))

    docker.stopnode('fork1')
    sleep(1)

    repeat
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
    until (err == 0)
    assert((forkcount() + 1) == ret, 'test failed! ret:' .. ret .. ', count:' .. (forkcount() + 1))

    docker.stopnode('fork2')
    sleep(1)

    repeat
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
    until (err == 0)
    assert((forkcount() + 1) == ret, 'test failed! ret:' .. ret .. ', count:' .. (forkcount() + 1))

    docker.startfnode('fork1')
    sleep(1)

    repeat
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
    until (err == 0)
    assert((forkcount() + 1) == ret, 'test failed! ret:' .. ret .. ', count:' .. (forkcount() + 1))

    docker.startfnode('fork2')
    sleep(1)

    repeat
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
    until (err == 0)
    assert((forkcount() + 1) == ret, 'test failed! ret:' .. ret .. ', count:' .. (forkcount() + 1))

    print('getforkcount testing passed')
end

function docker.getforkcount_test2()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
        if 0 == err and 3 == ret then
            count = count + 1
        end
        i = i + 1
        print('getforkcount err:' .. err .. ', ret:' .. ret .. ', index:' .. i)
    until(i >= 10000)
    print('getforkcount testing, normal:' .. count)
end

function docker.getblockhash()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('getblockhash', docker.rootrpchost, docker.rootrpcport, 101)
        if 0 == err and 3 == ret then
            count = count + 1
        end
        i = i + 1
        print('getblockhash err:' .. err .. ', count:' .. count)
    until(i >= 10000)
    print('getblockhash testing, normal:' .. count)
end

function docker.listtransaction()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('listtransaction', docker.rootrpchost, 6812)
        if 0 == err then
            count = count + 1
        end
        i = i + 1
        print('listtransaction  err:' .. err .. ', count:' .. count)
    until(i >= 10000)
    print('listtransaction testing, normal:' .. count)
end

return docker