--
-- txrobot.lua
--

local txrobot = { _version = "0.1" }

local rpc = require("rpc")
local node = require("node")
local key = require("key")

local function sendtx(from, to)
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

function txrobot.run(index)
  while running do
    for i = 1, 20 do
      if i ~= index then
        rpc:asyncstart(sendtx, index, i)
      end
    end
    print("wait", rpcasyncwait(1000))
  end
end

return txrobot