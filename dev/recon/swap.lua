for _,n in ipairs({"ReadyOrNotPlayerState:SetTeam","ReadyOrNotPlayerState:Server_SetTeam","ReadyOrNotCharacter:IsOnSameTeam","ReadyOrNotPlayerState:GetTeam"}) do local f=StaticFindObject("/Script/ReadyOrNot."..n) local s={} f:ForEachProperty(function(p) s[#s+1]=p:GetFName():ToString()..":"..p:GetClass():GetFName():ToString() end) P(n,table.concat(s,", ")) end
local ps = FindFirstOf("ReadyOrNotPlayerState")
ps.Team = 3
local pc = FindFirstOf("BasePlayer_C")
pcall(function() pc:HandleTeamChanged(3) end)
P("ps.Team",ps.Team,"char team",pc:GetTeam())
for _,c in ipairs(FindAllOf("CyberneticCharacter")) do P(c:GetFName():ToString(), c:GetTeam(), c:IsOnSameTeam(pc, false)) end
