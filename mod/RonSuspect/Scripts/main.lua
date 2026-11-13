-- SUSPECT MODE v0.1 for Ready or Not (UE4SS Lua). Host-authoritative: the host's game swaps every
-- player to TT_SUSPECT, so AI suspects become your allies and the SWAT AI squad hunts you.
local dir = debug.getinfo(1,"S").source:gsub("^@",""):gsub("main%.lua$","")
local okc, cfg = pcall(dofile, dir.."config.lua"); if not okc or type(cfg)~="table" then cfg = {Enabled=true,PrepSeconds=60,WinMode="timer",SurviveSeconds=600,KillTarget=4,SuspectHealthMult=2.5,StunResist=true,StunMaxSeconds=0.75,AnnounceEvery=60,ToggleKey="F7",StatusKey="F8"} end
local TT_SUSPECT = 3
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

local function isHost() return valid(FindFirstOf("ReadyOrNotGameMode")) end
local function inMission()
  local w = FindFirstOf("World"); if not valid(w) then return nil end
  local n = w:GetFullName(); if n:find("/Menu/") or n:find("PreMission") then return nil end
  if #list("PlayerCharacter") == 0 then return nil end
  return n
end

local function swatChars() local r={} for _,c in ipairs(list("SWATCharacter")) do if valid(c) then r[#r+1]=c end end return r end
local function swatAlive() local n=0 for _,c in ipairs(swatChars()) do if not c:IsHealthDepleted() then n=n+1 end end return n end
local function swatDead() local n=0 for _,c in ipairs(swatChars()) do if c:IsHealthDepleted() then n=n+1 end end return n end

local function makeSuspects(prep)
  for _,ps in ipairs(list("ReadyOrNotPlayerState")) do if valid(ps) and ps.Team ~= TT_SUSPECT then ps.Team = TT_SUSPECT end end
  for _,c in ipairs(list("PlayerCharacter")) do if valid(c) then
    if c:GetTeam() ~= TT_SUSPECT then pcall(function() c.DefaultTeam = TT_SUSPECT c:HandleTeamChanged(TT_SUSPECT) end) end
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
  for _,ctl in ipairs(list("SWATController")) do if valid(ctl) then ctl.bDisableSensePerception = prep and true or false end end
end

local function fmt(s) s=math.max(0,math.floor(s)) return string.format("%d:%02d", s//60, s%60) end

local function win(reason)
  S.done = true; S.phase = "won"
  chat("SUSPECTS WIN - "..reason.."  (remaining SWAT stand down)")
  for _,c in ipairs(swatChars()) do if not c:IsHealthDepleted() then pcall(function() c:Kill() end) end end
end

local function tick()
  if not cfg.Enabled or not isHost() then return end
  local map = inMission()
  if not map then S.map=nil S.phase="idle" return end
  if map ~= S.map then -- new mission
    S.map=map S.phase="prep" S.done=false S.limbs={} S.t0=os.time() S.prepEnd=S.t0+cfg.PrepSeconds S.lastAnn=0
    chat(("You are the SUSPECTS. %ds to set up - SWAT AI hunts you after that. Goal: %s"):format(cfg.PrepSeconds,
      cfg.WinMode=="kills" and ("kill "..cfg.KillTarget.." SWAT") or ("survive "..fmt(cfg.SurviveSeconds))))
  end
  local now = os.time()
  if S.phase=="prep" and now >= S.prepEnd then S.phase="live" S.liveStart=now S.lastAnn=now chat("SWAT IS BREACHING! "..swatAlive().." operators inbound.") end
  if S.done then return end
  makeSuspects(S.phase=="prep")
  if S.phase=="live" then
    if cfg.WinMode=="kills" and swatDead() >= cfg.KillTarget then return win(swatDead().." SWAT down") end
    if cfg.WinMode~="kills" and now - S.liveStart >= cfg.SurviveSeconds then return win("you held out "..fmt(cfg.SurviveSeconds)) end
    if #list("SWATCharacter")>0 and swatAlive()==0 then return win("entire SWAT element neutralised") end
    if now - S.lastAnn >= cfg.AnnounceEvery then S.lastAnn=now
      chat(cfg.WinMode=="kills" and ("SWAT down: "..swatDead().."/"..cfg.KillTarget) or ("Hold out: "..fmt(cfg.SurviveSeconds-(now-S.liveStart)).." left, SWAT alive "..swatAlive())) end
  elseif S.phase=="prep" and now - S.lastAnn >= 15 then S.lastAnn=now chat("Setup time: "..fmt(S.prepEnd-now)) end
end

LoopAsync(500, function() ExecuteInGameThread(function() local ok,e=pcall(tick) if not ok then log("tick error: "..tostring(e)) end end) return false end)

local function key(name) return Key[name] or Key.F7 end
RegisterKeyBind(key(cfg.ToggleKey), function() ExecuteInGameThread(function()
  cfg.Enabled = not cfg.Enabled; if not cfg.Enabled then for _,c in ipairs(list("PlayerCharacter")) do pcall(function() c.bGodMode=false end) end end
  S.map=nil; chat("Suspect Mode "..(cfg.Enabled and "ON (restarts setup timer)" or "OFF")) end) end)
RegisterKeyBind(key(cfg.StatusKey), function() ExecuteInGameThread(function()
  chat(("phase=%s  SWAT alive=%d dead=%d  mode=%s"):format(S.phase, swatAlive(), swatDead(), cfg.WinMode)) end) end)
log("v0.1 loaded")
