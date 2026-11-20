# How Suspect Mode works

A tour of the mod for anyone who wants to understand or change it. The code is one Lua file,
`mod/RonSuspect/Scripts/main.lua`, run by **UE4SS** inside Ready or Not. Exact class names, fields and the gotchas
found along the way are in [ENGINE_NOTES.md](ENGINE_NOTES.md) and [HANDOFF.md](HANDOFF.md).

---

## 1. The big picture

```
                 every machine (host and clients)                         host only
  ┌───────────────────────────────────────────────────────────┐   ┌──────────────────────────────────┐
  │ looks: dress enemies as SWAT, players/mannequins as        │   │ the rules: setup timer, breach,  │
  │        suspects (follower meshes), SWAT voices + aim       │   │ spawning SWAT, intel, waves,     │
  │ loadout: suspect arsenal in the LoadoutManager lists       │   │ win/lose, VIP, human shield,     │
  │ UI: F8 menu, CHARACTER LOOK panel, label swaps             │   │ no-reporting, settings commands  │
  └───────────────────────────────────────────────────────────┘   └──────────────────────────────────┘
                 ▲                                                                ▲
                 │       chat lines as a message bus: #look, #cmd, !set, !preset, !menu
                 └────────────────────────────────────────────────────────────────┘
```

- **Host authority.** Ready or Not co-op is a listen server: the host's game owns the AI, health and teams. The mod
  checks `FindFirstOf("ReadyOrNotGameMode")` (only exists on the host) and runs the rules there. Team, health and
  actor positions then replicate to clients through the game itself.
- **Cosmetics run everywhere.** Mesh swaps and UI are local to each machine, so every player runs the same mod and
  each machine dresses what it sees.
- **One loop.** A 500 ms `LoopAsync` calls `tick()` (host rules) plus the cosmetic passes, all inside
  `ExecuteInGameThread` and `pcall`, so an error in one feature can't stop the others.

## 2. The key discovery: who the AI shoots

Everything is built around how the game's AI chooses targets (tested in game):

- **The real SWAT AI never fights players.** It is the player's command squad. Even with the player moved to the
  suspect team and marked as a known enemy, it tracks you and never fires.
- **Suspect AI picks enemies only by the *target's* team.** Team 1/2 (SWAT) = enemy, team 3 (suspect) = friend.
  The AI's own team doesn't matter.

So the mod keeps players on their normal SWAT team internally and uses the **game's own suspect AI** as the enemy,
spawned from the map's `AISpawn` actors. Then it **dresses that AI as SWAT** (uniform, masked helmet head, plate
carrier, helmet, SWAT voices). To the players it's a SWAT team; to the engine it's armed suspects, the one AI
that really shoots players.

The same rule powers the **human shield**: while you hold a hostage you are switched to team 3 for a few seconds,
and every enemy holds fire.

## 3. A mission, in code

| Phase | Function | What happens |
|---|---|---|
| Detect | `inMission` | A mission starts when a real, possessed player pawn exists. Keyed on the GameMode instance, so replaying a map restarts the mode. The station hub (`GM_Lobby_C`) is ignored. |
| Setup | `makeSuspects(true)`, `moveAway`, `dropSquad` | Players get god mode, enemies are blinded, players are moved far from the SWAT entry, the AI squad is deleted. Player limb damage multipliers are divided by `SuspectHealthMult`. |
| Breach | `spawnHunters`, `swatIntel`, `pickVIP` | Unused map spawners are fired until there are `SwatBase + SwatPerPlayer x players` enemies; each is dropped 25-45 m from a player; all learn where the players are; a civilian becomes the VIP. |
| Fight | `tick`, `swatIntel`, `vipIntel` | Every `SwatIntelEvery` s, enemies are told where players (and the VIP) are; stragglers are brought back. Reinforcement waves if enabled. |
| End | `win`, `lose` | Eliminate / timer / kills win; all players down or the VIP dead loses. |

## 4. Making the AI look like SWAT

`dressHunters` (every machine, every tick): for each `SuspectCharacter` whose body isn't SWAT yet:
- set `Mesh` to a SWAT uniform and `FaceMesh` to a masked SWAT head, then re-apply the SWAT mesh's own
  materials (otherwise the suspect's material overrides paint the uniform as a jacket);
- `armourUp` adds a plate carrier and a helmet as extra `SkeletalMeshComponent`s that follow the body's pose;
- `SpeechCharacterName` is set to a SWAT voice (SWATSwan, King, Prescott, Eli, Judge);
- `Archetype.Accuracy` is set to `EnemyAccuracy`.

It runs every tick because the game re-applies the suspect's look after spawning.

## 5. Making players look like suspects

**Looks are captured, not shipped.** Before an enemy is dressed as SWAT, `captureLook` records its body, head and
base materials into `looks.txt`. That list is what the look panel offers.

**Follower meshes.** Putting a suspect mesh into a SWAT/player body component makes it render invisible (different
skeleton and animation setup). So `dressFollowers` hides the pawn's own body and face (they keep animating:
`VisibilityBasedAnimTickOption = 0`) and attaches two new mesh components, the suspect body and head, that copy the
pose with `SetLeaderPoseComponent`. This is used for:
- the players in a mission (what your friend sees);
- the mannequins: the pre-mission **van intro** and the **loadout preview** ("PlayerPreview"). These are
  `BasePlayer_Customization_C`, which is not a `PlayerCharacter`. Their helmet, goggles and armour are separate
  attached item actors, hidden or shown according to the GEAR choice.

**Asset loading.** Loading a mesh mid-mission crashed the game in testing, so looks are only loaded outside missions,
or while the loadout screen is open (`S.noLoad`).

## 6. The loadout

The loadout screen reads `LoadoutManager` (on the GameInstance), whose lists `PrimaryWeapons`, `SecondaryWeapons`,
`LongTacticalItems` and `TacticalItems` hold item **class default objects**. `arsenal()`:
1. snapshots the vanilla lists once;
2. loads the suspect-only item classes the game ships (AK-102... frag grenade), takes their CDOs, registers them in
   `LoadoutItems` and `ItemLookupMap` (keyed by name, e.g. `AK102`, so every machine agrees regardless of order);
3. rebuilds the four lists: suspect guns only, or vanilla + suspect, always without police gear.

The UI ignores `bShowInLoadout`, so removal is done by emptying and refilling the arrays.

## 7. The UI

All UI is real UMG built at runtime from Lua (`WidgetBlueprintLibrary:Create` + `StaticConstructObject` of a
`WidgetTree`, `CanvasPanel`, `Border`, `BackgroundBlur`, `VerticalBox`, `TextBlock`...), styled like the game:
dark translucent panel, the game's Barlow font, uppercase labels, a dark-red selection bar, red key hints.

| UI | When | Input |
|---|---|---|
| Suspect Mode menu | F8 | arrows |
| CHARACTER LOOK panel | while `W_Loadout_V2_C` or `W_Customization_C` is on screen | arrows (when the F8 menu is closed) |
| Chat lines | status, countdown, win/lose | |
| Label swaps (`uiText`) | always | `S.W.A.T.` becomes `SUSPECTS` |

## 8. Talking between machines

There is no custom networking. The mod uses the game's **chat** as a message bus:

| Line | Sent by | Read by | Purpose |
|---|---|---|---|
| `#look <body> <head> <gear>` | anyone, on change + every 60 s | everyone | Your chosen look |
| `#cmd <name> <seq>` | client | host | Run a host command for that player (kept for future features) |
| `!set <key> <value>`, `!preset <name>`, `!menu` | anyone (menu or typed) | host | Change / show settings |

Each machine reads `GameState.SavedChatMessages`.

## 9. Repository map

| Path | What |
|---|---|
| `mod/RonSuspect/Scripts/main.lua` | The mod |
| `mod/RonSuspect/Scripts/config.lua` | Default settings |
| `installer/` | `install.bat`, `uninstall.bat`, the readme inside the zip |
| `tools/build_dist.sh` | Builds the release zip (UE4SS + mod + installer) |
| `dev/RonBridge/` | Dev-only REPL mod: run Lua inside the live game. **Never ship it** |
| `dev/q.sh`, `dev/winshot.ps1` | Send Lua to the bridge; screenshot the game window |
| `dev/recon/` | Scripts used to reverse-engineer the game |
| `docs/` | This documentation |
