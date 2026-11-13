-- dev-only REPL bridge: write Lua to cmd.lua, result lands in out.txt
local dir = ((os.getenv("RON_BRIDGE") or (os.getenv("LOCALAPPDATA").."/Temp/ronbridge")):gsub("\\","/")).."/"
_G.LOG = {}
function _G.P(...) local t={} for i=1,select('#',...) do t[#t+1]=tostring(select(i,...)) end LOG[#LOG+1]=table.concat(t," ") end
LoopAsync(400, function()
  local f = io.open(dir.."cmd.lua","r"); if not f then return false end
  local src = f:read("a"); f:close(); os.remove(dir.."cmd.lua")
  ExecuteInGameThread(function()
    LOG = {}
    local fn, err = load(src, "cmd", "t", _G)
    local ok, e2 = true, nil
    if fn then ok, e2 = pcall(fn) else ok, e2 = false, err end
    if not ok then P("ERR "..tostring(e2)) end
    local o = io.open(dir.."out.txt","w"); o:write(table.concat(LOG,"\n")); o:close()
  end)
  return false
end)
