local fns = {"/Script/ReadyOrNot.ReadyOrNotCharacter:Server_ApplyPointDamage","/Script/ReadyOrNot.ReadyOrNotCharacter:GetTeam","/Script/ReadyOrNot.ReadyOrNotCharacter:Multicast_TakeDamage","/Script/ReadyOrNot.ReadyOrNotGameMode:SwapPlayerTeams","/Script/ReadyOrNot.ReadyOrNotGameMode:SpawnPlayerCharacter","/Script/ReadyOrNot.ReadyOrNotGameMode:IsTeamDead","/Script/ReadyOrNot.CharacterHealthComponent:SetMaxLimbHealth","/Script/ReadyOrNot.ReadyOrNotCharacter:ApplyDamageToBone","/Script/ReadyOrNot.ReadyOrNotCharacter:HandleTeamChanged"}
for _,n in ipairs(fns) do
  local f = StaticFindObject(n)
  if f and f:IsValid() then local s={} f:ForEachProperty(function(p) s[#s+1]=p:GetFName():ToString()..":"..p:GetClass():GetFName():ToString() end) P(n:match(":(.*)").."("..table.concat(s,", ")..")") else P("missing "..n) end
end
for _,c in ipairs({"ReadyOrNotPlayerState","ReadyOrNotGameMode_PVP","SWATCharacter","SWATController","AISpawn","ReadyOrNotGameState"}) do
  local cl = StaticFindObject("/Script/ReadyOrNot."..c); local s={}
  cl:ForEachProperty(function(p) local n=p:GetFName():ToString() if not n:find("^On") then s[#s+1]=n end end)
  local fs={} cl:ForEachFunction(function(f) fs[#fs+1]=f:GetFName():ToString() end)
  P("##"..c.." P: "..table.concat(s," ")); P("   F: "..table.concat(fs," "))
end
