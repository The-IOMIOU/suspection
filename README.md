# Suspection — Suspect Mode for Ready or Not

**Flip Ready or Not around: you and your friends are the suspects, and the SWAT AI breaches the building to get you.**
It's a UE4SS Lua mod and it works in Steam co-op: the host runs the logic, and everyone installs the same zip.

> Status: **v0.1 (lite)**, verified in game on 2026-11-13. A big roadmap is in [docs/ROADMAP.md](docs/ROADMAP.md).
> Built with AI (Claude Code). If you're an AI agent taking over, start at [docs/HANDOFF.md](docs/HANDOFF.md).

## What v0.1 does
| Feature | Details |
|---|---|
| Role swap | Every player goes onto the game's own `TT_SUSPECT` team. AI suspects become allies and the SWAT AI targets you natively. |
| Setup phase | `PrepSeconds` (default 60): you can't be hurt and the SWAT AI is blind (`bDisableSensePerception`). Use it to set up. |
| Win modes | `timer`: survive `SurviveSeconds`. `kills`: kill `KillTarget` SWAT. Wiping out every SWAT also wins. |
| Tougher suspects | Damage you take is divided by `SuspectHealthMult` (default 2.5), using per-limb `LimbDamageMultiplier`. |
| Stun resistance | Flashbang, stinger and gas stuns get cut short after `StunMaxSeconds`. |
| Chat HUD | Countdown and status in the in-game chat. The host presses **F7** to toggle the mode and **F8** for status. |

## Install (every player)
1. Download `SuspectMode_v0.1.zip` from [Releases](../../releases) and unzip it.
2. Double-click `install.bat`. It finds the game folder or asks for it, then copies UE4SS and the mod into `ReadyOrNot\Binaries\Win64`.
3. Host co-op as usual. The **host's** `ue4ss\Mods\RonSuspect\Scripts\config.lua` is the one that counts.

`uninstall.bat` removes `dwmapi.dll` and the `ue4ss` folder.

Requirements: Ready or Not on Steam. The mission needs SWAT AI (the singleplayer squad, or co-op with the AI squad). Spawning extra SWAT is the next milestone.

## Repo layout
```
mod/RonSuspect/Scripts/   main.lua (the mode), config.lua (settings)   <- the shipped mod
installer/                install.bat, uninstall.bat, README.txt        <- go into the release zip
tools/build_dist.sh       downloads UE4SS, builds dist/SuspectMode_<ver>.zip
dev/RonBridge/            dev-only Lua REPL mod (never ship it)
dev/q.sh                  sends Lua to the running game through RonBridge
dev/winshot.ps1           screenshots the game window (PrintWindow, works on D3D12)
dev/recon/                scripts used to reverse the game (class dump, signatures, map list, team swap tests)
docs/                     HANDOFF.md, ENGINE_NOTES.md, ROADMAP.md
```

## Credits
- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) (MIT) is the loader, bundled in the release zip.
- Ready or Not belongs to VOID Interactive. This repo contains no game files, extracted assets or decompiled code.
- Built with Claude Code.
