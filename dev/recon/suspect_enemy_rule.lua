local p
for _,c in ipairs(FindAllOf("PlayerCharacter")) do if c.Controller:IsValid() and not c:GetClass():GetFName():ToString():find("Custom") then p=c end end
local sus = FindAllOf("SuspectCharacter"); local a, b = sus[1], sus[2]; local ca = a.Controller
a.DefaultTeam = 2; a:HandleTeamChanged(2)
P("pawn 2 -> ctl team", ca:GetTeam(), "A enemy p", ca:IsCharacterEnemy(p), "A enemy B", ca:IsCharacterEnemy(b))
local ok,e = pcall(function() ca:UnPossess() ca:Possess(a) end) P("repossess", ok, e)
P("after repossess ctl team", ca:GetTeam(), "A enemy p", ca:IsCharacterEnemy(p), "A enemy B", ca:IsCharacterEnemy(b))
-- other direction: player to team 3
local ps = p.PlayerState
P("B enemy p (p team2)", b.Controller:IsCharacterEnemy(p))
ps.Team = 3; p.DefaultTeam = 3; p:HandleTeamChanged(3)
P("p team", p:GetTeam(), "B enemy p (p team3)", b.Controller:IsCharacterEnemy(p), "A enemy p", ca:IsCharacterEnemy(p))
ps.Team = 2; p.DefaultTeam = 2; p:HandleTeamChanged(2)
