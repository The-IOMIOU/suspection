# ROADMAP: everything the user asked for, ordered so each milestone ships on its own

Rule from the user: **don't make it too OP.** It depends on the character and the kit. Every feature gets a toggle or slider in `config.lua`.
Each milestone = vertical slice → in-game verify → commit → `tools/build_dist.sh` → GitHub release.

Legend: [x] done · [ ] todo · (hint) = where to start, see ENGINE_NOTES.md

## M0: Lite core (v0.1) [x]
- [x] Players moved to TT_SUSPECT; AI suspects become allies, SWAT AI hunts players
- [x] Adjustable setup time at the start of each map (god mode, SWAT blind)
- [x] Win modes: survive timer / kill N SWAT / wipe all SWAT
- [x] Suspect health multiplier (per-limb damage multiplier)
- [x] Stun / sound resistance (suspects affected "way less")
- [x] Chat HUD, F7 toggle, F8 status, installer zip for friends

## M1: Enough SWAT, always (next; it blocks co-op without an AI squad)
- [ ] Spawn N SWAT AI (`SwatCount` slider; scales with player count, e.g. 2 players vs 10 SWAT) at the map's SWAT start (hint: `AISpawn.DoSpawn`, `ArchetypeOverride`, or SpawnActor of `CyberneticsSwat_V2_C` + `BP_SWAT_GOAP_Controller_C`; spawn tags `SWATRedStartTag`)
- [ ] Waves / reinforcements (`bUseReinforcements`, `Reinforcements_TimeRemaining`)
- [ ] Make sure SWAT actually breach toward players (stack-up / breach activities on doors near players)
- [ ] Settings: SWAT accuracy, damage dealt to suspects, damage dealt to SWAT (separate sliders)
- [ ] Mode: "survive N SWAT kills" = the SWAT ticket pool

## M2: Suspect loadouts (no police gear)
- [ ] Suspect-only weapons: Uzi/Micro-Uzi, the AI suspects' pistols/SMGs/shotguns/AKs (hint: the `InventoryComp` of `SuspectCharacter`s and their `GlobalWeaponOverride` items; give them to players)
- [ ] Remove police gear (flashbangs, stingers, pepperball, cuffs) from players
- [ ] Real frag grenades instead of flashbangs; molotov / gasoline can + lighter (fire zones)
- [ ] Loadout picker per player (kits / "characters" with different trade-offs so nothing is OP)
- [ ] Specials (one per kit): knife, bazooka/RPG, taser, laser burner, door-trap kit, vaseline (slip floor), cyberdeck

## M3: Traps and fortification (uses the setup time)
- [ ] Booby-trap doors (hint: `AllDoorTrapActors` already exist in game: spawn or arm the game's own door traps; SWAT has `DisarmDoorTrapActivity`, so it's fair)
- [ ] Bombs / IEDs, remote det, tripwires
- [ ] Barricade doors (lock + wedge-style blocking; SWAT must ram/C2)
- [ ] "Vietnam" traps: punji pits, swinging spikes, grenade-in-can tripwires, spike boards, bamboo whips
- [ ] Gasoline tanks that can be ignited
- [ ] Security cameras placed around the map + camera viewer to see who is coming
- [ ] Vaseline / oil slick: SWAT slip and ragdoll
- [ ] Trap budget per kit (balance)

## M4: Civilians and hostages
- [ ] Take civilians hostage, drag them, use them as a human shield (SWAT hold fire / ROE)
- [ ] Booby-trap civilians (bomb vest; `bAllowExplosiveVestSpawn` exists)
- [ ] Secretly recruit civilians and arm them (switch them to TT_SUSPECT + give a weapon)
- [ ] Negotiate a ransom (timer pause / SWAT holds while talking) → set up an ambush
- [ ] Objective per map: defend a VIP / package / server / boss suspect ("protect target")

## M5: Survival and deception
- [ ] Downed instead of dead: SWAT can cuff a downed suspect; a teammate can patch + untie them; self-untie+patch once (`SelfRescueCount` setting) (hint: CharacterHealthComponent revive fields, arrest fields)
- [ ] Captured-target timer: if SWAT capture the VIP, a rescue timer runs while SWAT defend; SWAT only win by killing everyone or holding the capture
- [ ] Fake death with stealth body armour: drop to ragdoll, play dead, get up later
- [ ] Disguise as a dead body / camo / blend in as a civilian
- [ ] Chokehold from behind (silent takedown)
- [ ] Steal SWAT equipment → see the other SWAT positions on a map/radio (toggle)

## M6: Cyberdeck (the big one)
- [ ] Hack SWAT comms: talk to the squad (push-to-talk → speech-to-text → LLM playing the SWAT element)
- [ ] The fake info you feed them ("suspect detected in upper room") moves the SWAT AI there (map callouts → rooms → MoveTo/search activities)
- [ ] SWAT memory: they log every tip; too many lies / contradictions → suspicion meter → they ignore you or trace the hack
- [ ] Qwen TTS for SWAT radio replies (local server, like the user's "scam with your friends" project)
- [ ] Negotiation calls through the same pipeline

## M7: Polish to "as big as normal SWAT mode"
- [ ] Proper mission end screen / scoring for suspects
- [ ] Per-map scenario presets (what to defend, spawn points, trap spots)
- [ ] In-game settings menu (instead of editing config.lua)
- [ ] AI suspect helpers count + difficulty sliders
- [ ] Balance pass, showcase video, mod.io / Nexus release
