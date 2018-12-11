--
-- node.lua
--

local node = { _version = "0.1" }

function node.rpchost(n)
  return "127.0.0.1"
end

function node.rpcport(n)
  return (n+6) .. "812"
end

function node.port(n)
  return (n+6) .. "811"
end

function node.dnseedport(n)
  return (n+6) .. "816"
end

function node.dbpport(n)
  return (n+6) .. "815"
end

function node.dbname(n)
  return "dpos" .. n
end

function node.datadir(n)
  if n == 0 then
      return os.getenv("HOME") .. "/.multiverse"
  else
      return os.getenv("HOME") .. "/.dpos" .. n
  end
end

function node.log(n)
  return node.datadir(n) .. "/multiverse.log"
end


return node
