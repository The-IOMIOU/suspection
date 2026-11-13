-- SUSPECT MODE settings (host's file is the one that counts). Edit, then restart the game.
return {
  Enabled          = true,
  SpawnAway        = true,   -- move players away from the SWAT entry point when the mission starts
  PrepSeconds      = 60,     -- trap/setup time at mission start: you can't be hurt, SWAT AI is blind
  WinMode          = "timer",-- "timer" = survive SurviveSeconds, "kills" = kill KillTarget SWAT
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
