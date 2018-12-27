--
-- exec.lua
--

local util = require("util")
local key = require("key")
local node = require("node")
local rpc = require("rpc")
local txrobot = require("txrobot")

local function getkeys(n)
  local keys = nil
  if n == 0 then
    keys = key.main
  else
    keys = key.keypair[n]
  end

  return keys
end

local function waittx(host, port, tx, tm, confirmed)
  local timeout = nil
  if tm and type(tm) == "number" then
    timeout = os.time() + tm
  end
  local err, ret = nil, nil
  while running do
    err, ret = rpc.gettransactionhost(host, port, tx)
    if err ~= 0 then
      print("Waiting transaction... " .. tx, err)
      sleep(5000)
    elseif confirmed and ret["transaction"]["confirmations"] == 0 then
      print("Waiting transaction confirmation... " .. tx, err)
      sleep(5000)
    else
      break
    end
  end
  return err
end

local function createconf(n, keys, miner)
  local dir = node.datadir(n)

  if util.direxist(dir) then
    print(dir .. " has been existed. ")
    return false
  end

  os.execute("mkdir -p " .. dir)
  io.output(dir.. "/multiverse.conf")
  if n == 0 then
    io.write("blake512address=" .. keys[1]["pubkeyaddr"] .. "\n")
    io.write("blake512key=" .. keys[2]["privkey"] .. "\n")
    io.write("mpvssaddress=" .. keys[1]["pubkeyaddr"] .. "\n")
    io.write("mpvsskey=" .. keys[2]["privkey"] .. "\n")
  elseif miner then
    io.write("mpvssaddress=" .. keys[1]["pubkeyaddr"] .. "\n")
    io.write("mpvsskey=" .. keys[2]["privkey"] .. "\n")
  else
    io.write("#mpvssaddress=" .. keys[1]["pubkeyaddr"] .. "\n")
    io.write("#mpvsskey=" .. keys[2]["privkey"] .. "\n")
  end
  io.write("rpcmaxconnections=200\n")
  io.write("maxconnections=200\n")
  io.write("listen\n")
  io.write("addgroup=" .. rpc.genesis .. "\n")
  if n ~= 0 then
    io.write("addnode=127.0.0.1:6811\n")
  end
  io.write("dbname=" .. node.dbname(n) .. "\n")
  io.write("port=" .. node.port(n) .. "\n")
  io.write("rpcport=" .. node.rpcport(n) .. "\n")
  io.write("dnseedport=" .. node.dnseedport(n) .. "\n")
  io.write("dbpport=" .. node.dbpport(n) .. "\n")
  io.flush()
  io.close()
  return true
end

local function newdpos(first, last, amount)
  local dpostxs = {}
  for i = first, last do
    local keys = getkeys(i)
    if keys and createconf(i, keys, true) then
      rpc.stophost(node.rpchost(i), node.rpcport(i))
      os.execute("mysql -uroot -p123456 -e \"drop database if exists " .. node.dbname(i) .. ";" ..
        "create database " .. node.dbname(i) .. " default charset utf8 collate utf8_general_ci;" ..
        "grant all on " .. node.dbname(i) .. ".* to multiverse@localhost;" ..
        "flush privileges;\"")
      
      os.execute("multiverse -debug -daemon -datadir=" .. node.datadir(i) .. " >> " .. node.log(i) .. " 2>&1")
      while running do
        sleep(5000)
        err, _ = rpc.importprivkeyhost(node.rpchost(i), node.rpcport(i), keys[1]["privkey"], "123")
        if err == 0 then
          break
        end
      end

      if i ~= 0 then
        rpc.unlockkey(key.main[1]["pubkeyaddr"], "123")
        local err, ret = rpc.listfork()
        if err ~= 0 then
          print("listfork error:", ret)
        else
          for _, v in ipairs(ret) do
            if v["fork"] ~= rpc.genesis then
              err, r = rpc.sendfrom(key.main[1]["pubkeyaddr"], keys[1]["pubkeyaddr"], 10000, nil, v["fork"])
              if err ~= 0 then
                print("sendfrom error to " .. keys[1]["pubkeyaddr"] .. " on " .. v["fork"] .. ": " .. r)
              end
            else
              err, ret = rpc.sendfrom(key.main[1]["pubkeyaddr"], keys[1]["pubkeyaddr"], amount)
              if err ~= 0 then
                print("sendfrom dpos token error to " .. keys[1]["pubkeyaddr"] .. ": " .. err, ret)
              else
                dpostxs[i] = ret
              end
            end
          end
        end
      end
    end
    sleep(1000)
  end
  return dpostxs
end

local function newwallet(first, last)
  for i = first, last do
    local keys = getkeys(i)
    if keys and createconf(i, keys) then
      rpc.stophost(node.rpchost(i), node.rpcport(i))
      os.execute("mysql -uroot -p123456 -e \"drop database if exists " .. node.dbname(i) .. ";" ..
        "create database " .. node.dbname(i) .. " default charset utf8 collate utf8_general_ci;" ..
        "grant all on " .. node.dbname(i) .. ".* to multiverse@localhost;" ..
        "flush privileges;\"")
      
      os.execute("multiverse -debug -daemon -datadir=" .. node.datadir(i) .. " >> " .. node.log(i) .. " 2>&1")
      while running do
        sleep(5000)
        err, _ = rpc.importprivkeyhost(node.rpchost(i), node.rpcport(i), keys[1]["privkey"], "123")
        if err == 0 then
          break
        end
      end

      if i ~= 0 then
        rpc.unlockkey(key.main[1]["pubkeyaddr"], "123")
        local err, ret = rpc.listfork()
        if err ~= 0 then
          print("listfork error:", ret)
        else
          for _, v in ipairs(ret) do
            if v["fork"] ~= rpc.genesis then
              err, r = rpc.sendfrom(key.main[1]["pubkeyaddr"], keys[1]["pubkeyaddr"], 10000, nil, v["fork"])
              if err ~= 0 then
                print("sendfrom error to " .. keys[1]["pubkeyaddr"] .. " on " .. v["fork"] .. ": " .. r)
              end
            end
          end
        end
      end
    end
    sleep(1000)
  end
end

local function createdelegate(dpostxs, first, last, amount)
  for i = first, last do
    if i ~= 0 then
      local tx = dpostxs[i]
      if tx then
        if waittx(node.rpchost(i), node.rpcport(i), tx) ~= 0 then
          return
        end

        local keys = getkeys(i)
        err, ret = rpc.createdelegate(node.rpchost(i), node.rpcport(i), keys[2]["pubkey"], keys[1]["pubkeyaddr"], "123", amount)
        if err ~= 0 then
          print("addnewtemplate delegate error", ret)
        end
      end
    end
  end
end

local function rundpos(first, last)
  for i = first, last do
    if util.direxist(node.datadir(i)) then
      print("multiverse -debug -daemon -datadir=" .. node.datadir(i) .. " >> " .. node.log(i) .. " 2>&1")
      os.execute("multiverse -debug -daemon -datadir=" .. node.datadir(i) .. " >> " .. node.log(i) .. " 2>&1")
    else
      print("No dpos " .. i)
    end
    sleep(100)
  end
end

local function stopdpos(first, last)
  for i = first, last do
    print("multiverse stop -rpchost=" .. node.rpchost(i) .. " -rpcport=" .. node.rpcport(i))
    os.execute("multiverse stop -rpchost=" .. node.rpchost(i) .. " -rpcport=" .. node.rpcport(i))
    sleep(100)
  end
end

local function purgedpos(first, last)
  for i = first, last do
    print("multiverse -purge -datadir=" .. node.datadir(i))
    os.execute("multiverse -purge -datadir=" .. node.datadir(i))
    sleep(100)
  end
end

local function removedpos(first, last)
  for i = first, last do
    os.execute("multiverse stop -rpchost=" .. node.rpchost(i) .. " -rpcport=" .. node.rpcport(i))
    sleep(1000)
    os.execute("rm -rf " .. node.datadir(i))
    os.execute("mysql -uroot -p123456 -e \"drop database if exists " .. node.dbname(i) .. "\";")
    print("node " .. i .. " has been removed.")
  end
end

local function createfork(first, last, hash)
  rpc.unlockkey(key.main[1]["pubkeyaddr"], "123")

  local forks = {}
  for i = first, last do
    local err, msg, hash, txid = rpc.createfork(nil, nil, hash, key.main[1]["pubkeyaddr"], 1000000, "fork"..i, "fork"..i, 1)
    if err ~= 0 then
      print(msg)
    else
      table.insert(forks, table.pack(hash, txid))
    end
    sleep(100)
  end

  for i, v in ipairs(forks) do
    local hash, txid = table.unpack(v)
    if waittx(nil, nil, txid, nil, true) ~= 0 then
      return
    end

    while running do
      err, ret = rpc.getbalance(key.main[1]["pubkeyaddr"], hash)
      if err == 0 and #ret > 0 and ret[1]["avail"] > 0 then
        break
      end
      sleep(5000)
    end

    for i = 1, 50 do
      if util.direxist(node.datadir(i)) then
        err, ret = rpc.sendfrom(key.main[1]["pubkeyaddr"], key.keypair[i][1]["pubkeyaddr"], 10000, nil, hash)
        if err ~= 0 then
          print("sendfrom error to " .. key.keypair[i][1]["pubkeyaddr"] .. " on " .. hash .. ": " .. ret)
        else
          print("sendfrom fork " .. hash .. ", txid: " .. ret)
        end
      end
    end
  end
end

args = table.pack(...)
op, first, last = args[1], args[2], args[3]

first = tonumber(first)
if not first or first < 0 or first > 50 then
  print("index out of range [0, 50] ")
  return
end

last = tonumber(last)
if not last or last < first then
  last = first
elseif last > 50 then
  last = 50
end

if op == "new" then
  local amount = #args >= 4 and tonumber(args[4]) or 20000000
  dpostxs = newdpos(first, last, amount + 1)
  createdelegate(dpostxs, first, last, amount)
elseif op == "wallet" then
  newwallet(first, last)
elseif op == "run" then
  rundpos(first, last)
elseif op == "stop" then
  stopdpos(first, last)
elseif op == "purge" then
  purgedpos(first, last)
elseif op == "remove" then
  removedpos(first, last)
elseif op == "createfork" then
  local hash = #args >= 4 and args[4] or rpc.genesis
  createfork(first, last, hash)
elseif op == "createdelegate" then
  local amount = #args >= 4 and tonumber(args[4]) or 20000000
  os.execute("luashell exec opendpos " .. first .. " " .. last)
  for i = first, last do
    keys = getkeys(i)
    rpc.createdelegate(node.rpchost(i), node.rpcport(i), keys[2]["pubkey"], keys[1]["pubkeyaddr"], "123", amount)
  end
elseif op == "txrobotrun" or op == "txrobotrundaemon" then
  local fork = #args >= 4 and args[4] or nil
  if first == last and op == "txrobotrun" then
    txrobot.run(first, count, fork)
  else
    for i = first, last do
      local cmd = "screen -S txrobot" .. i .. "-d -m bash -c 'luashell exec txrobotrun " .. i .. " " .. i .. " " .. count .. " " .. fork .. "'"
      os.execute(cmd)
    end
  end
elseif op == "txrobotstop" then
    for i = first, last do
      local cmd = "luashell exec txrobotrun " .. i ..
      os.execute("ps -ef | grep '" .. cmd .. "' | grep -v grep | awk '{print $2}' | xargs kill -2")
    end
elseif op == "closedpos" then
    for i = first, last do
      os.execute("sed -i 's/mpvss/#mpvss/g' " .. node.datadir(i) .. "/multiverse.conf")
    end
elseif op == "opendpos" then
    for i = first, last do
      os.execute("sed -i 's/#mpvss/mpvss/g' " .. node.datadir(i) .. "/multiverse.conf")
    end
elseif op == "clearlog" then
    for i = first, last do
      os.execute("rm -f " .. node.datadir(i) .. "/multiverse.log")
    end
else
  print("Unknown operator " .. op)
  return
end

::exit::