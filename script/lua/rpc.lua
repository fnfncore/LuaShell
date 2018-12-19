--
-- rpc.lua
--

local rpc = { _version = "0.1" }

local function makedelegateparam(delegate, owner)
  if type(delegate) ~= "string" then
    error("expected delegate of type string, got " .. type(delegate))
  end
  if type(owner) ~= "string" then
    error("expected owner of type string, got " .. type(owner))
  end
  return { ["type"] = "delegate", 
           ["delegate"] = { ["delegate"] = delegate, ["owner"] = owner } }
end

local function makeforkparam(redeem, fork)
  if type(redeem) ~= "string" then
    error("expected redeem of type string, got " .. type(redeem))
  end
  if type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  return { ["type"] = "fork", 
           ["fork"] = { ["redeem"] = redeem, ["fork"] = fork } }
end

local function makemintparam(mint, spent)
  if type(mint) ~= "string" then
    error("expected mint of type string, got " .. type(mint))
  end
  if type(spent) ~= "string" then
    error("expected spent of type string, got " .. type(spent))
  end
  return { ["type"] = "mint", 
           ["mint"] = { ["mint"] = mint, ["spent"] = spent } }
end

local function makemultisigparam(required, pubkeys)
  if type(required) ~= "number" then
    error("expected required of type number, got " .. type(required))
  end
  if type(pubkeys) ~= "table" then
    error("expected pubkeys of type table, got " .. type(pubkeys))
  end
  for k, v in pairs(pubkeys) do
    if type(k) ~= "number" then
      error("expected idx of type number, got " .. type(k))
    end
    if type(v) ~= "string" then
      error("expected key of type string, got " .. type(v))
    end
  end
  return { ["type"] = "multisig", 
           ["multisig"] = { ["required"] = required, ["pubkeys"] = pubkeys } }
end

local function makeweightedparam(required, weighted)
  if type(required) ~= "number" then
    error("expected required of type number, got " .. type(required))
  end
  if type(weighted) ~= "table" then
    error("expected weighted of type table, got " .. type(weighted))
  end

  local pubkeys = {}
  for k, v in pairs(weighted) do
    if type(k) ~= "string" then
      error("expected key of type string, got " .. type(k))
    end
    if type(v) ~= "number" then
      error("expected weight of type number, got " .. type(v))
    end
    table.insert(pubkeys, { ["key"] = k, ["weight"] = v })
  end
  return { ["type"] = "weighted", 
           ["weighted"] = { ["required"] = required, ["pubkeys"] = pubkeys } }
end

local maketemplateparam = {
  [ "delegate" ] = makedelegateparam, 
  [ "fork"     ] = makeforkparam, 
  [ "mint"     ] = makemintparam, 
  [ "multisig" ] = makemultisigparam, 
  [ "weighted" ] = makeweightedparam
}


local impl = {

-- System

help = function(fn, command)
  if type(command) ~= "string" then
    return fn("help", {})
  end
  return fn("help", { ["command"] = command })
end, 

stop = function(fn)
  return fn("stop", {})
end, 

version = function(fn)
  return fn("version", {})
end, 

-- Network

getpeercount = function(fn)
  return fn("getpeercount", {})
end, 

listpeer = function(fn)
  return fn("listpeer", {})
end, 

addnode = function(fn, node)
  if type(node) ~= "string" then
    error("expected node of type string, got " .. type(node))
  end
  return fn("addnode", { ["node"] = node })
end, 

removenode = function(fn, node)
  if type(node) ~= "string" then
    error("expected node of type string, got " .. type(node))
  end
  return fn("removenode", { ["node"] = node })
end, 

-- Worldline & TxPool
 
getforkcount = function(fn)
  return fn("getforkcount", {})
end, 

listfork = function(fn)
  return fn("listfork", {})
end, 

getgenealogy = function(fn, fork)
  if type(fork) ~= "string" then
    return fn("getgenealogy", {})
  end
  return fn("getgenealogy", { ["fork"] = fork })
end, 

getforkheight = function(fn, fork)
  if type(fork) ~= "string" then
    return fn("getforkheight", {})
  end
  return fn("getforkheight", { ["fork"] = fork })
end, 

getblockcount = function(fn, fork)
  if type(fork) ~= "string" then
    return fn("getblockcount", {})
  end
  return fn("getblockcount", { ["fork"] = fork })
end, 

getblockhash = function(fn, height, fork)
  if type(height) ~= "number" then
    error("expected height of type number, got " .. type(height))
  end
  if type(fork) ~= "string" then
    return fn("getblockhash", { ["height"] = height })
  end
  return fn("getblockhash", { ["height"] = height, ["fork"] = fork })
end, 

getblocklocation = function(fn, block)
  if type(block) ~= "string" then
    error("expected block of type string, got " .. type(block))
  end
  return fn("getblocklocation", { ["block"] = block })
end, 

getblock = function(fn, block)
  if type(block) ~= "string" then
    error("expected block of type string, got " .. type(block))
  end
  return fn("getblock", { ["block"] = block })
end, 

gettxpool = function(fn, fork, detail)
  detail = detail or false
  if type(detail) ~= "boolean" then
    error("expected detail of type boolean, got " .. type(detail))
  end
  if type(fork) ~= "string" then
    return fn("gettxpool", { ["detail"] = detail })
  end
  return fn("gettxpool", { ["fork"] = fork, ["detail"] = detail })
end, 

gettransaction = function(fn, txid, serialized)
  serialized = serialized or false
  if type(serialized) ~= "boolean" then
    error("expected serialized of type boolean, got " .. type(serialized))
  end
  if type(txid) ~= "string" then
    error("expected txid of type string, got " .. type(txid))
  end
  return fn("gettransaction", { ["txid"] = txid, ["serialized"] = serialized })
end, 

sendtransaction = function(fn, txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return fn("sendtransaction", { ["txdata"] = txdata })
end, 

-- Wallet

listkey = function(fn)
  return fn("listkey", {})
end, 

getnewkey = function(fn, passphrase)
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return fn("getnewkey", { ["passphrase"] = passphrase })
end, 

encryptkey = function(fn, pubkey, passphrase, oldpassphrase)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  if type(passphrase) ~= "string" then
    error("expected new passphrase of type string, got " .. type(passphrase))
  end
  if type(oldpassphrase) ~= "string" then
    error("expected old passphrase of type string, got " .. type(oldpassphrase))
  end
  return fn("encryptkey", { ["pubkey"] = pubkey, ["passphrase"] = passphrase, ["oldpassphrase"] = oldpassphrase })
end, 

lockkey = function(fn, pubkey)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  return fn("lockkey", { ["pubkey"] = pubkey })
end, 

unlockkey = function(fn, pubkey, passphrase)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return fn("unlockkey", { ["pubkey"] = pubkey, ["passphrase"] = passphrase })
end, 

importprivkey = function(fn, privkey, passphrase)
  if type(privkey) ~= "string" then
    error("expected privkey of type string, got " .. type(privkey))
  end
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return fn("importprivkey", { ["privkey"] = privkey, ["passphrase"] = passphrase })
end, 

addnewtemplate = function(fn, ttype, ...)
  if type(ttype) ~= "string" then
    error("expected ttype of type string, got " .. type(ttype))
  end
  if not maketemplateparam[ttype] then
    error("unknown template type " .. ttype)
  end

  return fn("addnewtemplate", maketemplateparam[ttype](...))
end, 

listaddress = function(fn)
  return fn("listaddress", {})
end, 

validateaddress = function(fn, address)
  if type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end
  return fn("validateaddress", { ["address"] = address })
end, 

resyncwallet = function(fn, address)
  if address and type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end
  return fn("resyncwallet", { ["address"] = address })
end, 

getbalance = function(fn, address, fork)
  if fork and type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  if address and type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end

  return fn("getbalance", { ["fork"] = fork, ["address"] = address })
end, 

listtransaction = function(fn, count, offset)
  if count and type(count) ~= "number" then
    error("expected count of type number, got " .. type(count))
  end
  if offset and type(offset) ~= "number" then
    error("expected offset of type number, got " .. type(offset))
  end
  return fn("listtransaction", { ["count"] = count, ["offset"] = offset })
end, 

sendfrom = function(fn, from, to, amount, txfee, fork, data)
  if type(from) ~= "string" then
    error("expected from of type string, got " .. type(from))
  end
  if type(to) ~= "string" then
    error("expected to of type string, got " .. type(to))
  end
  if type(amount) ~= "number" then
    error("expected amount of type number, got " .. type(amount))
  end
  if txfee and type(txfee) ~= "number" then
    error("expected txfee of type number, got " .. type(txfee))
  end
  if fork and type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  if data and type(data) ~= "string" then
    error("expected data of type string, got " .. type(data))
  end
  return fn("sendfrom", { ["from"] = from, ["to"] = to, ["amount"] = amount, 
                              ["txfee"] = txfee, ["fork"] = fork, ["data"] = data})
end, 

createtransaction = function(fn, from, to, amount, txfee, fork, data)
  if type(from) ~= "string" then
    error("expected from of type string, got " .. type(from))
  end
  if type(to) ~= "string" then
    error("expected to of type string, got " .. type(to))
  end
  if type(amount) ~= "number" then
    error("expected amount of type number, got " .. type(amount))
  end
  if txfee and type(txfee) ~= "number" then
    error("expected txfee of type number, got " .. type(txfee))
  end
  if fork and type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  if data and type(data) ~= "string" then
    error("expected data of type string, got " .. type(data))
  end
  return fn("createtransaction", { ["from"] = from, ["to"] = to, ["amount"] = amount, 
                                       ["txfee"] = txfee, ["fork"] = fork, ["data"] = data})
end, 

signtransaction = function(fn, txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return fn("signtransaction", { ["txdata"] = txdata })
end, 

makeorigin = function(fn, prev, owner, amount, name, symbol, reward, isolated, private, enclosed)
  if type(prev) ~= "string" then
    error("expected prev of type string, got " .. type(prev))
  end
  if type(owner) ~= "string" then
    error("expected owner of type string, got " .. type(owner))
  end
  if type(amount) ~= "number" then
    error("expected amount of type number, got " .. type(amount))
  end
  if type(name) ~= "string" then
    error("expected name of type string, got " .. type(name))
  end
  if type(symbol) ~= "string" then
    error("expected symbol of type string, got " .. type(symbol))
  end
  if type(reward) ~= "number" then
    error("expected reward of type number, got " .. type(reward))
  end
  if isolated and type(isolated) ~= "boolean" then
    error("expected isolated of type boolean, got " .. type(isolated))
  end
  if private and type(private) ~= "boolean" then
    error("expected private of type boolean, got " .. type(private))
  end
  if enclosed and type(enclosed) ~= "boolean" then
    error("expected enclosed of type boolean, got " .. type(enclosed))
  end
  return fn("makeorigin", { ["prev"] = prev, ["owner"] = owner, ["amount"] = amount, 
                                ["name"] = name, ["symbol"] = symbol, ["reward"] = reward, 
                                ["isolated"] = isolated, ["private"] = private, 
                                ["enclosed"] = enclosed })
end, 

-- Util

makekeypair = function(fn)
  return fn("makekeypair", {})
end, 

getpubkeyaddress = function(fn, pubkey)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  return fn("getpubkeyaddress", { ["pubkey"] = pubkey })
end, 

gettemplateaddress = function(fn, tid)
  if type(tid) ~= "string" then
    error("expected tid of type string, got " .. type(tid))
  end
  return fn("gettemplateaddress", { ["tid"] = tid })
end, 

maketemplate = function(fn, ttype, ...)
  if type(ttype) ~= "string" then
    error("expected ttype of type string, got " .. type(ttype))
  end
  if not maketemplateparam[ttype] then
    error("unknown template type " .. ttype)
  end

  return fn("maketemplate", maketemplateparam[ttype](...))
end, 

decodetransaction = function(fn, txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return fn("decodetransaction", { ["txdata"] = txdata })
end, 

}

local nonce = 1
local usednonce = {}
local idlenonce = {}
local cononce = {}
local function getnonce()
  local n
  if #idlenonce > 0 then
    n = idlenonce[#idlenonce]
    table.remove(idlenonce)
  else
    n = nonce
    nonce = nonce + 1
  end
  return n
end

local function releasenonce(nonce)
  for i, v in ipairs(usednonce) do
    if v == nonce then
      table.remove(usednonce, i)
      break
    end
  end

  table.insert(idlenonce, nonce)
end

function rpc.asyncstart(fn, ...)
  local n = getnonce()
  local co
  co = coroutine.create(function(...)
    fn(...)
    releasenonce(cononce[co])
    cononce[co] = nil
  end)

  cononce[co] = n
  coroutine.resume(co, ...)
end

local rpchost, rpcport = "", 0
rpc.genesis = "c8f10736fb9b03a2d224c9d79b60ccc156b4bf9c28072fb332d0ea5fc104e085"

function rpc.callhost(method, host, port, ...)
  if not host or type(host) ~= "string" or host == "localhost" then
      host = "127.0.0.1"
  end

  if type(port) == "string" then
    port = tonumber(port)
  end
  if not port or type(port) ~= "number" or port <= 0 or port > 65535 then
    port = 6812
  end

  local co, ismain = coroutine.running()
  local fn = impl[method]
  if fn then
    if ismain then
      -- print("rpccall...", "host:" .. tostring(host), "port:" .. tostring(port), method, ...)
      local synccall = function (m, d) return rpccall(m, d, host, port) end
      return fn(synccall, ...)
    else
      -- print("rpcasynccall...", "host:" .. tostring(host), "port:" .. tostring(port), method, ...)
      local asynccall = function (m, d) return rpcasynccall(cononce[co], m, d, host, port) end
      return fn(asynccall, ...)
    end
  end
end

function rpc.call(method, ...)
  return rpc.callhost(method, "127.0.0.1", 6812, ...)
end

function rpc.createfork(host, port, prev, owner, amount, name, symbol, reward, isolated, private, enclosed)
  err, ret = rpc.makeoriginhost(host, port, prev, owner, amount, name, symbol, reward, isolated, private, enclosed)
  if err ~= 0 then
    return err, ret
  end
  local hash = ret["hash"]
  local hex = ret["hex"]

  err, ret = rpc.addnewtemplatehost(host, port, "fork", owner, hash)
  if err ~= 0 then
    return err, ret
  end
  
  err, ret = rpc.sendfromhost(host, port, owner, ret, amount, nil, rpc.genesis, hex)
  if err ~= 0 then
    return err, ret
  end

  return 0, "", hash, ret
end

function rpc.createdelegate(host, port, delegate, owner, password, amount)
  err, ret = rpc.addnewtemplatehost(host, port, "delegate", delegate, owner)
  if err ~= 0 then
    return err, ret
  else
    rpc.unlockkeyhost(host, port, owner, password)
    return rpc.sendfromhost(host, port, owner, ret, amount)
  end
end

setmetatable(rpc, { __index = function(t, k) 
  return function(...)
    if string.find(k, "host", -4) then
      return t.callhost(string.sub(k, 1, -5), ...)
    else
      return t.call(k, ...)
    end
  end
end})


return rpc
