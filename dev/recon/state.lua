local gm=FindFirstOf("ReadyOrNotGameMode") P(gm:IsValid() and gm:GetFullName() or "nogm")
local gs=FindFirstOf("ReadyOrNotGameState") P("swat",gs.NumSwatActive,"sus",gs.NumSuspectsActive,"civ",gs.NumCiviliansActive,"pvp",gs.bPvPMode,"mode",gs.ModeName:ToString())
local cnt={}
for _,c in ipairs(FindAllOf("ReadyOrNotCharacter") or {}) do local k=c:GetClass():GetFName():ToString().." t"..tostring(c:GetTeam()) cnt[k]=(cnt[k] or 0)+1 end
for k,v in pairs(cnt) do P(k,v) end
for _,s in ipairs(FindAllOf("ReadyOrNotPlayerState") or {}) do P("PS team", s.Team) end
