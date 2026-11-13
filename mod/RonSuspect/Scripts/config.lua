-- SUSPECT MODE settings (host's file is the one that counts). Edit, then restart the game.
return {
  Enabled          = true,
  PrepSeconds      = 60,     -- trap/setup time at mission start: you can't be hurt, SWAT AI is blind
  WinMode          = "timer",-- "timer" = survive SurviveSeconds, "kills" = kill KillTarget SWAT
  SurviveSeconds   = 600,
  KillTarget       = 4,
  SuspectHealthMult= 2.5,    -- players take 1/2.5 damage (2v10, so you get more health)
  StunResist       = true,   -- flashbangs/stingers/gas/sound hit you way less (stuns cut short)
  StunMaxSeconds   = 0.75,
  AnnounceEvery    = 60,     -- chat status every N seconds
  ToggleKey        = "F7",   -- host: turn Suspect Mode on/off mid-mission
  StatusKey        = "F8",
}
