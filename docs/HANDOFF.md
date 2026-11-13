# HANDOFF: read this first (for the next Claude / agent)

## TL;DR
- **Goal:** a full "Suspect Mode" for Ready or Not, as big as the normal SWAT mode. Players are suspects, the AI is SWAT, and it works in Steam co-op. See [ROADMAP.md](ROADMAP.md) for the whole wish-list (the user wants *everything*, built incrementally).
- **Done:** v0.1 lite, verified in game (team swap, setup timer, win modes, damage multiplier, stun resist, chat HUD, share zip).
- **Route:** UE4SS (experimental v4.0.0-6, `dwmapi.dll` proxy) plus a Lua mod. The game has **no anti-cheat**, and the devs support mods officially (mod.io), so co-op with modded clients is fine.
- **Authority:** all logic runs only where `FindFirstOf("ReadyOrNotGameMode")` is valid, i.e. the host / listen server. Team and health replicate to clients.
- **The user** is on a tight usage budget. Work one vertical slice at a time, verify it in game, commit, and ship a zip from `tools/build_dist.sh`.

## Machine-specific paths (the original dev box)
| What | Path |
|---|---|
| Game | `E:\SteamLibrary\steamapps\common\Ready Or Not` (Steam app 1144200) |
| Mods dir | `...\ReadyOrNot\Binaries\Win64\ue4ss\Mods\` (`mods.txt` lists `RonBridge : 1`, `RonSuspect : 1`) |
| UE4SS log | `...\Binaries\Win64\ue4ss\UE4SS.log` (the mod prints `[SuspectMode] ...`) |
| Working folder | `E:\MixUps\ronsuspect` (this repo is cloned at `E:\MixUps\ronsuspect\repo`; `MODLOG.md` is there too) |
| Bridge files | `E:\MixUps\ronsuspect\bridge\` (`cmd.lua` in, `out.txt` out). The path is hardcoded in `dev/RonBridge` and `dev/q.sh`; change both if you move it. |
| Save backup | `~/.universal-modder/backups/readyornot-saves/*.zip` |

The game folder also has a `version.dll` and `cream_api.ini` that are not ours. Don't touch them.

## Dev loop (fast; no restarts needed for Lua changes)
1. Edit `mod/RonSuspect/Scripts/main.lua`, then copy it into the game's `Mods/RonSuspect/Scripts/`.
2. Hot-load it into the running game:
   ```
   dev/q.sh -e 'dofile([[<Mods>/RonSuspect/Scripts/main.lua]]) RonSuspect.cfg.PrepSeconds=8 P("ok")'
   ```
   Hot-loading again stacks a second LoopAsync and keybinds. That's harmless for tests, but restart the game before a real take.
3. Load a test map without clicking through the menus:
   ```
   dev/q.sh -e 'local K=StaticFindObject("/Script/Engine.Default__KismetSystemLibrary") local pc=FindFirstOf("ReadyOrNotPlayerController") K:ExecuteConsoleCommand(pc,"open /Game/ReadyOrNot/Level/RoN_Gas/Levels/RoN_Gas_Core",pc)'
   ```
   The map loads with `GM_COOP_C` and 8 SWAT AI, but **no suspects or civilians** (the bare `open` skips the mission URL options). For full missions, start one from the menu, or reverse the URL options (TODO).
4. Inspect state with `dev/q.sh dev/recon/state.lua`. Screenshot with
   `powershell -File dev/winshot.ps1 -Proc ReadyOrNotSteam-Win64-Shipping -Out shot.png -Scale 0.33`.
   The universal-modder plugin's `um win shot` (gfxcapture) is broken on this machine.
5. `P(...)` inside bridge code writes to out.txt. A `q.sh` TIMEOUT usually means a map is loading or the game thread is busy.
6. Release: `tools/build_dist.sh v0.x`, then `gh release create v0.x dist/SuspectMode_v0.x.zip`. Never ship RonBridge.

## v0.1 verification (2026-11-13, RoN_Gas_Core)
- `ps.Team=3` made `SWATController:IsCharacterEnemy(player)` true, and 2 controllers had `GetTrackedTarget()` = the player.
- Prep: `bGodMode` true, SWAT blind, head `LimbDamageMultiplier` 1.25 → 0.5. Chat lines showed in game.
- The live phase started on time. "SUSPECTS WIN - you held out 0:25" fired at the 25 s test timer, and the remaining SWAT were killed.

## NOT verified yet (do these first)
1. A full mission started from the menu: are the AI suspects really friendly to suspect-team players, and how do civilians react?
2. Real 2-player Steam co-op (host plus a friend running the same zip). Check that the team swap replicates and the chat shows on the client.
3. Whether SWAT AI actually shoot to kill or stick to their ROE and yell compliance first. If they're too passive, look at the GOAP controller and ROE.
4. Co-op missions without an AI squad may have **zero SWAT**. That's the main blocker, so extra SWAT spawning (ROADMAP M1) is next.
5. Whether stun resist actually helps against flashbangs (`bRepStunned=false` may not end the client-side visual flash).
6. The mission end / scoring screen after a "win". Right now we only kill the remaining SWAT and post chat.

## Gotchas learned
- In bash heredocs, backslashes in Lua patterns break `load` (`"[/\\]"` gave an invalid escape). Avoid backslash patterns.
- Function signatures: `StaticFindObject("/Script/ReadyOrNot.Class:Func"):ForEachProperty(...)`. `IsOnSameTeam(A,B)` takes 2 args.
- `PlayerController:ConsoleCommand` isn't callable from Lua here. Use `KismetSystemLibrary:ExecuteConsoleCommand(ctx, cmd, pc)`.
- AssetRegistry from Lua works: `GetAssetsByPath(FName(path), outTable, true, false)` fills a Lua table of FAssetData.
- The dev box's hook policy blocks `sleep N && ...` chains. Use background waits (`run_in_background`).
