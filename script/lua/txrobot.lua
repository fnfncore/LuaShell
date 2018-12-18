--
-- txrobot.lua
--

local txrobot = { _version = "0.1" }

local rpc = require("rpc")
local node = require("node")
local key = require("key")

local function sendtx(host, port, from, to, fork, count)
  local host, port = node.rpchost(index), node.rpcport(index)
  local err, forks = rpc:sethost(host, port).listfork()
  if err == 0 and forks[to] then
    for i = 1, 5 do
      local f = forks[to]["fork"]
      local fromaddr = key.keypair[from][1]["pubkeyaddr"]
      local toaddr = key.keypair[to][1]["pubkeyaddr"]
      rpc:sethost(host, port).sendfrom(fromaddr, toaddr, 0.000001, nil, f)
    end
  end
end

function txrobot.run(index, count)
  local host, port = node.rpchost(index), node.rpcport(index)
  local from = key.keypair[index][1]["pubkeyaddr"]
  local to = key.keypair[index % 50 + 1][1]["pubkeyaddr"]
  rpc:sethost(host, port).unlockkey(pubkeyaddr, "123")

  while running do
    local err, forks = rpc:sethost(host, port).listfork()
    if err == 0 and #forks > 1 then
      local per = count // (#forks - 1)
      local realcount = per * (#forks - 1)
      for i = 1, #forks do
        local fork = forks[i]["fork"]
        if fork ~= rpc.genesis then
          rpc:asyncstart(sendtx, host, port, from, to, fork, per)
        end
      end
      print("wait for work:" .. realcount .. " done:" .. rpcasyncwait(1000))
    else
      print("listfork error")
      sleep(1000)
    end
  end
end

return txrobot