-- SUSPECT MODE v0.3 for Ready or Not (UE4SS Lua). Host-authoritative: the host's game swaps every
-- player to TT_SUSPECT, so AI suspects become your allies and the SWAT AI squad hunts you.
local dir = debug.getinfo(1,"S").source:gsub("^@",""):gsub("main%.lua$","")
local DEF = {SwatBase=6,SwatPerPlayer=2,SwatMax=24,ReinforceEvery=120,ReinforceSize=2,ReinforceWaves=3,SwatIntelEvery=20,SpawnAway=true,EnemyMode="hunters",HunterDropMin=2500,HunterDropMax=4500,BreachGrace=10,DressEnemiesAsSwat=true}
local okc, cfg = pcall(dofile, dir.."config.lua"); if not okc or type(cfg)~="table" then cfg = {Enabled=true,PrepSeconds=60,WinMode="timer",SurviveSeconds=600,KillTarget=4,SuspectHealthMult=2.5,StunResist=true,StunMaxSeconds=0.75,AnnounceEvery=60,SwatBase=6,SwatPerPlayer=2,SwatMax=24,ReinforceEvery=120,ReinforceSize=2,ReinforceWaves=3,ToggleKey="F7",StatusKey="F8"} end
for k,v in pairs(DEF) do if cfg[k]==nil then cfg[k]=v end end  -- old config.lua files keep working
local TT_SUSPECT, TT_SWAT = 3, 1
local SWAT_CLASS = "/Game/Blueprints/Characters/AI/CyberneticsSwat_V2.CyberneticsSwat_V2_C"
local S = { map=nil, phase="idle", t0=0, prepEnd=0, lastAnn=0, done=false, limbs={} }
local LIMBS = {"Head","LeftArm","RightArm","LeftLeg","RightLeg"}
_G.RonSuspect = { cfg=cfg, S=S }

local function log(m) print("[SuspectMode] "..m.."\n") end
local function valid(o) return o and o.IsValid and o:IsValid() end
local function list(cls) local t = FindAllOf(cls) return t or {} end

local function chat(msg)
  log(msg)
  local gs = FindFirstOf("ReadyOrNotGameState"); if not valid(gs) then return end
  pcall(function() gs:Multicast_BroadcastChatMessage({SenderName="SUSPECT MODE", Message=msg,
    Color={R=1,G=0.25,B=0.15,A=1}, AssociatedTeam=TT_SUSPECT, TargetTeam=0}) end)
end

-- Real player pawns only: the pre-mission lobby shows BasePlayer_Customization_C mannequins, which are
-- PlayerCharacters too, and must not start the mode or count as players.
local function playerChars()
  local r={} for _,c in ipairs(list("PlayerCharacter")) do
    if valid(c) and not c:GetClass():GetFName():ToString():find("Customization") and valid(c.Controller) then r[#r+1]=c end end
  return r
end
local function isHost() return valid(FindFirstOf("ReadyOrNotGameMode")) end
local function inMission()
  local w = FindFirstOf("World"); if not valid(w) then return nil end
  local n = w:GetFullName(); if n:find("/Menu/") or n:find("PreMission") then return nil end
  -- Key the mission on the GameMode instance, not the map name: replaying the same map is a new mission.
  local gm = FindFirstOf("ReadyOrNotGameMode"); if valid(gm) then n = gm:GetFullName() end
  if n ~= S.map and #playerChars() == 0 then return nil end  -- wait for the first real spawn; after that the map stays "in mission"
  return n
end

-- The map keeps spare "trailer" SWAT parked far below the level (z = -10000); they are not part of the fight.
local function swatChars() local r={} for _,c in ipairs(list("SWATCharacter")) do if valid(c) and c:K2_GetActorLocation().Z > -5000 then r[#r+1]=c end end return r end
-- EnemyMode "hunters": the game's SWAT AI never fights players, so the enemy is the game's own hostile AI
-- (suspect AI from the map's AISpawn actors), which attacks SWAT-team players by itself. Players keep
-- their team in this mode and the AI squad is removed. EnemyMode "swat" is the old team-swap mode.
local function hunters() return cfg.EnemyMode ~= "swat" end
local function enemies()
  if not hunters() then return swatChars() end
  local r={} for _,c in ipairs(list("SuspectCharacter")) do if valid(c) then r[#r+1]=c end end return r
end
-- Hunters mode: every hostile AI is suspect AI under the hood (the only AI that shoots players), so it is dressed
-- as SWAT: SWAT uniform body + masked SWAT head, with the SWAT mesh's own materials (the suspect's material
-- overrides would otherwise paint the uniform as a jacket). Cosmetic and local, so it runs on host AND clients.
local CH = "/Game/ReadyOrNot/Character/SWAT/"
local SWAT_BODIES = { CH.."SWAT_Officer/Uniform_Heavy/SK_SWAT_U_Heavy_01.SK_SWAT_U_Heavy_01", CH.."SWAT_Officer/Uniform_Light/SK_SWAT_U_Light_01.SK_SWAT_U_Light_01" }
local SWAT_HEADS  = { CH.."Heads/Swan/Meshes/head_swan_masked_LOD0_opt.head_swan_masked_LOD0_opt", CH.."Heads/Judge/Meshes/SK_SWAT_Head_Judge_Helmet_Masked_opt.SK_SWAT_Head_Judge_Helmet_Masked_opt" }
local function asset(path)
  local a = StaticFindObject(path)
  if not valid(a) then pcall(function() LoadAsset(path:gsub("%.[^.]+$","")) end) a = StaticFindObject(path) end
  return valid(a) and a or nil
end
local function setMesh(comp, mesh)
  if not (valid(comp) and mesh) then return false end
  local ok = pcall(function() comp:SetSkeletalMeshAsset(mesh) end)
  if not ok then ok = pcall(function() comp:SetSkeletalMesh(mesh, false) end) end
  if ok then pcall(function() local mats = mesh.Materials for i=1,#mats do comp:SetMaterial(i-1, mats[i].MaterialInterface) end end) end
  return ok
end
S.dressed = {}
local function dressHunters()
  if not cfg.Enabled or cfg.EnemyMode == "swat" or cfg.DressEnemiesAsSwat == false then return end
  -- Checked every tick, not once: the game applies the suspect's own look (async, after spawn / on replication)
  -- and that would silently undo an early dress.
  for _,c in ipairs(list("SuspectCharacter")) do if valid(c) then
    local cur = ""; pcall(function() cur = c.Mesh.SkeletalMesh:GetFName():ToString() end)
    if not cur:find("SWAT") then
      local key = c:GetFullName()
      local n = (#key % 2) + 1  -- stable per pawn
      setMesh(c.Mesh, asset(SWAT_BODIES[n]))
      setMesh(c.FaceMesh, asset(SWAT_HEADS[n]))
      S.dressed[key] = (S.dressed[key] or 0) + 1
    end
  end end
end

local function swatAlive() local n=0 for _,c in ipairs(enemies()) do if not c:IsHealthDepleted() then n=n+1 end end return n end
local function swatDead() local n=0 for _,c in ipairs(enemies()) do if c:IsHealthDepleted() then n=n+1 end end return n end

local function players() return #playerChars() end
local function playersAlive() local n=0 for _,c in ipairs(playerChars()) do if not c:IsHealthDepleted() then n=n+1 end end return n end

-- M1: spawn extra SWAT AI. Anchor = where the map's own squad stands (remembered once), else a
-- reachable point well away from the players. Each one lands on the navmesh near the anchor.
-- A pawn spawned from the class alone has an empty inventory (no gun, no armour), so every spawned
-- operator gets a kit: the same items the map's own squad carries, with a random primary.
local IT = "/Game/Blueprints/Items/"
local KIT = { IT.."ArmorRevised/Armor_Light_V2.Armor_Light_V2_C", IT.."ArmorRevised/Helmets/BP_Helmet_Standard.BP_Helmet_Standard_C",
              IT.."WeaponsRevised/Secondary_G19_V2.Secondary_G19_V2_C" }
local PRIMARIES = { IT.."WeaponsRevised/Primary_MCX.Primary_MCX_C", IT.."WeaponsRevised/Primary_BRN180.Primary_BRN180_C",
                    IT.."WeaponsRevised/Primary_SPC9.Primary_SPC9_C", IT.."WeaponsRevised/Primary_Superbnova.Primary_Superbnova_C" }
local function class(path)
  local c = StaticFindObject(path)
  if not valid(c) then pcall(function() LoadAsset(path:gsub("%.[^.]+$","")) end) c = StaticFindObject(path) end
  return valid(c) and c or nil
end
local function giveKit(p)
  local G = StaticFindObject("/Script/Engine.Default__GameplayStatics"); local inv = p.InventoryComp
  if not valid(G) or not valid(inv) then return false end
  local l = p:K2_GetActorLocation()
  local T = {Rotation={X=0,Y=0,Z=0,W=1},Translation={X=l.X,Y=l.Y,Z=l.Z},Scale3D={X=1,Y=1,Z=1}}
  local function give(path)
    local cls = class(path); if not cls then return nil end
    local it = G:BeginDeferredActorSpawnFromClass(p,cls,T,1,p,0); if not valid(it) then return nil end
    G:FinishSpawningActor(it,T,0)
    return inv:AddInventoryItem(it) and cls or nil
  end
  for _,path in ipairs(KIT) do give(path) end
  local first = math.random(1,#PRIMARIES)
  for i=0,#PRIMARIES-1 do  -- try the random pick first, then the others, until one primary works
    local prim = give(PRIMARIES[(first+i-1) % #PRIMARIES + 1])
    if prim then inv:EquipItemOfClass(prim,true) return true end
  end
  return false
end

local function swatAnchor()
  if S.anchor then return S.anchor end
  for _,c in ipairs(swatChars()) do if not c:IsHealthDepleted() then local l=c:K2_GetActorLocation() S.anchor={X=l.X,Y=l.Y,Z=l.Z} return S.anchor end end
  local N = StaticFindObject("/Script/NavigationSystem.Default__NavigationSystemV1")
  local pl = playerChars()[1]
  if not valid(N) or not pl then return nil end
  local o, best, bestD = pl:K2_GetActorLocation(), nil, -1
  for _=1,12 do local out={} if N:K2_GetRandomReachablePointInRadius(pl,{X=o.X,Y=o.Y,Z=o.Z},out,8000.0,nil,nil) then
    local d=(out.X-o.X)^2+(out.Y-o.Y)^2 if d>bestD then bestD=d best={X=out.X,Y=out.Y,Z=out.Z} end end end
  S.anchor = best; return best
end

local function spawnSwat(n)
  if n <= 0 then return 0 end
  local H = StaticFindObject("/Script/AIModule.Default__AIBlueprintHelperLibrary")
  local N = StaticFindObject("/Script/NavigationSystem.Default__NavigationSystemV1")
  local cls = class(SWAT_CLASS)
  local ctx = FindFirstOf("ReadyOrNotGameMode"); local a = swatAnchor()
  if not valid(H) or not valid(N) or not cls or not a then log("spawnSwat: missing helper/class/anchor") return 0 end
  local made, armed = 0, 0
  for _=1,n do
    local out = {}
    if not N:K2_GetRandomReachablePointInRadius(ctx,a,out,500.0,nil,nil) then out = a end
    local ok, p = pcall(function() return H:SpawnAIFromClass(ctx,cls,nil,{X=out.X,Y=out.Y,Z=out.Z+100},{Pitch=0,Yaw=math.random(0,359),Roll=0},true,nil) end)
    if ok and valid(p) then made = made + 1
      pcall(function() p.DefaultTeam = TT_SWAT p:HandleTeamChanged(TT_SWAT) end)
      local okk, got = pcall(giveKit, p); if okk and got then armed = armed + 1 else log("kit failed: "..tostring(got)) end
    end
  end
  log("spawned "..made.."/"..n.." SWAT, armed "..armed)
  return made
end

-- Hunters patrol where they spawn and do not walk to the players on their own, so they are dropped
-- on the navmesh HunterDropMin..HunterDropMax cm from a random living player; from there they fight natively.
local function nearestPlayerDist(c)
  local l, best = c:K2_GetActorLocation(), 1e12
  for _,pl in ipairs(playerChars()) do if not pl:IsHealthDepleted() then local o = pl:K2_GetActorLocation()
    local d = (l.X-o.X)^2+(l.Y-o.Y)^2 if d < best then best = d end end end
  return math.sqrt(best)
end
local function dropNear(c)
  local N = StaticFindObject("/Script/NavigationSystem.Default__NavigationSystemV1"); if not valid(N) then return false end
  local alive = {} for _,pl in ipairs(playerChars()) do if not pl:IsHealthDepleted() then alive[#alive+1] = pl end end
  if #alive == 0 then return false end
  local pl = alive[math.random(1,#alive)]; local o = pl:K2_GetActorLocation()
  local best, bestD = nil, -1
  for _=1,12 do local out = {}
    if N:K2_GetRandomReachablePointInRadius(pl,{X=o.X,Y=o.Y,Z=o.Z},out,cfg.HunterDropMax,nil,nil) then
      local d = math.sqrt((out.X-o.X)^2+(out.Y-o.Y)^2)
      if d > bestD then bestD = d best = out end
      if d >= cfg.HunterDropMin then break end
    end
  end
  if not best then return false end
  local ok = c:K2_TeleportTo({X=best.X,Y=best.Y,Z=best.Z+90},{Pitch=0,Yaw=math.random(0,359),Roll=0})
  pcall(function() c.Controller.TargetingComponent:AddKnownEnemy(pl,true) end)
  return ok
end

-- Spawned SWAT sense players but never act on it, and the map's squad only reacts to what it sees.
-- "Intel": put every living player on each operator's known-enemy list so the whole element hunts.
local function swatIntel()
  local n = 0
  for _,c in ipairs(enemies()) do if not c:IsHealthDepleted() then pcall(function()
    local tc = c.Controller.TargetingComponent
    for _,pl in ipairs(playerChars()) do if not pl:IsHealthDepleted() then tc:AddKnownEnemy(pl,true) n = n + 1 end end
    if hunters() and nearestPlayerDist(c) > cfg.HunterDropMax * 1.5 then dropNear(c) end  -- bring stragglers back into the fight
  end) end end
  return n
end

-- Players start at the SWAT entry point, next to the squad. Move each one once, during setup, to the
-- reachable spot farthest from the squad so they begin as suspects somewhere on the map.
local function moveAway()
  S.moved = S.moved or {}
  local N = StaticFindObject("/Script/NavigationSystem.Default__NavigationSystemV1"); if not valid(N) then return end
  local a = S.anchor
  if not a then local sw; for _,c in ipairs(swatChars()) do if not c:IsHealthDepleted() then sw = c break end end
    if not sw then return end  -- the squad spawns a moment after the players
    a = sw:K2_GetActorLocation() end
  for _,pl in ipairs(playerChars()) do local key = pl:GetFullName()
    if not S.moved[key] then
      local best, bestD = nil, -1
      for _=1,24 do local out={} if N:K2_GetRandomReachablePointInRadius(pl,{X=a.X,Y=a.Y,Z=a.Z},out,12000.0,nil,nil) then
        local d=(out.X-a.X)^2+(out.Y-a.Y)^2 if d>bestD then bestD=d best=out end end end
      if best and bestD > 1500^2 then
        local r = pl:K2_GetActorRotation()
        pl:K2_TeleportTo({X=best.X,Y=best.Y,Z=best.Z+100},{Pitch=0,Yaw=r.Yaw,Roll=0})
        log(("moved a player %.0f m away from SWAT"):format(math.sqrt(bestD)/100))
      end
      S.moved[key] = true
    end
  end
end

-- Hunters come from the map's own AISpawn actors (fully set-up AI; hand-spawned suspects crash the game).
-- An unused spawner is fired where it stands and the hunter is dropped near a player; civilians it produces are removed.
local function spawnHunters(n)
  if n <= 0 then return 0 end
  local N = StaticFindObject("/Script/NavigationSystem.Default__NavigationSystemV1")
  local ctx = FindFirstOf("ReadyOrNotGameMode"); local a = swatAnchor()
  local pool = {}
  for _,s in ipairs(list("AISpawn")) do if valid(s) then local c = s.SpawnedCharacter
    if not valid(c) or c:IsHealthDepleted() then pool[#pool+1] = s end end end
  local made, tries = 0, 0
  while made < n and #pool > 0 and tries < n * 6 do tries = tries + 1
    local s = table.remove(pool, math.random(1,#pool))
    pcall(function()
      s.bEnabled = true; s.SpawnChance = 1.0; s:DoSpawn()
    end)
    local c = s.SpawnedCharacter
    if valid(c) and not c:IsHealthDepleted() then
      if c:GetClass():GetFName():ToString():find("Suspect") then made = made + 1; pcall(dropNear, c)
      else pcall(function() c:K2_DestroyActor() end) end
    end
  end
  log("spawned "..made.."/"..n.." hunters ("..#pool.." spawners left)")
  return made
end

-- Hunters mode: remember where the AI squad stood (the entry point), then remove it so it cannot help the players.
local function dropSquad()
  if S.squadGone then return end
  local all = list("SWATCharacter"); if #all == 0 then return end
  swatAnchor()
  for _,c in ipairs(all) do if valid(c) then pcall(function() c:K2_DestroyActor() end) end end
  S.squadGone = true; log("AI squad removed")
end

local function swatTarget() return math.min(cfg.SwatMax, cfg.SwatBase + cfg.SwatPerPlayer * players()) end

local function makeSuspects(prep)
  local swap = not hunters()
  if swap then for _,ps in ipairs(list("ReadyOrNotPlayerState")) do if valid(ps) and ps.Team ~= TT_SUSPECT then ps.Team = TT_SUSPECT end end end
  for _,c in ipairs(playerChars()) do if valid(c) then
    if swap and c:GetTeam() ~= TT_SUSPECT then pcall(function() c.DefaultTeam = TT_SUSPECT c:HandleTeamChanged(TT_SUSPECT) end) end
    c.bGodMode = prep and true or false
    local key = c:GetFullName()
    if not S.limbs[key] then  -- tougher suspects: scale per-limb damage multipliers once per character
      local h = c.CharacterHealth
      if valid(h) then for _,l in ipairs(LIMBS) do pcall(function() local L=h[l] L.LimbDamageMultiplier = L.LimbDamageMultiplier / math.max(0.1,cfg.SuspectHealthMult) end) end S.limbs[key]=true end
    end
    if cfg.StunResist and not prep then
      S.stun = S.stun or {}
      pcall(function()
        if c:IsStunned() then
          S.stun[key] = S.stun[key] or os.clock()
          if os.clock() - S.stun[key] > cfg.StunMaxSeconds then c.bRepStunned = false; S.stun[key] = nil end
        else S.stun[key] = nil end
      end)
    end
  end end
  local blind = prep or (S.graceEnd and os.time() < S.graceEnd)  -- setup time, then a short grace after the breach
  for _,c in ipairs(enemies()) do pcall(function() c.Controller.bDisableSensePerception = blind and true or false end) end
end

local function fmt(s) s=math.max(0,math.floor(s)) return string.format("%d:%02d", s//60, s%60) end

local function win(reason)
  S.done = true; S.phase = "won"
  chat("SUSPECTS WIN - "..reason.."  (remaining SWAT stand down)")
  for _,c in ipairs(enemies()) do if not c:IsHealthDepleted() then pcall(function() c:Kill() end) end end
end

local function lose()
  S.done = true; S.phase = "lost"
  chat("SWAT WINS - all suspects are down. SWAT left: "..swatAlive())
end

local function tick()
  if not cfg.Enabled or not isHost() then return end
  local map = inMission()
  if not map then S.map=nil S.phase="idle" return end
  if map ~= S.map then -- new mission
    S.map=map S.phase="prep" S.done=false S.limbs={} S.anchor=nil S.waves=0 S.moved={} S.squadGone=false S.graceEnd=nil S.dressed={} S.t0=os.time() S.prepEnd=S.t0+cfg.PrepSeconds S.lastAnn=0
    chat(("You are the SUSPECTS. %ds to set up - SWAT AI hunts you after that. Goal: %s"):format(cfg.PrepSeconds,
      cfg.WinMode=="kills" and ("kill "..cfg.KillTarget.." SWAT") or ("survive "..fmt(cfg.SurviveSeconds))))
  end
  local now = os.time()
  if S.phase=="prep" and now >= S.prepEnd then S.phase="live" S.liveStart=now S.lastAnn=now S.lastWave=now S.lastIntel=now S.graceEnd=now+cfg.BreachGrace
    local need = swatTarget() - swatAlive()
    if hunters() then spawnHunters(need) else spawnSwat(need) end  -- top the map's squad up to SwatBase + SwatPerPlayer * players
    if cfg.SwatIntelEvery > 0 then swatIntel() end
    chat("SWAT IS BREACHING! "..swatAlive().." operators inbound.") end
  if S.done then return end
  if S.phase=="prep" and cfg.SpawnAway then moveAway() end
  if hunters() then dropSquad() end
  makeSuspects(S.phase=="prep")
  if S.phase=="live" then
    if playersAlive() == 0 then return lose() end
    if cfg.SwatIntelEvery > 0 and now - S.lastIntel >= cfg.SwatIntelEvery then S.lastIntel = now; swatIntel() end
    if cfg.WinMode=="kills" and swatDead() >= cfg.KillTarget then return win(swatDead().." SWAT down") end
    if cfg.WinMode~="kills" and now - S.liveStart >= cfg.SurviveSeconds then return win("you held out "..fmt(cfg.SurviveSeconds)) end
    local alive, wavesLeft = swatAlive(), cfg.ReinforceEvery > 0 and S.waves < cfg.ReinforceWaves
    if wavesLeft and (alive==0 or now - S.lastWave >= cfg.ReinforceEvery) then  -- reinforcements: on a timer, or at once after a wipe
      S.lastWave = now; S.waves = S.waves + 1
      local add = math.min(cfg.ReinforceSize, cfg.SwatMax - alive)
      local made = hunters() and spawnHunters(add) or spawnSwat(add)
      if cfg.SwatIntelEvery > 0 then swatIntel() end
      if made > 0 then chat(("SWAT REINFORCEMENTS: +%d (wave %d/%d)"):format(made, S.waves, cfg.ReinforceWaves)) end
      alive = swatAlive()
    end
    if #enemies()>0 and alive==0 and not (cfg.ReinforceEvery > 0 and S.waves < cfg.ReinforceWaves) then return win("entire SWAT element neutralised") end
    if now - S.lastAnn >= cfg.AnnounceEvery then S.lastAnn=now
      chat(cfg.WinMode=="kills" and ("SWAT down: "..swatDead().."/"..cfg.KillTarget) or ("Hold out: "..fmt(cfg.SurviveSeconds-(now-S.liveStart)).." left, SWAT alive "..swatAlive())) end
  elseif S.phase=="prep" and now - S.lastAnn >= 15 then S.lastAnn=now chat("Setup time: "..fmt(S.prepEnd-now)) end
end

LoopAsync(500, function() ExecuteInGameThread(function()
  local ok,e=pcall(tick) if not ok then log("tick error: "..tostring(e)) end
  ok,e=pcall(dressHunters) if not ok then log("dress error: "..tostring(e)) end  -- every machine, not just the host
end) return false end)

local function key(name) return Key[name] or Key.F7 end
RegisterKeyBind(key(cfg.ToggleKey), function() ExecuteInGameThread(function()
  cfg.Enabled = not cfg.Enabled; if not cfg.Enabled then for _,c in ipairs(list("PlayerCharacter")) do pcall(function() c.bGodMode=false end) end end
  S.map=nil; chat("Suspect Mode "..(cfg.Enabled and "ON (restarts setup timer)" or "OFF")) end) end)
RegisterKeyBind(key(cfg.StatusKey), function() ExecuteInGameThread(function()
  chat(("phase=%s  SWAT alive=%d dead=%d  mode=%s"):format(S.phase, swatAlive(), swatDead(), cfg.WinMode)) end) end)
log("v0.3 loaded")
