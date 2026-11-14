# Suspection — Suspect Mode for Ready or Not

**Hold the building while the AI comes for you, in Ready or Not.** You get a setup phase, then armed enemies are sent in waves until you survive the timer, kill enough of them, or go down.
It's a UE4SS Lua mod and the host runs the logic. Everyone installs the same zip.

> Status: **v0.6 is released**: human shield (F6), AI suspect helpers, protect-the-VIP. Before that, v0.5: suspect look editor (F9/F10/F11), no reporting, plus everything from v0.4 (presets, eliminate mode, SWAT voices, aim slider, players dressed as suspects).
> Tested solo on one map only. Co-op is untested. See [docs/HANDOFF.md](docs/HANDOFF.md) for exactly what is verified.
> Built with AI (Claude Code). If you are taking over, human or agent, start at [docs/HANDOFF.md](docs/HANDOFF.md). The wish-list is in [docs/ROADMAP.md](docs/ROADMAP.md).

## What it does on `main`
| Feature | Details |
|---|---|
| Enemies that shoot | `EnemyMode = "hunters"` (default): hostile AI from the map's own spawners is dropped 25-45 m from a player and attacks. Your AI squad is removed. |
| Enemies look like SWAT | `DressEnemiesAsSwat`: every hostile AI wears a SWAT uniform and a masked SWAT head, on every player's screen. Under the hood they are the game's suspect AI, the only AI that shoots players. |
| Main mode + presets | `Preset = "standard"`: one SWAT team (6 + 2 per player) breaches, eliminate them all. Also `easy`, `hardcore`, `survival` (timer + waves) and `custom` (config.lua as written). |
| SWAT voices and aim | `SwatVoices`: enemies use the SWAT squad's voice lines. `EnemyAccuracy` (0..1, standard 0.55) nerfs their aim. |
| You look like a suspect | `DressPlayersAsSuspects`: your SWAT outfit parts and helmet are hidden and you wear a real suspect body and head, captured from the map's suspects and saved in `looks.txt`. Armour stays on top (`DressKeepArmor`). `SuspectLook = n` picks a fixed look. |
| Look editor | **F9** / Shift+F9: next/previous suspect body. **F10** / Shift+F10: head. **F11**: extras (none, armour, helmet, both). Saved in `mylook.txt`, and sent to the other players through a `#look` chat line so they see you the same way. Looks come from suspects you have met (`looks.txt`). |
| No reporting | `NoReporting`: suspects don't call TOC. No "Report" prompt on bodies, arrests or props. |
| Human shield | **F6** near a civilian (3 m): grab them. SWAT hold fire while you hold them, for `ShieldSeconds` (20), then a `ShieldCooldown` (30). Works for clients too (sent to the host as a `#cmd` chat line). |
| AI helpers | `Helpers` (standard 2): squad members kept as suspects in suspect clothes. They follow you and fight the SWAT. |
| Protect the VIP | `ProtectVIP`: at the breach a civilian near you becomes the VIP. SWAT hunt them too, and you lose if they die. |
| Breach grace | `BreachGrace` (default 10 s): enemies stay blind for a moment after the breach. |
| Moved start | `SpawnAway`: you are moved away from the entry point when the mission starts. |
| Setup phase | `PrepSeconds` (default 60): you can't be hurt and the enemies are blind. |
| Waves | Enemies are topped up to `SwatBase + SwatPerPlayer * players` at the breach. Then `ReinforceWaves` waves of `ReinforceSize` arrive every `ReinforceEvery` seconds. |
| Win and lose | `timer`: survive `SurviveSeconds`. `kills`: kill `KillTarget` enemies. Wiping them all out also wins. You lose when every player is down. |
| Tougher players | Damage you take is divided by `SuspectHealthMult` (default 2.5). Stuns are cut short after `StunMaxSeconds`. |
| Chat HUD | Countdown and status in the in-game chat. The host presses **F7** to toggle the mode and **F8** for status. |
| Old team swap | `EnemyMode = "swat"` puts players on the suspect team, as in v0.1. The SWAT AI does not shoot players, so this mode has no real enemy. |

It needs a mission that has AI spawners (any normal mission). All settings are in `config.lua`, each with a comment.

## Install (every player)
1. Download the latest `SuspectMode_*.zip` from [Releases](../../releases) and unzip it. To try unreleased `main`, build the zip with `tools/build_dist.sh`.
2. Double-click `install.bat`. It finds the game folder or asks for it, then copies UE4SS and the mod into `ReadyOrNot\Binaries\Win64`.
3. Host co-op as usual. The **host's** `ue4ss\Mods\RonSuspect\Scripts\config.lua` is the one that counts.

`uninstall.bat` removes `dwmapi.dll` and the `ue4ss` folder.

Requirements: Ready or Not on Steam.

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
