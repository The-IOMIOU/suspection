# HANDOFF: read this first (for the next Claude / agent)

## TL;DR
- **Goal:** a full "Suspect Mode" for Ready or Not, as big as the normal SWAT mode. Players are suspects, the AI is SWAT, and it works in Steam co-op. See [ROADMAP.md](ROADMAP.md) for the whole wish-list (the user wants *everything*, built incrementally).
- **Done:** v0.1 lite, plus v0.2 work on `main` (not released): SWAT top-up spawn with kit, reinforcement waves, "SWAT wins" when all players are down, lobby and replay fixes. See "v0.2 session" below.
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
| Bridge files | `%LOCALAPPDATA%\Temp\ronbridge` (`cmd.lua` in, `out.txt` out), or `$RON_BRIDGE` if set. `dev/RonBridge` and `dev/q.sh` share that default. |
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

## v0.2 session (2026-11-13, second dev box, RoN_Gas_Core, solo host)
Second box: game at `C:\Program Files (x86)\Steam\steamapps\common\Ready Or Not`. No working folder outside the repo clone.

Verified in game (three full automated rounds, player idle):
- Top-up at the breach: 4 map SWAT + 4 spawned = 8 (`SwatBase 6 + SwatPerPlayer 2 * 1`), then 3 waves of +2 → 14. All 14 held a weapon.
- Timer win fires and kills the remaining SWAT. Replaying the same map starts a fresh round.
- The mode no longer starts in the pre-mission lobby.

Found, not fixed:
- **Spawned SWAT are passive.** `GetTrackedTarget()` is valid only for the map's own 4; the spawned ones stand at the spawn point.
- **No SWAT shot an idle player.** The player stood 60 cm from the squad for 140 s at 100 health. Not tested: whether they fire once the player shoots or holds a gun on them (needs a human at the keyboard).
- "SWAT WINS" (all players down) is written but never triggered in a test.
- Not tested: co-op with a second player, maps with no SWAT of their own (the anchor then falls back to a far navmesh point), full missions from the menu.

Fixes to v0.1 behaviour made on the way:
- `BasePlayer_Customization_C` (lobby mannequins) are `PlayerCharacter`s. They used to start the setup timer in the pre-mission screen; `playerChars()` now ignores them and needs a controller.
- The mission key is the GameMode instance name, not the map name, so a replay of the same map restarts the mode.
- `CyberneticsSwatTrailer_C` pawns parked at z = -10000 are no longer counted as SWAT (they made "wipe all SWAT" impossible).

How to drive the game without a human:
- `open <map>` lands in the pre-mission lobby. `FindFirstOf("ReadyOrNotPlayerController"):ReadyUp()` starts the mission and spawns the player.
- Each mod has its own Lua state: `RonSuspect` is not visible from the bridge. Changed mod code needs a game restart (or hot-load a second copy into the bridge state, which then runs next to the first).
- A crash leaves `CrashReporter.exe` open and Steam will not relaunch until it is closed.
- **Crash:** passing the userdata from `InventoryComp:GetLastEquippedLoadout()` into `Server_AttemptEquipNewLoadout` / `EquipLoadoutOnPlayer` killed the game. Don't.

## v0.2 session, part 2: why SWAT don't fight (2026-11-13)
What was measured on RoN_Gas_Core, player idle with a rifle in hand:
- Map SWAT have a `SwatCombatActivity` (`ctl:GetCombatActivity()`); spawned SWAT have none. Spawned SWAT do sense the player (`LastSensedCharacter`, `RecentlySeenSuspects`).
- `ctl.TargetingComponent:AddKnownEnemy(player, true)` makes spawned SWAT track the player (0 → 5-8 of 14 tracking). This is now `SwatIntelEvery` in the mod.
- Even so, in a 200 s live round nobody moved toward the player and the player took **no damage** (all limbs 100).
- The squad HUD still lists the map's 4 SWAT under the player with orders (FALL IN, MOVE TO): they are the player's own command squad and stand 60-70 cm from the leader. Changing `PlayerState.Team` does not detach them.
- `SpawnRandomAI(3)` gave 2 civilians and 1 suspect. Moved to team 1 they track the player, but the suspect was unarmed and did nothing.

Not tested (needs a human playing): whether SWAT open fire once the player shoots at them or aims at them.

Ideas, untested:
1. Detach the map squad from the player (find where the squad/leader is stored: look for a SWAT manager, `OnSquadRoleAssigned`, `IsSameSquad`, the command HUD's source) or kill it at the breach and use only spawned SWAT.
2. Give spawned SWAT a combat activity (find what creates `SwatCombatActivity` for the map squad).
3. Use the autonomous suspect AI as the enemy instead: `CyberneticsSuspect_V2_C` + `SuspectController` on team 1 with a weapon from `giveKit`-style item spawning, since suspect AI attacks on its own in the normal game.

## v0.2 session, part 3: hostile AI experiments (2026-11-13)
- **User test (human at the keyboard): SWAT do not shoot back when the suspect-team player shoots them.** The SWAT AI never fights players, whatever their team.
- `SpawnAway` (new, verified): during setup each player is teleported once (`K2_TeleportTo`) to the farthest of 24 random reachable points within 120 m of the squad. Test: moved 61 m on RoN_Gas_Core.
- Spawned AI is inert because `Archetype` is nil. A suspect spawned deferred with `a.Archetype = a.DefaultSuspectArchetype` (`/Game/Blueprints/AI/Archetypes/Core/Suspect_Common`) set before `FinishSpawningActor` does walk around.
- **Crash, 3 times out of 3:** such an archetyped `CyberneticsSuspect_V2_C` (team 3, player on team 2) placed within ~7 m of the player crashes the game within seconds, armed by `giveKit`-style items or unarmed. `EXCEPTION_ACCESS_VIOLATION reading 0x290`, no symbols. One placed 8-15 m away with no line of sight wandered for 40 s without a crash. So hand-spawned suspects lack data the combat code needs.
- `SpawnAIFromClass` gives suspects team 0; `SpawnRandomAI` gives team 3. A suspect moved to team 1 reports `IsCharacterEnemy(team-3 player) == false`; on team 3 against a team-2 player it reports true.
- Only `Suspect_Common` and `Civilian_Scared` archetypes are loaded on a bare `open` map; there is no SWAT archetype object.

Next idea, untested: in a full mission started from the menu the map has real `AISpawn` actors. Move one (`K2_SetActorLocation`) and call `DoSpawn()` to get a fully initialised suspect, then compare its fields with a hand-spawned one to find what is missing. Fully working hostile AI in this game is suspect AI against SWAT-team players, so the mode may have to keep players on the SWAT team internally and present suspect AI as the "SWAT" (look and kit swapped).
