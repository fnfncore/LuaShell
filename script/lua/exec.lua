--
-- exec.lua
--

local util = require("util")
local key = require("key")
local node = require("node")
local rpc = require("rpc")

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
    err, ret = rpc:sethost(host, port).gettransaction(tx)
    if err ~= 0 then
      print("Waiting transaction... " .. tx, err)
      sleep(1000)
    elseif confirmed and ret["transaction"]["confirmations"] == 0 then
      print("Waiting transaction confirmation... " .. tx, err)
      sleep(1000)
    else
      break
    end
  end
  return err
end

local function createconf(n, keys)
  local dir = node.datadir(n)

  if util.direxist(dir) then
    print(dir .. " has been existed. ")
    return false
  end

  os.execute("mkdir -p " .. dir)
  io.output(dir.. "/multiverse.conf")
  io.write("mpvssaddress=" .. keys[1]["pubkeyaddr"] .. "\n")
  io.write("mpvsskey=" .. keys[2]["privkey"] .. "\n")
  io.write("blake512address=" .. keys[1]["pubkeyaddr"] .. "\n")
  io.write("blake512key=" .. keys[3]["privkey"] .. "\n")
  io.write("listen\n")
  io.write("addgroup=" .. rpc.genesis .. "\n")
  for i = 0, 20 do
    io.write("addnode=127.0.0.1:" .. node.port(i) .. "\n")
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

local function newdpos(first, last)
  local dpostxs = {}
  for i = first, last do
    local keys = getkeys(i)
    if keys and createconf(i, keys) then
      rpc:sethost(node.rpchost(i), node.rpcport(i)).stop()
      os.execute("mysql -uroot -p123456 -e \"drop database if exists " .. node.dbname(i) .. ";" ..
        "create database " .. node.dbname(i) .. ";" ..
        "grant all on " .. node.dbname(i) .. ".* to multiverse@localhost;" ..
        "flush privileges;\"")
      
      os.execute("multiverse -debug -daemon -datadir=" .. node.datadir(i) .. " > " .. node.log(i) .. " 2>&1")
      sleep(5000)
      print(rpc:sethost(node.rpchost(i), node.rpcport(i)).importprivkey(keys[1]["privkey"], "123"))

      -- fork
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

      -- dpos
      rpc.unlockkey(key.main[1]["pubkeyaddr"], "123")
      err, ret = rpc.sendfrom(key.main[1]["pubkeyaddr"], keys[1]["pubkeyaddr"], 20000001)
      if err ~= 0 then
        print("sendfrom dpos token error to " .. keys[1]["pubkeyaddr"] .. ": " .. err, ret)
      else
        dpostxs[i] = ret
      end
    end
    sleep(100)
  end
  return dpostxs
end

local function createdelegate(dpostxs, first, last)
  for i = first, last do
    local tx = dpostxs[i]
    if tx then
      if waittx(node.rpchost(i), node.rpcport(i), tx) ~= 0 then
        return
      end

      local keys = getkeys(i)
      err, ret = rpc.createdelegate(node.rpchost(i), node.rpcport(i), keys[2]["pubkey"], keys[1]["pubkeyaddr"], "123", 20000000)
      if err ~= 0 then
        print("addnewtemplate delegate error", ret)
      end
    end
  end
end

local function startdpos(first, last)
  for i = first, last do
    if util.direxist(node.datadir(i)) then
      print("multiverse -daemon -datadir=" .. node.datadir(i) .. " > " .. node.log(i) .. " 2>&1")
      os.execute("multiverse -daemon -datadir=" .. node.datadir(i) .. " > " .. node.log(i) .. " 2>&1")
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

local function createfork(first, last)
  rpc.unlockkey(key.main[1]["pubkeyaddr"], "123")

  local forks = {}
  for i = first, last do
    local err, msg, hash, txid = rpc.createfork(nil, nil, rpc.genesis, key.main[1]["pubkeyaddr"], 1000000, "fork"..i, "fork"..i, 1)
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

op, first, last = ...

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
  dpostxs = newdpos(first, last)
  createdelegate(dpostxs, first, last)
elseif op == "start" then
  startdpos(first, last)
elseif op == "stop" then
  stopdpos(first, last)
elseif op == "purge" then
  purgedpos(first, last)
elseif op == "remove" then
  removedpos(first, last)
elseif op == "createfork" then
  createfork(first, last)
else
  print("Unknown operator " .. op)
  return
end

::exit::