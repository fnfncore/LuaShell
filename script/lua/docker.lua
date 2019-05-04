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

function docker.getforkcount_test2(n, c)
    local start_time = os.time()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('getforkcount', docker.rootrpchost, docker.rootrpcport)
        if 0 == err and c == ret then
            count = count + 1
        end
        i = i + 1
        print('getforkcount err:' .. err .. ', ret:' .. ret .. ', index:' .. i)
    until(i >= n)
    local end_time = os.time()
    local total_time = end_time - start_time;
    local average_time = total_time / n
    print('getforkcount testing, normal:' .. count .. ', time:' .. total_time .. ', avg time:' .. average_time)
end

docker.forks = {
    'd62c1fca5f2aacf9cf5738ed057d9987373508d8984734fa8fac05a6780a7cfd',
    'c3c7d25961b7f3b5a69d4b0b3756ec856815a596fb30c60346b15c7a66e087b9',
    '7303aa24ffa184d63f618d67750cbaac32377676a591879739f2b9899c39f346',
    'f1405b170aa36ed1fa0462b065536bd0ff231e9cb6aa7c38586a0df2c38ae46e',
    '6695266140184418c1f568b85dba8d4470bd4b09ab12618c4066ff3b25296a2c'
}

function is_in_table(value, tbl)
    for k,v in ipairs(tbl) do
        if v == value then
            return true;
        end
    end
    return false;
end

function docker.listfork(n, c)
    local i = 0
    local count = 0
    local start_time = os.time()
    repeat
        local err
        local ret
        err, ret = rpc.callhost('listfork', docker.rootrpchost, docker.rootrpcport)
        if 0 == err and c == #ret then
            count = count + 1
        end
        i = i + 1
        print('listfork err:' .. err .. ', ret:' .. ret .. ', index:' .. i)
    until(i >= n)
    local end_time = os.time()
    local total_time = end_time - start_time;
    local average_time = total_time / n
    print('listfork testing, normal:' .. count .. ', time:' .. total_time .. ', avg time:' .. average_time)
end

--getblockcount\getblocklocation\getblockhash\getblock
--docker.cross_test_fork = 'f1405b170aa36ed1fa0462b065536bd0ff231e9cb6aa7c38586a0df2c38ae46e'
docker.cross_test_fork = 'd62c1fca5f2aacf9cf5738ed057d9987373508d8984734fa8fac05a6780a7cfd'
function docker.cross_test(test_fork)
    local count = 0
    local err
    local ret
    err, ret = rpc.callhost('getblockcount', docker.rootrpchost, docker.rootrpcport, docker.cross_test_fork)
    print('getblockcount:' .. ret)
    if 0 == err then
        for i = 0, 280 do
            local err1, ret1 = rpc.callhost('getblockhash', docker.rootrpchost, docker.rootrpcport, i, docker.cross_test_fork)
            print(i .. '-1-getblockhash i:' .. i .. ', hash:' .. ret1[1])
            if err1 == 0 then
                local err2, ret2 = rpc.callhost('getblock', docker.rootrpchost, docker.rootrpcport, ret1[1])
                print(i .. '-2-getblock fork:' .. ret2['fork'] .. ', hash:' .. ret2['hash'])
                if err2 == 0 then
                    local err3, ret3 = rpc.callhost('getblocklocation', docker.rootrpchost, docker.rootrpcport, ret2['hash'])
                    print(i .. '-3-getblocklocation fork:' .. ret3['fork'] .. ', height' .. ret3['height'])
                    if err3 == 0 and ret3['height'] == i and docker.cross_test_fork == ret3['fork'] then
                        count = count + 1;
                    end
                end
            end
        end
    end
    print("cross test normal count:" .. count)
end

function docker.getblockcount(fork, n, c)
    local start_time = os.time()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('getblockcount', docker.rootrpchost, docker.rootrpcport, fork)
        if 0 == err and c == ret then
            count = count + 1
        end
        i = i + 1
        print('getblockcounbt err:' .. err .. ', ret:' .. ret .. ', index:' .. i)
    until(i >= n)
    local end_time = os.time()
    local total_time = end_time - start_time;
    local average_time = total_time / n
    print('getblockcount testing, normal:' .. count .. ', time:' .. total_time .. ', avg time:' .. average_time)
end

function docker.getblocklocation(test_hash, n)
    local start_time = os.time()
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('getblocklocation', docker.rootrpchost, docker.rootrpcport, test_hash)
        if 0 == err then
            count = count + 1
        end
        i = i + 1
        print('getblocklocation err:' .. err .. ', index:' .. i)
    until(i >= n)
    local end_time = os.time()
    local total_time = end_time - start_time;
    local average_time = total_time / n
    print('getblocklocation testing, normal:' .. count .. ', time:' .. total_time .. ', avg time:' .. average_time)
end

function docker.getblockhash()
end

function docker.getblock()
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

function docker.listtransaction(n)
    local i = 0
    local count = 0
    repeat
        local err
        local ret
        err, ret = rpc.callhost('listtransaction', docker.rootrpchost, docker.rootrpcport)
        if 0 == err then
            count = count + 1
        end
        i = i + 1
        print('listtransaction  err:' .. err .. ', count:' .. count)
    until(i >= n)
    print('listtransaction testing, normal:' .. count)
end

return docker