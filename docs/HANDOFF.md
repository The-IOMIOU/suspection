# HANDOFF: read this first

For whoever picks this up next, human or AI agent. Last updated 2026-11-13.

## Where the project stands
- **Goal:** a "Suspect Mode" for Ready or Not that is as big as the normal mode: the players hold a building and the AI comes for them, in Steam co-op. The full wish-list is in [ROADMAP.md](ROADMAP.md).
- **What works on `main`:** enemies that really shoot (`EnemyMode = "hunters"`), a setup phase, players moved away from the entry point, enemy top-up and reinforcement waves, win and lose conditions, chat HUD.
- **Released:** v0.4 (2026-11-14): presets (`standard` = eliminate one SWAT team), SWAT voices (`SpeechCharacterName` = SWATSwan/King/Prescott/Eli/Judge), enemy aim (`Archetype.bAccuracyOverride` + `Accuracy`; the archetype is a shared data asset), players dressed as suspects (`dressPlayers`: captured looks in `looks.txt`, `SkeletalMesh_CSK_*` / `CustomizationFaceMesh` / helmet hidden). v0.3 added enemies dressed as SWAT and the breach grace.
- **v0.4 verified by values, not by eye:** player body/head = suspect meshes, 7/7 CSK parts hidden, voices = SWAT, accuracy 0.55. Your own 3rd-person body can't be seen solo (`SetViewTargetWithBlend` to another pawn didn't switch the camera). Needs a co-op check. Untested: whether SWAT voice banks have lines for every suspect speech event (a missing line just stays silent), and the lobby mannequin dressing.
- **v0.5 (2026-11-14):** the look editor exists as F-keys plus chat feedback (`cycle`, `cycleExtras`, `mylook.txt`). Co-op sync works like this: each change sends `Server_SendChatMessage` `#look <body> <head> <extras>`, and every machine parses `GameState.SavedChatMessages` (re-sent every 60 s for late joiners). Reporting is off (`noReports`: `GameState.bCanReportToTOC=false`, every character `bHasBeenReported=true`, `ReportableActor.bReportableEnabled=false`). Also fixed: `LoadAsset` needs the full object path (`/Game/x/A.A`); the old `gsub` call passed 2 args and silently failed.
- **v0.6 (M4):** the command channel (`runCmd` / `hostReadCmds`: clients send `#cmd <name> <seq>` in chat, the host runs `CMD[name](pawn)` once per seq per sender), the shield (`CMD.hostage`, `tickShields` 50 ms loop, player team set to 3 while shielding), `Helpers` (`dropSquad` keeps N squad SWAT, `dressHelpers`), and the VIP (`pickVIP`, civilian set to team 2, `vipIntel`). Verified: 0 damage over 10 s with 3 hunters at 8 m while shielding, release after 20 s, helpers killed 3 hunters. Config is read once at game start; restart after editing it.
- **Still wanted:** a real character editor UI (the user's words: rework the built-in customization screen so you become a suspect, then add armour on top). Either rework the game's customization UI so you can pick a suspect body/head and add armour on top, or add a mod-side picker (F-key list of `looks.txt` entries, then layer armour/helmet items). Right now the only choice is `SuspectLook = n`.
- **Biggest open problems**, in order:
  1. ~~Enemies look like suspects~~ fixed in v0.3 (`dressHunters`). Still open: the player model and the pre-mission lobby/briefing show SWAT.
  2. Enemies are teleported near the players. They do not walk in from the entry point.
  3. Nothing is tested in co-op, and only one map is tested.
  4. Balance: an idle player died 4 s after the breach.

## The one thing to know about the game's AI
- **The SWAT AI never fights players.** It is the player's command squad. It stays that way after `PlayerState.Team` is set to suspect, after `TargetingComponent:AddKnownEnemy`, and when the player shoots it (tested by a human).
- **Suspect AI fights SWAT-team players by itself**, but only when the game spawned it. Suspects spawned by hand (`SpawnAIFromClass`, or deferred spawn with `Archetype` set) crashed the game on contact, 3 times out of 3.
- So the working design keeps the players on their normal team and uses suspect AI from the map's own `AISpawn` actors as the enemy. `EnemyMode = "swat"` keeps the original team swap, but nobody shoots in it.
- **How suspect AI picks enemies (tested 2026-11-14):** only by the *target's* team. A target on team 1 or 2 (SWAT) is an enemy, a target on team 3 is a friend, and the AI's own team (pawn `DefaultTeam`, controller `GetTeam`, re-possess) changes nothing. So all suspect AI share one rule. You cannot have friendly suspects and hostile suspects at the same time, and a player on team 3 is safe from every suspect.
- **So every hostile AI is dressed as SWAT** (`dressHunters`, v0.3): `Mesh` → `SK_SWAT_U_Heavy_01` / `SK_SWAT_U_Light_01`, `FaceMesh` → masked SWAT head, then `SetMaterial(i, mesh.Materials[i].MaterialInterface)`. Without the material reset the suspect's overrides paint the uniform as a jacket. It's cosmetic and local, so it runs on every machine, not just the host. Users had reported "I get shot by SWAT *and* suspects"; they were all the same suspect AI.
- **Not fixed:** the pre-mission lobby / briefing / loading scenes still show the SWAT squad, and the player model is still a SWAT officer (to a friend in co-op). Ideas: player 3P mesh = `CharacterMesh0` (`SK_Player_NoMesh_Base`) plus ~15 `SkeletalMesh_CSK_*` customization parts and `*VisualizationComponent`s. Hide those and set a suspect body/head the same way as `dressHunters`. Leave the `*1P*` components alone.

## How the mod works (`mod/RonSuspect/Scripts/main.lua`)
All logic runs on the host only (`FindFirstOf("ReadyOrNotGameMode")` is valid there). One `tick()` every 500 ms.

| Step | Function | What it does |
|---|---|---|
| Mission detect | `inMission`, `playerChars` | A mission starts when a real, possessed player pawn exists. Keyed on the GameMode instance, so replaying a map restarts the mode. Lobby mannequins (`BasePlayer_Customization_C`) are ignored. |
| Setup | `makeSuspects(true)` | Players have `bGodMode`, enemies have `bDisableSensePerception`. Per-limb damage multiplier is divided by `SuspectHealthMult` once per pawn. |
| Remove squad | `dropSquad` | Hunters mode: remembers where the AI squad stood, then destroys every `SWATCharacter`. |
| Move players | `moveAway` | Teleports each player once to the farthest of 24 random reachable points within 120 m of the entry point. |
| Breach | `spawnHunters` | Tops enemies up to `SwatBase + SwatPerPlayer * players`. Fires unused `AISpawn` actors (`bEnabled`, `SpawnChance = 1`, `DoSpawn()`), keeps suspects, destroys civilians. |
| Drop | `dropNear` | Teleports a hunter to a navmesh point `HunterDropMin..HunterDropMax` cm from a random living player. |
| Intel | `swatIntel` | Every `SwatIntelEvery` s: `AddKnownEnemy(player)` on every enemy, and re-drops any enemy further than 1.5 x `HunterDropMax`. |
| Waves | in `tick` | Every `ReinforceEvery` s, or at once after a wipe: `ReinforceSize` more, `ReinforceWaves` times. |
| End | `win`, `lose` | Timer, kill target or wipe wins and kills the remaining enemies. All players down loses. |

`spawnSwat` and `giveKit` (SWAT pawns with armour, helmet, pistol, random primary) are only used by `EnemyMode = "swat"`.
Every setting is in `mod/RonSuspect/Scripts/config.lua` with a comment. A `config.lua` from an older version still loads; missing keys get defaults.

## Set up a dev machine
1. Install Ready or Not on Steam (app 1144200). Find `...\Ready Or Not\ReadyOrNot\Binaries\Win64`, called `<Win64>` below.
2. Install UE4SS: download the `UE4SS_v*.zip` asset from the `experimental-latest` release of `UE4SS-RE/RE-UE4SS` and unzip it into `<Win64>` (gives `dwmapi.dll` and `ue4ss\`). Verified with `UE4SS_v4.0.0-6-gef15eba8.zip`.
3. Copy `mod/RonSuspect` and `dev/RonBridge` into `<Win64>\ue4ss\Mods\`.
4. In `<Win64>\ue4ss\Mods\mods.txt`, add `RonBridge : 1` and `RonSuspect : 1` above the `Keybinds : 1` line.
5. Start the game. `<Win64>\ue4ss\UE4SS.log` should show `[SuspectMode] v0.2 loaded`.

Never ship `RonBridge`. It runs any Lua written to a file.
`tools/build_dist.sh v0.x` builds the release zip (UE4SS + mod + installer). Then `gh release create v0.x dist/SuspectMode_v0.x.zip`.

## Dev loop
- **Bridge:** `dev/q.sh -e '<lua>'` or `dev/q.sh file.lua` runs Lua in the game thread and prints what `P(...)` wrote. Files go through `%LOCALAPPDATA%\Temp\ronbridge` (override with `RON_BRIDGE`). `TIMEOUT` means a map is loading or the game crashed.
- **Each mod has its own Lua state.** The bridge cannot see `RonSuspect`. After changing `main.lua`, copy it to the game and restart the game.
- **Load a full mission without the menus:**
  ```
  dev/q.sh -e 'local K=StaticFindObject("/Script/Engine.Default__KismetSystemLibrary") local pc=FindFirstOf("PlayerController") K:ExecuteConsoleCommand(pc,"open /Game/ReadyOrNot/Level/RoN_Gas/Levels/RoN_Gas_BarricadedSuspects_Core",pc)'
  ```
  This lands in the pre-mission lobby. Then start the mission and spawn the player:
  ```
  dev/q.sh -e 'FindFirstOf("ReadyOrNotPlayerController"):ReadyUp()'
  ```
- **Use the `_BarricadedSuspects_Core` map.** It has 66 `AISpawn` actors, suspects and civilians. The plain `RoN_Gas_Core` has no AI and no spawners, so hunters mode spawns nothing there.
- **Screenshot:** `powershell -File dev/winshot.ps1 -Proc ReadyOrNotSteam-Win64-Shipping -Out shot.png -Scale 0.4`.
- **For quick tests** edit the timers in the game's copy of `config.lua` (for example `PrepSeconds = 15`, `SurviveSeconds = 150`, `ReinforceEvery = 40`). Put the repo's `config.lua` back afterwards.
- **After a crash** `CrashReporter.exe` stays open and Steam will not start the game again until it is closed. Crash data is in `%LOCALAPPDATA%\ReadyOrNot\Saved\Crashes` (no symbols).
- `dev/recon/` has the scripts used to explore the game. `dev/recon/class_dump_mod.lua` still writes to a hardcoded `E:/MixUps/ronsuspect/dump/`; change the path before using it.

## What is verified, and how
All on one machine, solo host, 2026-11-13.

| Claim | Evidence |
|---|---|
| Hunters shoot | `RoN_Gas_BarricadedSuspects_Core`, idle player, drops at 15-30 m: squad removed, player moved 112 m, 4 hunters spawned at the breach, player dead 4 s later, "SWAT WINS" posted, no crash. |
| Top-up and waves | Same map without the drop: 8 enemies at the breach, three waves to 14, timer win, no crash. |
| Lobby and replay fixes | The mode starts only after the player spawns, and starts again when the same map is opened twice. |
| SWAT AI is useless as an enemy | `EnemyMode = "swat"` on `RoN_Gas_Core`: 14 armed SWAT, up to 8 tracking the player, no movement, no damage in 200 s. A human then shot at them and they did not shoot back. |

## Not tested
- Co-op with a second player (team, chat and teleport replication).
- Any map other than the gas station, and missions started from the menu.
- The default drop distance (25-45 m). Only 15-30 m was run.
- `WinMode = "kills"` in hunters mode.
- Whether stun resistance does anything (`bRepStunned = false` may not clear the client-side flash).
- A proper mission end screen. A win or loss is only a chat line.

## Things that crash the game
- Passing the userdata from `InventoryComp:GetLastEquippedLoadout()` into `Server_AttemptEquipNewLoadout` or `EquipLoadoutOnPlayer`.
- A hand-spawned `CyberneticsSuspect_V2_C` with `Archetype` set, within about 7 m of a SWAT-team player (armed or not). `EXCEPTION_ACCESS_VIOLATION reading 0x290`.
- Possibly `CyberneticController:SetAwarenessState(2)` on such a pawn (it crashed right after, cause not isolated).

## Lua and UE4SS gotchas
- In bash heredocs, backslashes in Lua patterns break `load`. Avoid backslash patterns.
- Function signatures: `StaticFindObject("/Script/ReadyOrNot.Class:Func"):ForEachProperty(...)`.
- `PlayerController:ConsoleCommand` is not callable from Lua. Use `KismetSystemLibrary:ExecuteConsoleCommand(ctx, cmd, pc)`.
- Out-parameters that are structs take a Lua table, which gets filled: `N:K2_GetRandomReachablePointInRadius(ctx, origin, out, radius, nil, nil)`.
- `StaticFindObject` only finds loaded classes. The suspect blueprint class is not loaded on a map without suspects.
- Python on Windows cannot see Git Bash's `/tmp`. Keep helper scripts inside the repo folder (`build/` is gitignored).

More engine detail (classes, fields, spawn calls) is in [ENGINE_NOTES.md](ENGINE_NOTES.md).

## Ideas for the open problems
1. **SWAT look:** hunters have an `InventoryComp`; try adding `Armor_Light_V2` and `BP_Helmet_Standard` with the `giveKit` item-spawn method and see whether they show on a suspect body. Otherwise look for a mesh override (`CharacterMeshData`, `Multicast_SendCharacterMeshData`). Change the chat wording either way.
2. **Walking in:** hunters ignore `AIController:MoveToActor` (returns 2, then they resume patrol). Look at `CyberneticController:RequestMoveAsync`, `AddActivity` / `RemoveAllActivitiesExcept`, and what the suspect AI does when it hears noise (`AddExposedToStimulusTag`).
3. **Fair drops:** check line of sight before dropping (`TargetingComponent:CanCharacterBeSeen`), and prefer points behind doors.
