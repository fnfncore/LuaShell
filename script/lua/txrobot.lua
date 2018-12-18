--
-- txrobot.lua
--

local txrobot = { _version = "0.1" }

local rpc = require("rpc")
local node = require("node")
local key = require("key")

local function sendtx(host, port, from, to, fork, count)
  for i = 1, count do
    local err, ret = rpc.sendfromhost(host, port, from, to, 0.000001, nil, fork)
    if err ~= 0 then
      print(ret)
    end
  end
end

function txrobot.run(index, count)
  local host, port = node.rpchost(index), node.rpcport(index)
  local from = key.keypair[index][1]["pubkeyaddr"]
  local to = key.keypair[index % 50 + 1][1]["pubkeyaddr"]
  rpc.unlockkeyhost(host, port, from, "123")

  local works = 0
  -- while running do
    local err, forks = rpc.listforkhost(host, port)
    print(err, forks, host, port)
    if err == 0 and #forks > 1 then
      local per = count // (#forks - 1)
      local realcount = per * (#forks - 1)
      works = works + realcount
      for i, v in ipairs(forks) do
        local fork = v["fork"]
        if fork ~= rpc.genesis then
          -- rpc.asyncstart(sendtx, host, port, from, to, fork, per)
          sendtx(host, port, from, to, fork, per)
        end
      end
      print("waiting... " .. realcount)
      local w = rpcasyncwait(1000)
      print("completed... " .. w)
      works = works - w
      while works > 100 and running do
        w = rpcasyncwait(1000)
        works = works - w
      end
    else
      sleep(1000)
    end
  -- end
end

return txrobot