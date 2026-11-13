-- M1 recon: what is there to spawn SWAT with? Run in a loaded mission: dev/q.sh dev/recon/spawn.lua
local function nm(o) return (o and o:IsValid()) and o:GetFullName() or "nil" end
local sp = FindAllOf("AISpawn") or {}
P("AISpawn actors", #sp)
for i, s in ipairs(sp) do if i <= 12 then
  local ok, team = pcall(function() return s:GetSpawningTeamType() end)
  local ok2, ch = pcall(function() return nm(s.SpawnedCharacter) end)
  P(i, s:GetClass():GetFName():ToString(), "team", ok and team or "?", "spawned", ok2 and ch or "?")
end end
for _, c in ipairs(FindAllOf("SWATCharacter") or {}) do
  local ctl = c.Controller
  local l = c:K2_GetActorLocation()
  P("SWAT", c:GetClass():GetFullName(), "ctl", (ctl and ctl:IsValid()) and ctl:GetClass():GetFullName() or "nil", ("@ %.0f %.0f %.0f"):format(l.X, l.Y, l.Z))
end
for _, p in ipairs(FindAllOf("PlayerStart") or {}) do
  local l = p:K2_GetActorLocation()
  P("START", p:GetClass():GetFName():ToString(), p.PlayerStartTag:ToString(), ("@ %.0f %.0f %.0f"):format(l.X, l.Y, l.Z))
end
local gm = FindFirstOf("ReadyOrNotGameMode")
if gm and gm:IsValid() then P("GM", gm:GetClass():GetFName():ToString(), "tags", gm.SWATRedStartTag:ToString(), gm.SWATBlueStartTag:ToString(), gm.SuspectStartTag:ToString()) end
for _, n in ipairs({ "/Script/ReadyOrNot.AISpawn:DoSpawn", "/Script/ReadyOrNot.AISpawn:GetSpawningTeamType", "/Script/Engine.GameplayStatics:BeginDeferredActorSpawnFromClass", "/Script/Engine.GameplayStatics:FinishSpawningActor", "/Script/AIModule.AIBlueprintHelperLibrary:SpawnAIFromClass" }) do
  local f = StaticFindObject(n)
  if f and f:IsValid() then local s = {} f:ForEachProperty(function(p) s[#s + 1] = p:GetFName():ToString() .. ":" .. p:GetClass():GetFName():ToString() end) P(n:match(":(.*)") .. "(" .. table.concat(s, ", ") .. ")") else P("missing " .. n) end
end
local cl = StaticFindObject("/Script/ReadyOrNot.AISpawn") local s = {}
cl:ForEachProperty(function(p) s[#s + 1] = p:GetFName():ToString() .. ":" .. p:GetClass():GetFName():ToString() end)
P("AISpawn props: " .. table.concat(s, " "))
