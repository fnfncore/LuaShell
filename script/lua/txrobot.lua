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

function txrobot.run(index, count, fork)
  local host, port = node.rpchost(index), node.rpcport(index)
  local from = key.keypair[index][1]["pubkeyaddr"]
  local to = key.keypair[index % 50 + 1][1]["pubkeyaddr"]
  rpc.unlockkeyhost(host, port, from, "123")

  local works = 0
  while running do
    local t0 = os.time()
    local err, forks = rpc.listforkhost(host, port)
    if err == 0 and #forks > 1 then
      local per = fork and count or count // (#forks - 1)
      for i, v in ipairs(forks) do
        local f = v["fork"]
        if (fork and fork == f) or fork ~= rpc.genesis then
          sendtx(host, port, from, to, fork, per)
        end
      end
    else
      sleep(1000)
    end
    local t1 = os.time()
    print("tx",(t1 - t0) * 1.0 / count)
  end
end

return txrobot