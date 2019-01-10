--
-- util.lua
--

local util = { _version = "0.1" }

function util.direxist(path)
  if os.execute('cd "' .. path .. '" > /dev/null 2>&1') then
    return true
  end
  return false
end

function util.fileexist(path)
  if os.execute('ls "' .. path .. '" > /dev/null 2>&1') then
    return true
  end
  return false
end

function util.dumptable(tab, indent)
  if indent == nil then
    indent = ""
  end

  if type(tab) ~= "table" then
    print(type(tab) .. " is not a table")
    return
  end

  print(indent .. "{")
  for k, v in pairs (tab) do
    if type(k) == "string" then
      k = '"' .. k .. '"'
    end
    if type(v) == "string" then
      v = '"' .. v .. '"'
    end

    if type(v) == "table" then
        print(indent.."  [" .. tostring(k) .. "] =")
        util.dumptable(v, indent.."  ")
    else
        print(indent.."  [" .. tostring(k) .. "] =" .. tostring(v) .. ", ")
    end
  end
  print(indent .. "}, ")
end

return util