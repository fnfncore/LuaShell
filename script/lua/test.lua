--
-- test.lua
--

local rpc = require("rpc")

function task()
  for i = 1, 5 do
      err, msg = rpc.help("stop")
      print("asynchronous help return", i, coroutine.running(), err)
  end
end

if running then
  -- asynchronous call
  print("asynchronous...")
  for i = 1, 20 do
    rpc.asyncstart(task)
  end
  print("async wait", rpcasyncwait(1000))

  -- asynchronous call
  print("synchronous...")
  for i = 1, 100 do
    err, msg = rpc.help("stop")
    print("synchronous help return", i, err)
  end
end