-- SUSPECT MODE settings (host's file is the one that counts). Edit, then restart the game.
return {
  Enabled          = true,
  Preset           = "standard", -- "standard" (one SWAT team breaches: eliminate them all), "easy", "hardcore",
                                 -- "survival" (hold out a timer vs waves) or "custom" (use every value below as written).
                                 -- A preset overrides the values below that it sets.
  EnemyAccuracy    = 0.55,   -- SWAT aim, 0..1 (1 = the game default suspect aim)
  SwatVoices       = true,   -- enemies use SWAT voice lines instead of suspect ones
  DressPlayersAsSuspects = true, -- players (and the lobby mannequins) look like suspects to everyone
  DressKeepArmor   = true,   -- keep your chosen body armour visible on top of the suspect outfit
  SuspectLook      = 0,      -- 0 = a look picked from your name; 1..n = a fixed look from looks.txt (filled as you play)
  NoReporting      = true,   -- suspects never report to TOC: no "Report" prompt on bodies, props or arrests
  Helpers          = 2,      -- AI suspects on your side (kept from the squad, dressed as suspects; they fight SWAT and follow you)
  ProtectVIP       = true,   -- at the breach one civilian becomes the VIP: SWAT hunt them too, you lose if they die
  ShieldSeconds    = 20,     -- equip your ballistic shield next to a civilian (3 m): they become your shield instead; SWAT hold fire this long at most
  ShieldCooldown   = 30,     -- seconds before you can grab another hostage
  EnemyMode        = "hunters",-- "hunters": hostile AI from the map's own spawners hunts you (it really shoots), AI squad removed
                             -- "swat": old team swap; the SWAT AI stands around and never shoots players
  HunterDropMin    = 2500,   -- hunters are dropped this far from a player at least (cm; 2500 = 25 m) ...
  HunterDropMax    = 4500,   -- ... and this far at most; hunters further than 1.5x this are brought back every SwatIntelEvery
  DressEnemiesAsSwat = true,  -- hostile AI wears SWAT uniforms + masked SWAT heads (every player should keep this on)
  BreachGrace      = 10,     -- seconds the SWAT stay blind after the breach so nobody dies before they can react
  SpawnAway        = true,   -- move players away from the SWAT entry point when the mission starts
  PrepSeconds      = 60,     -- trap/setup time at mission start: you can't be hurt, SWAT AI is blind
  WinMode          = "eliminate",-- "eliminate" = kill the whole SWAT team, "timer" = survive SurviveSeconds, "kills" = kill KillTarget
  SurviveSeconds   = 600,
  KillTarget       = 4,
  SuspectHealthMult= 2.5,    -- players take 1/2.5 damage (2v10, so you get more health)
  SwatBase         = 6,      -- SWAT at the breach = SwatBase + SwatPerPlayer * players (the map's own squad counts)
  SwatPerPlayer    = 2,      --   e.g. 2 players -> 10 SWAT. Set both to 0 to keep only the map's squad
  SwatMax          = 24,     -- never more than this many SWAT alive at once
  ReinforceEvery   = 120,    -- seconds between reinforcement waves (0 = off); a wiped squad is replaced at once
  ReinforceSize    = 2,      -- SWAT per wave
  ReinforceWaves   = 3,      -- waves per mission; wiping SWAT only wins once these are used up
  SwatIntelEvery   = 20,     -- every N seconds all SWAT learn where the players are and hunt them (0 = off: they must spot you)
  StunResist       = true,   -- flashbangs/stingers/gas/sound hit you way less (stuns cut short)
  StunMaxSeconds   = 0.75,
  AnnounceEvery    = 60,     -- chat status every N seconds
  ToggleKey        = "F7",   -- host: turn Suspect Mode on/off mid-mission
  StatusKey        = "F8",
}
