--
-- txrobot.lua
--

local txrobot = { _version = "0.1" }

local rpc = require("rpc")
local node = require("node")
local key = require("key")

local function sendtx(host, port, from, to, fork, count)
  for i = 1, count do
    if not running then
      return
    end

    local err, ret = rpc.sendfromhost(host, port, from, to, 0.000001, nil, fork)
    if err ~= 0 then
      print(ret)
    end
  end
end

function txrobot.run(index, fork)
  local host, port = node.rpchost(index), node.rpcport(index)
  local from = key.keypair[index][1]["pubkeyaddr"]
  local to = key.keypair[index % 50 + 1][1]["pubkeyaddr"]
  rpc.unlockkeyhost(host, port, from, "123")

  local works = 0
  while running do
    local t0 = os.time()
    local err, forks = rpc.listforkhost(host, port)
    if err == 0 and #forks > 1 then
      for i, v in ipairs(forks) do
        local f = v["fork"]
        if (fork and fork == f) or (not fork and f ~= rpc.genesis) then
          sendtx(host, port, from, to, f, 1)
        end
      end
    else
      sleep(1000)
    end
  end
end

return txrobot