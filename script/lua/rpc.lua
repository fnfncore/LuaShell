--
-- rpc.lua
--

local rpc = { _version = "0.1" }

local function makedelegateparam(delegate,owner)
  if type(delegate) ~= "string" then
    error("expected delegate of type string, got " .. type(delegate))
  end
  if type(owner) ~= "string" then
    error("expected owner of type string, got " .. type(owner))
  end
  return { ["type"] = "delegate", 
           ["delegate"] = { ["delegate"] = delegate, ["owner"] = owner } }
end

local function makeforkparam(redeem,fork)
  if type(redeem) ~= "string" then
    error("expected redeem of type string, got " .. type(redeem))
  end
  if type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  return { ["type"] = "fork",
           ["fork"] = { ["redeem"] = redeem, ["fork"] = fork } }
end

local function makemintparam(mint,spent)
  if type(mint) ~= "string" then
    error("expected mint of type string, got " .. type(mint))
  end
  if type(spent) ~= "string" then
    error("expected spent of type string, got " .. type(spent))
  end
  return { ["type"] = "mint",
           ["mint"] = { ["mint"] = mint, ["spent"] = spent } }
end

local function makemultisigparam(required,pubkeys)
  if type(required) ~= "number" then
    error("expected required of type number, got " .. type(required))
  end
  if type(pubkeys) ~= "table" then
    error("expected pubkeys of type table, got " .. type(pubkeys))
  end
  for k,v in pairs(pubkeys) do
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

local function makeweightedparam(required,weighted)
  if type(required) ~= "number" then
    error("expected required of type number, got " .. type(required))
  end
  if type(weighted) ~= "table" then
    error("expected weighted of type table, got " .. type(weighted))
  end

  local pubkeys = {}
  for k,v in pairs(weighted) do
    if type(k) ~= "string" then
      error("expected key of type string, got " .. type(k))
    end
    if type(v) ~= "number" then
      error("expected weight of type number, got " .. type(v))
    end
    table.insert(pubkeys,{ ["key"] = k, ["weight"] = v })
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


-- System

function rpc.help(command)
  if type(command) ~= "string" then
    return rpccall("help",{})
  end
  return rpccall("help",{ ["command"] = command })
end

function rpc.stop()
  return rpccall("stop",{})
end

function rpc.version()
  return rpccall("version",{})
end

-- Network

function rpc.getpeercount()
  return rpccall("getpeercount",{})
end

function rpc.listpeer()
  return rpccall("listpeer",{})
end

function rpc.addnode(node)
  if type(node) ~= "string" then
    error("expected node of type string, got " .. type(node))
  end
  return rpccall("addnode",{ ["node"] = node })
end

function rpc.removenode(node)
  if type(node) ~= "string" then
    error("expected node of type string, got " .. type(node))
  end
  return rpccall("removenode",{ ["node"] = node })
end

-- Worldline & TxPool
 
function rpc.getforkcount()
  return rpccall("getforkcount",{})
end

function rpc.listfork()
  return rpccall("listfork",{})
end

function rpc.getgenealogy(fork)
  if type(fork) ~= "string" then
    return rpccall("getgenealogy",{})
  end
  return rpccall("getgenealogy",{ ["fork"] = fork })
end

function rpc.getforkheight(fork)
  if type(fork) ~= "string" then
    return rpccall("getforkheight",{})
  end
  return rpccall("getforkheight",{ ["fork"] = fork })
end

function rpc.getblockcount(fork)
  if type(fork) ~= "string" then
    return rpccall("getblockcount",{})
  end
  return rpccall("getblockcount",{ ["fork"] = fork })
end

function rpc.getblockhash(height,fork)
  if type(height) ~= "number" then
    error("expected height of type number, got " .. type(height))
  end
  if type(fork) ~= "string" then
    return rpccall("getblockhash",{ ["height"] = height })
  end
  return rpccall("getblockhash",{ ["height"] = height,["fork"] = fork })
end

function rpc.getblocklocation(block)
  if type(block) ~= "string" then
    error("expected block of type string, got " .. type(block))
  end
  return rpccall("getblocklocation",{ ["block"] = block })
end

function rpc.getblock(block)
  if type(block) ~= "string" then
    error("expected block of type string, got " .. type(block))
  end
  return rpccall("getblock",{ ["block"] = block })
end

function rpc.gettxpool(fork,detail)
  detail = detail or false
  if type(detail) ~= "boolean" then
    error("expected detail of type boolean, got " .. type(detail))
  end
  if type(fork) ~= "string" then
    return rpccall("gettxpool",{ ["detail"] = detail })
  end
  return rpccall("gettxpool",{ ["fork"] = fork,["detail"] = detail })
end

function rpc.gettransaction(txid,serialized)
  serialized = serialized or false
  if type(serialized) ~= "boolean" then
    error("expected serialized of type boolean, got " .. type(serialized))
  end
  if type(txid) ~= "string" then
    error("expected txid of type string, got " .. type(txid))
  end
  return rpccall("gettransaction",{ ["txid"] = txid,["serialized"] = serialized })
end

function rpc.sendtransaction(txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return rpccall("sendtransaction",{ ["txdata"] = txdata })
end

-- Wallet

function rpc.listkey()
  return rpccall("listkey",{})
end

function rpc.getnewkey(passphrase)
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return rpccall("getnewkey",{ ["passphrase"] = passphrase })
end

function rpc.encryptkey(pubkey, passphrase, oldpassphrase)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  if type(passphrase) ~= "string" then
    error("expected new passphrase of type string, got " .. type(passphrase))
  end
  if type(oldpassphrase) ~= "string" then
    error("expected old passphrase of type string, got " .. type(oldpassphrase))
  end
  return rpccall("encryptkey",{ ["pubkey"] = pubkey, ["passphrase"] = passphrase, ["oldpassphrase"] = oldpassphrase })
end

function rpc.lockkey(pubkey)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  return rpccall("lockkey",{ ["pubkey"] = pubkey })
end

function rpc.unlockkey(pubkey, passphrase)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return rpccall("unlockkey",{ ["pubkey"] = pubkey, ["passphrase"] = passphrase })
end

function rpc.importprivkey(privkey, passphrase)
  if type(privkey) ~= "string" then
    error("expected privkey of type string, got " .. type(privkey))
  end
  if type(passphrase) ~= "string" then
    error("expected passphrase of type string, got " .. type(passphrase))
  end
  return rpccall("importprivkey",{ ["privkey"] = privkey, ["passphrase"] = passphrase })
end

function rpc.addnewtemplate(ttype,...)
  if type(ttype) ~= "string" then
    error("expected ttype of type string, got " .. type(ttype))
  end
  if not maketemplateparam[ttype] then
    error("unknown template type " .. ttype)
  end

  return rpccall("addnewtemplate",maketemplateparam[ttype](...))
end

function rpc.listaddress()
  return rpccall("listaddress",{})
end

function rpc.validateaddress(address)
  if type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end
  return rpccall("validateaddress",{ ["address"] = address })
end

function rpc.resyncwallet(address)
  if address and type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end
  return rpccall("resyncwallet",{ ["address"] = address })
end

function rpc.getbalance(address, fork)
  if fork and type(fork) ~= "string" then
    error("expected fork of type string, got " .. type(fork))
  end
  if address and type(address) ~= "string" then
    error("expected address of type string, got " .. type(address))
  end

  return rpccall("getbalance",{ ["fork"] = fork,["address"] = address })
end

function rpc.listtransaction(count,offset)
  if count and type(count) ~= "number" then
    error("expected count of type number, got " .. type(count))
  end
  if offset and type(offset) ~= "number" then
    error("expected offset of type number, got " .. type(offset))
  end
  return rpccall("listtransaction",{ ["count"] = count, ["offset"] = offset })
end

function rpc.sendfrom(from,to,amount,txfee,fork,data)
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
  return rpccall("sendfrom",{ ["from"] = from, ["to"] = to, ["amount"] = amount,
                              ["txfee"] = txfee, ["fork"] = fork, ["data"] = data})
end

function rpc.createtransaction(from,to,amount,txfee,fork,data)
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
  return rpccall("createtransaction",{ ["from"] = from, ["to"] = to, ["amount"] = amount,
                                       ["txfee"] = txfee, ["fork"] = fork, ["data"] = data})
end

function rpc.signtransaction(txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return rpccall("signtransaction",{ ["txdata"] = txdata })
end

function rpc.makeorigin(prev,owner,amount,name,symbol,reward,isolated,private,enclosed)
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
  return rpccall("makeorigin",{ ["prev"] = prev, ["owner"] = owner, ["amount"] = amount,
                                ["name"] = name, ["symbol"] = symbol, ["reward"] = reward,
                                ["isolated"] = isolated, ["private"] = private, 
                                ["enclosed"] = enclosed })
end

-- Util

function rpc.makekeypair()
  return rpccall("makekeypair",{})
end

function rpc.getpubkeyaddress(pubkey)
  if type(pubkey) ~= "string" then
    error("expected pubkey of type string, got " .. type(pubkey))
  end
  return rpccall("getpubkeyaddress",{ ["pubkey"] = pubkey })
end

function rpc.gettemplateaddress(tid)
  if type(tid) ~= "string" then
    error("expected tid of type string, got " .. type(tid))
  end
  return rpccall("gettemplateaddress",{ ["tid"] = tid })
end

function rpc.maketemplate(ttype,...)
  if type(ttype) ~= "string" then
    error("expected ttype of type string, got " .. type(ttype))
  end
  if not maketemplateparam[ttype] then
    error("unknown template type " .. ttype)
  end

  return rpccall("maketemplate",maketemplateparam[ttype](...))
end

function rpc.decodetransaction(txdata)
  if type(txdata) ~= "string" then
    error("expected txdata of type string, got " .. type(txdata))
  end
  return rpccall("decodetransaction",{ ["txdata"] = txdata })
end

return rpc
