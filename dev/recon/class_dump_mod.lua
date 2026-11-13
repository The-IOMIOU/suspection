local out = "E:/MixUps/ronsuspect/dump/"
local function dump()
  local f = io.open(out.."classes.txt","w"); local e = io.open(out.."enums.txt","w")
  local keys = {"Character","Team","Health","Swat","SWAT","Suspect","Civilian","GameMode","GameState","AIController","Damage","Spawn","Loadout","Door","Trap","Hostage","Arrest","Surrender","Weapon","Mission"}
  local p = io.open(out.."props.txt","w")
  ForEachUObject(function(obj)
    local fn = obj:GetFullName()
    if fn:find("/Script/ReadyOrNot%.") then
      if fn:sub(1,6)=="Class " then
        f:write(fn.."\n")
        local short = fn:match("%.([%w_]+)$") or ""
        for _,k in ipairs(keys) do if short:find(k) then
          p:write("== "..fn.."\n")
          pcall(function() obj:ForEachProperty(function(pr) p:write("  P "..pr:GetFName():ToString().." : "..pr:GetClass():GetFName():ToString().."\n") end) end)
          pcall(function() obj:ForEachFunction(function(fu) p:write("  F "..fu:GetFName():ToString().."\n") end) end)
          break end end
      elseif fn:sub(1,5)=="Enum " then
        e:write(fn.."\n")
        pcall(function() obj:ForEachName(function(n,v) e:write("   "..n:ToString().."="..tostring(v).."\n") end) end)
      end
    end
  end)
  f:close(); e:close(); p:close(); print("[RonDump] done\n")
end
ExecuteWithDelay(15000, function() ExecuteInGameThread(dump) end)
