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

function txrobot.run(index, fork, sleepvalue)
  local host, port = node.rpchost(index), node.rpcport(index)
  local from = key.getpubkeyaddr(index,1)
  local to = key.getpubkeyaddr(index % 50 + 1,1)
  rpc.unlockkeyhost(host, port, from, "123")

  print("index:", index, "fork:", fork, "form:", from, "to:", to)

  local works = 0
  local sendtx_count = 0
  local sendtx_count_prev = 0
  local start_time = os.time()
  while running do
    local t0 = os.time()
    local err, forks = rpc.listforkhost(host, port)
    if err == 0 and #forks > 1 then
      for i, v in ipairs(forks) do
        local f = v["fork"]
        if (fork and fork == f) or (not fork and f ~= rpc.genesis) then
          sendtx(host, port, from, to, f, 1)
          sendtx_count = sendtx_count + 1
          if sleepvalue > 0 then
            sleep(sleepvalue)
          end
        end
      end
    else
      sleep(1000)
    end
    if os.time() - start_time >= 1 then
      start_time = os.time()
      print(os.time(), "total:", sendtx_count, "tps:", sendtx_count-sendtx_count_prev)
      sendtx_count_prev = sendtx_count
    end
  end
end

return txrobot