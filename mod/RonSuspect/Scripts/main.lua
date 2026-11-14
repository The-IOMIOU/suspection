-- SUSPECT MODE v0.8 for Ready or Not (UE4SS Lua). Host-authoritative: the host's game swaps every
-- player to TT_SUSPECT, so AI suspects become your allies and the SWAT AI squad hunts you.
local dir = debug.getinfo(1,"S").source:gsub("^@",""):gsub("main%.lua$","")
local DEF = {SwatBase=6,SwatPerPlayer=2,SwatMax=24,ReinforceEvery=120,ReinforceSize=2,ReinforceWaves=3,SwatIntelEvery=20,SpawnAway=true,EnemyMode="hunters",HunterDropMin=2500,HunterDropMax=4500,BreachGrace=10,DressEnemiesAsSwat=true,Helpers=0,ProtectVIP=true,ShieldSeconds=20,ShieldCooldown=30}
local okc, cfg = pcall(dofile, dir.."config.lua"); if not okc or type(cfg)~="table" then cfg = {Enabled=true,PrepSeconds=60,WinMode="timer",SurviveSeconds=600,KillTarget=4,SuspectHealthMult=2.5,StunResist=true,StunMaxSeconds=0.75,AnnounceEvery=60,SwatBase=6,SwatPerPlayer=2,SwatMax=24,ReinforceEvery=120,ReinforceSize=2,ReinforceWaves=3,ToggleKey="F7",StatusKey="F8"} end
for k,v in pairs(DEF) do if cfg[k]==nil then cfg[k]=v end end  -- old config.lua files keep working
-- Presets: Preset = "standard" | "easy" | "hardcore" | "survival" | "custom". A preset overrides the matching
-- config.lua values; "custom" uses config.lua exactly as written.
local PRESETS = {
  standard = {Helpers=0, WinMode="eliminate", SwatBase=6, SwatPerPlayer=2, ReinforceEvery=0, EnemyAccuracy=0.55, SuspectHealthMult=2.5, PrepSeconds=60, BreachGrace=10, SwatIntelEvery=30},
  easy     = {Helpers=0, WinMode="eliminate", SwatBase=4, SwatPerPlayer=1, ReinforceEvery=0, EnemyAccuracy=0.35, SuspectHealthMult=4,   PrepSeconds=90, BreachGrace=15, SwatIntelEvery=45},
  hardcore = {Helpers=0, WinMode="eliminate", SwatBase=8, SwatPerPlayer=3, ReinforceEvery=150, ReinforceSize=3, ReinforceWaves=2, EnemyAccuracy=0.9, SuspectHealthMult=1.5, PrepSeconds=45, BreachGrace=5, SwatIntelEvery=20},
  survival = {Helpers=0, WinMode="timer", SurviveSeconds=600, SwatBase=6, SwatPerPlayer=2, ReinforceEvery=120, ReinforceSize=2, ReinforceWaves=3, EnemyAccuracy=0.55, SuspectHealthMult=2.5, PrepSeconds=60},
}
local pre = PRESETS[cfg.Preset or "standard"]
if pre then for k,v in pairs(pre) do cfg[k] = v end end
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
local function asset(path, noLoad)
  local a = StaticFindObject(path)
  if noLoad then return valid(a) and a or nil end  -- suspect looks: a forced LoadAsset mid-mission crashed the game twice
  if not valid(a) then pcall(function() LoadAsset(path) end) a = StaticFindObject(path) end  -- full object path loads it
  if not valid(a) then pcall(function() LoadAsset((path:gsub("%.[^.]+$",""))) end) a = StaticFindObject(path) end
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
-- Suspect looks seen this session (body/head + base materials), captured from the map's own suspects before
-- they are dressed as SWAT, and saved to looks.txt so the lobby and maps without suspects can use them too.
S.looks = S.looks or {}
local LOOKS_FILE = dir.."looks.txt"
local function pathOf(o) local ok,r = pcall(function() return (o:GetFullName():gsub("^%S+ ","")) end) return ok and r or nil end
local function baseMat(m)
  local ok,p = pcall(function() return m.Parent end)
  if ok and valid(p) and m:GetClass():GetFName():ToString():find("Dynamic") then return p end
  return m
end
local function matPaths(comp) local t = {} pcall(function() for i=0,comp:GetNumMaterials()-1 do t[#t+1] = pathOf(baseMat(comp:GetMaterial(i))) or "" end end) return t end
local function saveLooks()
  local f = io.open(LOOKS_FILE, "w"); if not f then return end
  for _,l in ipairs(S.looks) do f:write(l.body.."|"..l.head.."|"..table.concat(l.bm, ",").."|"..table.concat(l.hm, ",").."\n") end
  f:close()
end
local function loadLooks()
  local f = io.open(LOOKS_FILE, "r"); if not f then return end
  for line in f:lines() do
    local b,h,bm,hm = line:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)$")
    if b and b ~= "" then
      local l = {body=b, head=h, bm={}, hm={}}
      for x in bm:gmatch("[^,]+") do l.bm[#l.bm+1]=x end
      for x in hm:gmatch("[^,]+") do l.hm[#l.hm+1]=x end
      S.looks[#S.looks+1]=l
    end
  end
  f:close()
end
loadLooks()
local function captureLook(c)
  local b, h = pathOf(c.Mesh.SkeletalMesh), pathOf(c.FaceMesh.SkeletalMesh)
  if not b or b:find("SWAT") then return end
  for _,l in ipairs(S.looks) do if l.body == b then return end end
  S.looks[#S.looks+1] = {body=b, head=h or "", bm=matPaths(c.Mesh), hm=matPaths(c.FaceMesh)}
  table.sort(S.looks, function(x,y) return x.body < y.body end)  -- same order on every machine
  saveLooks(); log("captured suspect look "..(b:match("[^/.]+$") or b))
end
local function applyMats(comp, paths)
  for i,pth in ipairs(paths) do local m = asset(pth, true) if m then pcall(function() comp:SetMaterial(i-1, m) end) end end
end

local function nameHash(s) local h=0 for i=1,#s do h=(h*31+s:byte(i))%100003 end return h end
-- Armoured, serious SWAT: a plate carrier and a ballistic helmet are added to every enemy as extra skeletal
-- meshes that follow the body's animation (leader pose). Same meshes the players' own kit uses.
local SWAT_GEAR = { CH.."SWAT_FRAS_Vest/SK_FRAS_Armor_Var01.SK_FRAS_Armor_Var01",
                    CH.."SWAT_Mandible/SK_Helmet_Mandible_NoGoggles.SK_Helmet_Mandible_NoGoggles" }
S.armoured = {}
function armourUp(c)
  local key = c:GetFullName(); if S.armoured[key] then return end
  local skc = StaticFindObject("/Script/Engine.SkeletalMeshComponent")
  local n = 0
  if not S.gearFallback then  -- any loaded SWAT vest / helmet, if the preferred ones aren't in memory on this map
    S.gearFallback = {}
    for _,sm in ipairs(list("SkeletalMesh")) do local fn = sm:GetFullName()
      if fn:find("/Character/SWAT/") then
        if not S.gearFallback[1] and (fn:find("Armor") or fn:find("Vest")) then S.gearFallback[1] = sm end
        if not S.gearFallback[2] and fn:find("Helmet") and not fn:find("Head") then S.gearFallback[2] = sm end
      end end
  end
  for gi,path in ipairs(SWAT_GEAR) do local m = asset(path, true) or S.gearFallback[gi]
    if m then local comp = c:AddComponentByClass(skc, false, {Translation={X=0,Y=0,Z=0}, Rotation={X=0,Y=0,Z=0,W=1}, Scale3D={X=1,Y=1,Z=1}}, false)
      if valid(comp) then
        pcall(function() comp:K2_AttachToComponent(c.Mesh, FName("None"), 2, 2, 2, false) end)
        pcall(function() comp:SetSkeletalMeshAsset(m) end)
        pcall(function() comp:SetLeaderPoseComponent(c.Mesh, false, false) end)
        pcall(function() comp:SetMasterPoseComponent(c.Mesh, false) end)
        n = n + 1 end end end
  S.armoured[key] = n > 0
end

local SWAT_VOICES = {"SWATSwan","SWATKing","SWATPrescott","SWATEli","SWATJudge"}
local function nerfAim(c)
  if not cfg.EnemyAccuracy then return end
  pcall(function()
    local a = c.Archetype
    if valid(a) and math.abs(a.Accuracy - cfg.EnemyAccuracy) > 0.001 then a.bAccuracyOverride = true; a.Accuracy = cfg.EnemyAccuracy end
  end)
end
local function dressHunters()
  if not cfg.Enabled or cfg.EnemyMode == "swat" or cfg.DressEnemiesAsSwat == false then return end
  -- Checked every tick, not once: the game applies the suspect's own look (async, after spawn / on replication)
  -- and that would silently undo an early dress.
  for _,c in ipairs(list("SuspectCharacter")) do if valid(c) then
    local cur = ""; pcall(function() cur = c.Mesh.SkeletalMesh:GetFName():ToString() end)
    if not cur:find("SWAT") then
      pcall(captureLook, c)
      if not S.susVoice then pcall(function() local v = c.SpeechCharacterName:ToString() if not v:find("SWAT") then S.susVoice = v end end) end
      local key = c:GetFullName()
      local n = (#key % 2) + 1  -- stable per pawn
      setMesh(c.Mesh, asset(SWAT_BODIES[n]))
      setMesh(c.FaceMesh, asset(SWAT_HEADS[n]))
      pcall(armourUp, c)
      if cfg.SwatVoices ~= false then pcall(function() c.SpeechCharacterName = SWAT_VOICES[(nameHash(key) % #SWAT_VOICES) + 1] end) end
      S.dressed[key] = (S.dressed[key] or 0) + 1
    end
    nerfAim(c)
  end end
end

-- LOOK EDITOR (every machine): F9 / Shift+F9 = next / previous body, F10 / Shift+F10 = next / previous head,
-- F11 = extras (none, armour, helmet, armour + helmet). Saved to mylook.txt. Every change is sent as a chat line
-- "#look <body> <head> <extras>" so the other players' games dress you the same way (they read the game's chat log).
local MYLOOK_FILE = dir.."mylook.txt"
local function shortName(path) return (path or ""):match("([^/.]+)$") or "" end
local function findLook(short)
  for _,l in ipairs(S.looks) do if shortName(l.body) == short or shortName(l.head) == short then return l end end
end
local my = { body = nil, head = nil, extras = 1 }
do local f = io.open(MYLOOK_FILE, "r")
  if f then local b,h,e = (f:read("l") or ""):match("^(%S+) (%S+) (%d)") f:close()
    if b then my.body, my.head, my.extras = b, h, tonumber(e) end end end
local function saveMy() local f = io.open(MYLOOK_FILE, "w") if f then f:write(("%s %s %d\n"):format(my.body, my.head, my.extras)) f:close() end end
local function localPC() local pc = FindFirstOf("ReadyOrNotPlayerController") return valid(pc) and pc or nil end
local function localName() local n = "" pcall(function() n = localPC().PlayerState:GetPlayerName():ToString() end) return n end
local function sayLocal(msg)  -- multicast called on the local machine only runs locally: private feedback line
  log(msg) local gs = FindFirstOf("ReadyOrNotGameState")
  pcall(function() gs:Multicast_BroadcastChatMessage({SenderName="LOOK", Message=msg, Color={R=0.6,G=0.9,B=1,A=1}}) end)
end
local function sendLook()
  if not my.body then return end
  local pc = localPC(); if not pc then return end
  pcall(function() pc:Server_SendChatMessage({SenderName=localName(), SenderPlayerState=pc.PlayerState,
    Message=("#look %s %s %d"):format(my.body, my.head, my.extras)}) end)
  S.lastLookSent = os.time()
end
local remote = {}  -- player name -> choice, parsed from chat
local function readChatLooks()
  local gs = FindFirstOf("ReadyOrNotGameState"); if not valid(gs) then return end
  pcall(function()
    local arr = gs.SavedChatMessages
    for i = 1, #arr do local m = arr[i]
      local b,h,e = m.Message:ToString():match("^#look (%S+) (%S+) (%d)")
      if b then remote[m.SenderName:ToString()] = {body=b, head=h, extras=tonumber(e)} end
    end
  end)
end
function lookChoiceFor(c, who)
  local mine = false; pcall(function() mine = c.Controller == localPC() end)
  if mine or (who ~= "" and who == localName()) then return my.body and my or nil end
  return remote[who]
end
local EXTRAS = {[0]="no armour, no helmet", [1]="armour", [2]="helmet", [3]="armour + helmet"}
local function cycle(part, step)
  if #S.looks == 0 then return sayLocal("No suspect looks yet: play one mission with suspects first.") end
  local cur = part == "body" and my.body or my.head
  local i = 0 for k,l in ipairs(S.looks) do if shortName(part=="body" and l.body or l.head) == cur then i = k end end
  i = ((i - 1 + step) % #S.looks) + 1
  local l = S.looks[i]
  if part == "body" then my.body = shortName(l.body); my.head = my.head or shortName(l.head)
  else my.head = shortName(l.head); my.body = my.body or shortName(l.body) end
  saveMy(); sendLook()
  sayLocal(("%s %d/%d: %s   (F9 body, F10 head, F11 extras)"):format(part, i, #S.looks, part=="body" and my.body or my.head))
end
local function cycleExtras()
  if not my.body then cycle("body", 0) end
  my.extras = (my.extras + 1) % 4; saveMy(); sendLook(); sayLocal("extras: "..EXTRAS[my.extras])
end
S.editor = { cycle = cycle, extras = cycleExtras, my = my, remote = remote }

-- No reporting: suspects don't call TOC. Every character counts as already reported, report-able props are
-- switched off and TOC reports are disabled, so the "Report" prompt never shows. Host-side (replicated).
local function noReports()
  local gs = FindFirstOf("ReadyOrNotGameState")
  if valid(gs) and gs.bCanReportToTOC then gs.bCanReportToTOC = false end
  for _,c in ipairs(list("ReadyOrNotCharacter")) do if valid(c) and not c.bHasBeenReported then pcall(function() c.bHasBeenReported = true end) end end
  for _,r in ipairs(list("ReportableActor")) do if valid(r) and r.bReportableEnabled then pcall(function() r.bReportableEnabled = false end) end end
end

-- Players dressed as suspects (3rd-person body seen by everyone else, and the lobby mannequins): the SWAT
-- customization parts and helmet are hidden, the base body/head become a captured suspect look. Armour can stay on top.
-- Each player gets a look from their name (same on every machine); SuspectLook = n in config.lua forces one.
local function dressPlayers()
  if not cfg.Enabled or cfg.DressPlayersAsSuspects == false or #S.looks == 0 then return end
  local comps = nil
  for _,c in ipairs(list("PlayerCharacter")) do if valid(c) then
    local who = ""; pcall(function() who = c.PlayerState:GetPlayerName():ToString() end)
    local idx = (cfg.SuspectLook and cfg.SuspectLook > 0) and ((cfg.SuspectLook-1) % #S.looks + 1)
                or (nameHash(who ~= "" and who or c:GetFName():ToString()) % #S.looks + 1)
    local look = S.looks[idx]
    local choice = lookChoiceFor(c, who)  -- look editor (F9/F10/F11), synced through chat
    local bodyL, headL = look, look
    if choice then bodyL = findLook(choice.body) or look; headL = findLook(choice.head) or bodyL end
    local cur = pathOf(c.Mesh.SkeletalMesh) or ""
    local curH = pathOf(c.FaceMesh.SkeletalMesh) or ""
    if cur ~= bodyL.body then
      local body = asset(bodyL.body, true)
      if body then pcall(function() c.Mesh:SetSkeletalMeshAsset(body) end) applyMats(c.Mesh, bodyL.bm) end
    end
    if curH ~= headL.head then
      local head = asset(headL.head, true)
      if head then pcall(function() c.FaceMesh:SetSkeletalMeshAsset(head) end) applyMats(c.FaceMesh, headL.hm) end
    end
    local keepArmor = cfg.DressKeepArmor ~= false
    local keepHelmet = false
    if choice then keepArmor = choice.extras == 1 or choice.extras == 3; keepHelmet = choice.extras >= 2 end
    comps = comps or list("SkeletalMeshComponent")
    local me = c:GetFullName()
    for _,comp in ipairs(comps) do
      local ok, own = pcall(function() return comp:GetOwner():GetFullName() end)
      if ok and own == me then
        local n = comp:GetFName():ToString()
        local hide = n:find("^SkeletalMesh_CSK") or n == "CustomizationFaceMesh"
        if n == "HelmetVisualizationComponent" then hide = not keepHelmet end
        if n == "ArmorVisualizationComponent" then hide = not keepArmor end
        if hide and comp:IsVisible() then pcall(function() comp:SetVisibility(false, false) end)
        elseif not hide and (n == "HelmetVisualizationComponent" or n == "ArmorVisualizationComponent") and not comp:IsVisible() then
          pcall(function() comp:SetVisibility(true, false) end) end
      end
    end
  end end
end

local function isDown(c) local d = false pcall(function() d = c:IsHealthDepleted() or c.bArrestComplete or c.bSurrenderComplete end) return d end
local function swatAlive() local n=0 for _,c in ipairs(enemies()) do if not isDown(c) then n=n+1 end end return n end
local function swatDead() local n=0 for _,c in ipairs(enemies()) do if isDown(c) then n=n+1 end end return n end

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
  if not valid(c) then pcall(function() LoadAsset(path) end) c = StaticFindObject(path) end
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
-- The AI squad is removed, except cfg.Helpers members who stay as AI suspect helpers: the game's SWAT AI
-- fights suspect AI on its own and follows the players, so dressed as suspects they are exactly "other suspects but AI".
local function dropSquad()
  if S.squadGone then return end
  local all = list("SWATCharacter"); if #all == 0 then return end
  swatAnchor()
  S.helpers = {}
  local active = swatChars()
  for i,c in ipairs(active) do if i <= (cfg.Helpers or 0) then S.helpers[#S.helpers+1] = c end end
  local keep = {} for _,c in ipairs(S.helpers) do keep[c:GetFullName()] = true end
  for _,c in ipairs(all) do if valid(c) and not keep[c:GetFullName()] then pcall(function() c:K2_DestroyActor() end) end end
  S.squadGone = true; log("AI squad removed, "..#S.helpers.." kept as suspect helpers")
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
  for _,c in ipairs(enemies()) do pcall(function() local ct = c.Controller if valid(ct) then ct.bDisableSensePerception = blind and true or false end end) end
end

local function fmt(s) s=math.max(0,math.floor(s)) return string.format("%d:%02d", s//60, s%60) end

-- ===== M4: hostages, helpers, VIP ==========================================================================
local function setTeam(c, T)
  pcall(function() if c.PlayerState and c.PlayerState:IsValid() then c.PlayerState.Team = T end end)
  pcall(function() c.DefaultTeam = T; c:HandleTeamChanged(T) end)
end
local function pname(c) local n = "" pcall(function() n = c.PlayerState:GetPlayerName():ToString() end) return n ~= "" and n or "a suspect" end
local function fwdPoint(c, dist)
  local l = c:K2_GetActorLocation(); local yaw = c:K2_GetActorRotation().Yaw
  pcall(function() yaw = c.Controller:GetControlRotation().Yaw end)
  local y = math.rad(yaw); return {X=l.X+math.cos(y)*dist, Y=l.Y+math.sin(y)*dist, Z=l.Z}, yaw
end

-- Command channel: a key on any machine runs the command on the host for that player. On a client the key
-- sends "#cmd <name> <seq>" through chat; the host reads the chat log and runs each new seq once per sender.
local CMD = {}
local cmdSeq, lastSeq = 0, {}
local function runCmd(name)
  local pc = localPC(); if not pc then return end
  if isHost() then local p = pc.Pawn if valid(p) and CMD[name] then CMD[name](p) end return end
  cmdSeq = cmdSeq + 1
  pcall(function() pc:Server_SendChatMessage({SenderName=localName(), SenderPlayerState=pc.PlayerState, Message=("#cmd %s %d"):format(name, cmdSeq)}) end)
end
local function hostReadCmds()
  local gs = FindFirstOf("ReadyOrNotGameState"); if not valid(gs) then return end
  local arr = gs.SavedChatMessages
  for i = 1, #arr do local m = arr[i]
    local name, seq = m.Message:ToString():match("^#cmd (%w+) (%d+)")
    if name then local who = m.SenderName:ToString(); seq = tonumber(seq)
      if seq > (lastSeq[who] or 0) then lastSeq[who] = seq
        for _,c in ipairs(playerChars()) do if pname(c) == who and CMD[name] then CMD[name](c) end end end end
  end
end

-- Human shield: grab the nearest civilian (3 m), they surrender and are held in front of you. While you hold
-- them you count as suspect team, and the SWAT (suspect AI underneath) only shoot SWAT-team targets, so they
-- hold fire. Limited by ShieldSeconds and ShieldCooldown so it is a tactic, not god mode.
S.shields, S.shieldCd = {}, {}
local function releaseShield(p, why)
  local key = p:GetFullName(); local sh = S.shields[key]; if not sh then return end
  S.shields[key] = nil; S.shieldCd[key] = os.time() + cfg.ShieldCooldown
  setTeam(p, sh.team)
  if valid(sh.civ) then
    pcall(function() sh.civ:K2_DetachFromActor(1, 1, 1) end)
    pcall(function() sh.civ:StopAnimMontage(nil) end)
    pcall(function() sh.civ.CapsuleComponent:SetCollisionEnabled(3) end)
    pcall(function() sh.civ.CharacterMovement:SetMovementMode(1, 0) end)
  end
  chat(pname(p).." "..why.." the hostage. SWAT can shoot again.")
end
CMD.hostage = function(p)
  local key = p:GetFullName()
  if S.shields[key] then return releaseShield(p, "let go of") end
  if S.phase ~= "live" and S.phase ~= "prep" then return end
  if S.shieldCd[key] and os.time() < S.shieldCd[key] then return chat(("Hostage cooldown: %ds"):format(S.shieldCd[key]-os.time())) end
  -- Candidates within 3 m, nearest first. Scripted civilians (seated etc.) can't be moved, so each grab is
  -- checked and undone if the person didn't actually end up in front of you.
  local l = p:K2_GetActorLocation(); local cands = {}
  for _,c in ipairs(list("CivilianCharacter")) do if valid(c) and not c:IsHealthDepleted() and not (valid(S.vip) and S.vip:GetFullName() == c:GetFullName()) then
    local busy = false for _,sh in pairs(S.shields) do if valid(sh.civ) and sh.civ:GetFullName() == c:GetFullName() then busy = true end end
    local cl = c:K2_GetActorLocation(); local d = math.sqrt((cl.X-l.X)^2 + (cl.Y-l.Y)^2 + (cl.Z-l.Z)^2)
    if not busy and d < 300 then cands[#cands+1] = {c=c, d=d} end end end
  table.sort(cands, function(a,b) return a.d < b.d end)
  local best = nil
  for _,cd in ipairs(cands) do local c = cd.c
    -- Held = attached to the captor 60 cm ahead, a little left so you can aim past their shoulder. Attachment
    -- replicates, so every machine sees them glued in front.
    pcall(function() c:K2_DetachFromActor(1, 1, 1) end)
    pcall(function() c.CharacterMovement:SetMovementMode(1, 0) end)   -- break any scripted pose first
    pcall(function() c.CharacterMovement:DisableMovement() end)
    pcall(function() c.CapsuleComponent:SetCollisionEnabled(0) end)   -- no capsule shove; the mesh still stops bullets
    pcall(function() c:K2_AttachToActor(p, FName("None"), 2, 2, 1, false) end)
    pcall(function() c.RootComponent:K2_SetRelativeLocationAndRotation({X=cfg.ShieldDistance or 60, Y=-22, Z=0}, {Pitch=0, Yaw=0, Roll=0}, false, {}, true) end)
    local cl = c:K2_GetActorLocation()
    if (cl.X-l.X)^2 + (cl.Y-l.Y)^2 < 120*120 then best = c break end
    pcall(function() c:K2_DetachFromActor(1, 1, 1) end)   -- didn't move: undo, try the next one
    pcall(function() c.CapsuleComponent:SetCollisionEnabled(3) end)
    pcall(function() c.CharacterMovement:SetMovementMode(1, 0) end)
    log("civilian "..c:GetFName():ToString().." couldn't be grabbed (scripted), trying next")
  end
  if not best then return false end
  S.shields[key] = {civ=best, t0=os.time(), team=p:GetTeam()}
  setTeam(p, TT_SUSPECT)
  chat(("%s took a human shield! SWAT hold fire for %ds. Switch weapon to let go."):format(pname(p), cfg.ShieldSeconds))
  return true
end
local function tickShields()  -- hold timer, captor/hostage death
  for key, sh in pairs(S.shields) do
    local p; for _,c in ipairs(playerChars()) do if c:GetFullName() == key then p = c end end
    if not valid(p) or p:IsHealthDepleted() then S.shields[key] = nil
      if valid(sh.civ) then pcall(function() sh.civ:K2_DetachFromActor(1, 1, 1) end) pcall(function() sh.civ.CapsuleComponent:SetCollisionEnabled(3) end) pcall(function() sh.civ.CharacterMovement:SetMovementMode(1, 0) end) end
    elseif not valid(sh.civ) or sh.civ:IsHealthDepleted() then releaseShield(p, "lost")
    elseif os.time() - sh.t0 >= cfg.ShieldSeconds then releaseShield(p, "can't hold on to")
    end
  end
end

-- The riot shield IS the grab: equip the ballistic shield within 3 m of a civilian and they become your
-- shield instead (upright, hands up, in front of you). Switch to any other item to let go. Host-side.
local function hasShield(p)  -- equipped item is the ballistic shield (BP_BallisticShield_C)
  local ok, r = pcall(function() local it = p.InventoryComp:GetEquippedItem() return valid(it) and it:GetClass():GetFName():ToString():find("Shield") ~= nil end)
  return ok and r
end
S.shieldWas = {}
local function shieldTrigger()
  for _,p in ipairs(playerChars()) do if not p:IsHealthDepleted() then
    local key = p:GetFullName(); local on = hasShield(p)
    if on and not S.shieldWas[key] and not S.shields[key] then
      if not (S.shieldCd[key] and os.time() < S.shieldCd[key]) then CMD.hostage(p) end
    elseif not on and S.shields[key] then releaseShield(p, "let go of") end
    S.shieldWas[key] = on and true or false
  end end
end

-- Visuals on every machine: a player holding the shield with a civilian pinned in front hides the shield
-- (3rd-person component and the held item) and the civilian plays the game's own hostage idle (standing, held).
local HOSTAGE_IDLE = "/Game/ReadyOrNot/Animations/TP/interaction/hostage/new/montages/tp_hostage_idle_01_slave_Montage.tp_hostage_idle_01_slave_Montage"
local function shieldVisuals()
  local civs = nil
  for _,p in ipairs(list("PlayerCharacter")) do if valid(p) and not p:GetClass():GetFName():ToString():find("Custom") and hasShield(p) then
    civs = civs or list("CivilianCharacter")
    local l = p:K2_GetActorLocation(); local held = nil
    for _,c in ipairs(civs) do if valid(c) and not c:IsHealthDepleted() then
      local cl = c:K2_GetActorLocation(); if (cl.X-l.X)^2 + (cl.Y-l.Y)^2 < 110*110 then held = c end end end
    if held then
      pcall(function() local item = p.InventoryComp:GetEquippedItem() if valid(item) then item:SetActorHiddenInGame(true) end end)
      for _,comp in ipairs(list("SkeletalMeshComponent")) do
        local ok, own = pcall(function() return comp:GetOwner():GetFullName() end)
        if ok and own == p:GetFullName() then local n = comp:GetFName():ToString()
          if (n == "LongTacticalVisualizationComponent" or n == "EquippedVisualizationComponent") and comp:IsVisible() then
            local mn = ""; pcall(function() mn = comp.SkeletalMesh:GetFName():ToString() end)
            if mn:find("Shield") then pcall(function() comp:SetVisibility(false, false) end) end end end
      end
      local m = asset(HOSTAGE_IDLE, true)
      if m then pcall(function()
        local ai = held.Mesh:GetAnimInstance()
        if not ai:Montage_IsPlaying(m) then held:PlayAnimMontage(m, 1.0, FName("None")) end end) end
    end
  end end
end

-- No reporting part 2: the map's SWAT objectives ("report the manager", "bring order to chaos", ...) are hidden
-- and can't end the mission. Every machine, so the HUD list is empty for clients too.
local function hideObjectives()
  local gs = FindFirstOf("ReadyOrNotGameState"); if not valid(gs) then return end
  pcall(function()
    local mo = gs.MissionObjectives
    for i = 1, #mo do local o = mo[i]
      if valid(o) and not o.bHiddenObjective then o.bHiddenObjective = true; o.bFailureEndsMission = false end end
  end)
end

-- Helpers wear a suspect look like the players; all SWAT gear parts except weapons are hidden.
local function dressHelpers()
  if not S.helpers or #S.looks == 0 then return end
  local comps = nil
  for i,c in ipairs(S.helpers) do if valid(c) and not c:IsHealthDepleted() then
    local look = S.looks[(i * 3) % #S.looks + 1]
    if (pathOf(c.Mesh.SkeletalMesh) or "") ~= look.body then
      local b, h = asset(look.body, true), asset(look.head, true)
      if b then pcall(function() c.Mesh:SetSkeletalMeshAsset(b) end) applyMats(c.Mesh, look.bm) end
      if h then pcall(function() c.FaceMesh:SetSkeletalMeshAsset(h) end) applyMats(c.FaceMesh, look.hm) end
      if S.susVoice then pcall(function() c.SpeechCharacterName = S.susVoice end) end
    end
    comps = comps or list("SkeletalMeshComponent")
    local me = c:GetFullName()
    for _,comp in ipairs(comps) do
      local ok, own = pcall(function() return comp:GetOwner():GetFullName() end)
      if ok and own == me then local n = comp:GetFName():ToString()
        local keep = n == "CharacterMesh0" or n == "FaceMesh" or n:find("Primary") or n:find("Secondary") or n:find("Equipped") or n:find("Item")
        if not keep and comp:IsVisible() then pcall(function() comp:SetVisibility(false, false) end) end end
    end
  end end
end
local function placeHelpers()
  local pl = playerChars()[1]; if not (S.helpers and valid(pl)) then return end
  for i,c in ipairs(S.helpers) do if valid(c) then local l = pl:K2_GetActorLocation(); local a = i * 2.4
    pcall(function() c:K2_SetActorLocation({X=l.X+math.cos(a)*250, Y=l.Y+math.sin(a)*250, Z=l.Z}, false, {}, true) end) end end
end

-- VIP: at the breach one civilian becomes the person you must protect. Moved onto the SWAT team so the
-- SWAT (suspect AI underneath) hunt them too; the suspects lose if the VIP dies.
local function pickVIP()
  if not cfg.ProtectVIP then return end
  local pl = playerChars()[1]; if not valid(pl) then return end
  local l = pl:K2_GetActorLocation(); local best, bd = nil, 1e12
  for _,c in ipairs(list("CivilianCharacter")) do if valid(c) and not c:IsHealthDepleted() then
    local cl = c:K2_GetActorLocation(); local d = (cl.X-l.X)^2 + (cl.Y-l.Y)^2 + (cl.Z-l.Z)^2
    if d < bd then best, bd = c, d end end end
  if not best then return end
  S.vip = best; setTeam(best, 2)
  chat(("PROTECT THE VIP: a civilian %dm from you is the target. If they die, you lose."):format(math.floor(math.sqrt(bd)/100)))
end
local function vipIntel()
  if not (valid(S.vip) and not S.vip:IsHealthDepleted()) then return end
  local i = 0
  for _,c in ipairs(enemies()) do if not c:IsHealthDepleted() then i = i + 1
    if i % 2 == 0 then pcall(function() c.Controller.TargetingComponent:AddKnownEnemy(S.vip, true) end) end end end
end

-- ===== SETTINGS MENU (chat) ================================================================================
local SETTINGS_FILE = dir.."settings.txt"
local MENU_KEYS = {"Preset","WinMode","SwatBase","SwatPerPlayer","EnemyAccuracy","SuspectHealthMult","PrepSeconds",
  "SurviveSeconds","KillTarget","ReinforceEvery","ReinforceSize","ReinforceWaves","BreachGrace","ProtectVIP",
  "ShieldSeconds","ShieldCooldown","StunResist","SwatVoices","DressPlayersAsSuspects","DressEnemiesAsSwat","NoReporting"}
local function parseVal(v)
  if v == "true" or v == "on" then return true elseif v == "false" or v == "off" then return false end
  return tonumber(v) or v
end
local function saveSettings()
  local f = io.open(SETTINGS_FILE, "w"); if not f then return end
  for _,k in ipairs(MENU_KEYS) do f:write(k.."="..tostring(cfg[k]).."\n") end f:close()
end
local function applyPreset(name)
  local pr = PRESETS[name]; cfg.Preset = name
  if pr then for k,v in pairs(pr) do cfg[k] = v end end
end
do local f = io.open(SETTINGS_FILE, "r")  -- saved menu choices win over config.lua and the preset
  if f then for line in f:lines() do local k, v = line:match("^(%w+)=(.*)$")
      if k == "Preset" then applyPreset(v) elseif k then cfg[k] = parseVal(v) end end f:close() end end
local function showMenu()
  local parts = {}
  for _,k in ipairs(MENU_KEYS) do parts[#parts+1] = k.."="..tostring(cfg[k]) end
  chat("SETTINGS (type in chat):  !set <name> <value>   !preset standard|easy|hardcore|survival|custom   !menu")
  for i = 1, #parts, 5 do chat(table.concat(parts, "  ", i, math.min(i+4, #parts))) end
end
S.chatIdx = 0
local function hostReadSettings()
  local gs = FindFirstOf("ReadyOrNotGameState"); if not valid(gs) then return end
  if S.menuGS ~= gs:GetFullName() then S.menuGS = gs:GetFullName(); S.chatIdx = #gs.SavedChatMessages end  -- new map: skip old lines
  local arr = gs.SavedChatMessages
  if #arr < S.chatIdx then S.chatIdx = 0 end
  for i = S.chatIdx + 1, #arr do
    local msg = arr[i].Message:ToString(); local who = arr[i].SenderName:ToString()
    if who ~= "SUSPECT MODE" and who ~= "LOOK" then
      local k, v = msg:match("^!set%s+(%w+)%s+(%S+)")
      local pr = msg:match("^!preset%s+(%w+)")
      if k then
        local real = nil for _,mk in ipairs(MENU_KEYS) do if mk:lower() == k:lower() then real = mk end end
        if real == "Preset" then pr = v elseif real then cfg[real] = parseVal(v); saveSettings(); chat(who.." set "..real.." = "..tostring(cfg[real]).." (saved)")
        else chat("Unknown setting '"..k.."'. Type !menu for the list.") end
      end
      if pr then if PRESETS[pr] or pr == "custom" then applyPreset(pr); saveSettings(); chat(who.." picked preset "..pr.." (saved)") else chat("Presets: standard, easy, hardcore, survival, custom") end end
      if msg:match("^!menu") then showMenu() end
    end
  end
  S.chatIdx = #arr
end

local function win(reason)
  S.done = true; S.phase = "won"
  chat("SUSPECTS WIN - "..reason.."  (remaining SWAT stand down)")
  for _,c in ipairs(enemies()) do if not c:IsHealthDepleted() then pcall(function() c:Kill() end) end end
end

local function lose(reason)
  S.done = true; S.phase = "lost"
  chat("SWAT WINS - "..(reason or "all suspects are down")..". SWAT left: "..swatAlive())
end

local function tick()
  if not cfg.Enabled or not isHost() then return end
  local map = inMission()
  if not map then S.map=nil S.phase="idle" return end
  if map ~= S.map then -- new mission
    S.map=map S.phase="prep" S.done=false S.limbs={} S.anchor=nil S.waves=0 S.moved={} S.squadGone=false S.helpers=nil S.vip=nil S.shields={} S.shieldCd={} S.graceEnd=nil S.dressed={} S.t0=os.time() S.prepEnd=S.t0+cfg.PrepSeconds S.lastAnn=0
    chat(("You are the SUSPECTS. %ds to set up - SWAT AI hunts you after that. Goal: %s"):format(cfg.PrepSeconds,
      cfg.WinMode=="kills" and ("kill "..cfg.KillTarget.." SWAT") or cfg.WinMode=="eliminate" and "eliminate the whole SWAT team" or ("survive "..fmt(cfg.SurviveSeconds))))
  end
  local now = os.time()
  if S.phase=="prep" and now >= S.prepEnd then S.phase="live" S.liveStart=now S.lastAnn=now S.lastWave=now S.lastIntel=now S.graceEnd=now+cfg.BreachGrace
    local need = swatTarget() - swatAlive()
    if hunters() then spawnHunters(need) else spawnSwat(need) end  -- top the map's squad up to SwatBase + SwatPerPlayer * players
    if cfg.SwatIntelEvery > 0 then swatIntel() end
    chat("SWAT IS BREACHING! "..swatAlive().." operators inbound.")
    placeHelpers(); pickVIP(); vipIntel() end
  if S.done then return end
  if S.phase=="prep" and cfg.SpawnAway then moveAway() end
  if hunters() then dropSquad() end
  makeSuspects(S.phase=="prep")
  if S.phase=="live" then
    if playersAlive() == 0 then return lose() end
    if S.vip and (not valid(S.vip) or S.vip:IsHealthDepleted()) then return lose("the VIP was killed") end
    if cfg.SwatIntelEvery > 0 and now - S.lastIntel >= cfg.SwatIntelEvery then S.lastIntel = now; swatIntel(); vipIntel() end
    if cfg.WinMode=="kills" and swatDead() >= cfg.KillTarget then return win(swatDead().." SWAT down") end
    if cfg.WinMode=="timer" and now - S.liveStart >= cfg.SurviveSeconds then return win("you held out "..fmt(cfg.SurviveSeconds)) end
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
      chat(cfg.WinMode=="kills" and ("SWAT down: "..swatDead().."/"..cfg.KillTarget) or cfg.WinMode=="eliminate" and ("SWAT left: "..swatAlive()) or ("Hold out: "..fmt(cfg.SurviveSeconds-(now-S.liveStart)).." left, SWAT alive "..swatAlive())) end
  elseif S.phase=="prep" and now - S.lastAnn >= 15 then S.lastAnn=now chat("Setup time: "..fmt(S.prepEnd-now)) end
end

LoopAsync(500, function() ExecuteInGameThread(function()
  local ok,e=pcall(tick) if not ok then log("tick error: "..tostring(e)) end
  ok,e=pcall(dressHunters) if not ok then log("dress error: "..tostring(e)) end  -- every machine, not just the host
  if cfg.NoReporting ~= false and isHost() then ok,e=pcall(noReports) if not ok then log("noReports error: "..tostring(e)) end end
  pcall(readChatLooks)
  if my.body and (not S.lastLookSent or os.time() - S.lastLookSent > 60) and inMission() then sendLook() end  -- late joiners
  if isHost() then pcall(hostReadSettings) end
  if isHost() then pcall(hostReadCmds) pcall(dressHelpers) if inMission() then pcall(shieldTrigger) end end
  if cfg.NoReporting ~= false then pcall(hideObjectives) end
  pcall(shieldVisuals)
  if S.tick2 then ok,e=pcall(dressPlayers) if not ok then log("dressP error: "..tostring(e)) end end
  S.tick2 = not S.tick2
end) return false end)

local function key(name) return Key[name] or Key.F7 end
RegisterKeyBind(key(cfg.ToggleKey), function() ExecuteInGameThread(function()
  cfg.Enabled = not cfg.Enabled; if not cfg.Enabled then for _,c in ipairs(list("PlayerCharacter")) do pcall(function() c.bGodMode=false end) end end
  S.map=nil; chat("Suspect Mode "..(cfg.Enabled and "ON (restarts setup timer)" or "OFF")) end) end)
RegisterKeyBind(key(cfg.StatusKey), function() ExecuteInGameThread(function()
  if isHost() then
    chat(("phase=%s  SWAT alive=%d down=%d  mode=%s"):format(S.phase, swatAlive(), swatDead(), cfg.WinMode)); showMenu()
  else local pc = localPC() if pc then pcall(function() pc:Server_SendChatMessage({SenderName=localName(), SenderPlayerState=pc.PlayerState, Message="!menu"}) end) end end
end) end)
log("v0.8 loaded")
RegisterKeyBind(Key.F9, function() ExecuteInGameThread(function() cycle("body", 1) end) end)
RegisterKeyBind(Key.F9, {ModifierKey.SHIFT}, function() ExecuteInGameThread(function() cycle("body", -1) end) end)
RegisterKeyBind(Key.F10, function() ExecuteInGameThread(function() cycle("head", 1) end) end)
RegisterKeyBind(Key.F10, {ModifierKey.SHIFT}, function() ExecuteInGameThread(function() cycle("head", -1) end) end)
RegisterKeyBind(Key.F11, function() ExecuteInGameThread(cycleExtras) end)
LoopAsync(250, function() if next(S.shields) then ExecuteInGameThread(function() local ok, e = pcall(tickShields) if not ok and not S.tsErr then S.tsErr = true log("tickShields error: "..tostring(e)) end end) end return false end)
