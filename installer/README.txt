SUSPECT MODE v0.1 for Ready or Not  (UE4SS Lua mod, built with AI - Claude Code)

YOU are the suspects. Every player is moved to the suspect team: AI suspects are your allies,
and the SWAT AI squad hunts you.
  1. Setup phase (PrepSeconds, default 60s): you can't be hurt and SWAT AI is blind. Set up.
  2. SWAT breaches. Win by surviving the timer (WinMode="timer") or killing N SWAT ("kills").
  3. Suspects take 1/2.5 damage (SuspectHealthMult) and flash/sting/gas stuns are cut to 0.75s.
Host: F7 toggles the mode (restarts setup), F8 posts status in chat.

INSTALL (both players): double-click install.bat, then play co-op through Steam as normal.
The HOST's config.lua is the one that counts. Both players should use the same version.
Needs SWAT AI in the mission (singleplayer squad / co-op with AI squad).
UE4SS (MIT licence, github.com/UE4SS-RE/RE-UE4SS) is bundled as the loader.
