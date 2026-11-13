# Engine notes: Ready or Not internals relevant to Suspect Mode
All names are from the live game via UE4SS (2026-11-13 build). Re-dump with `dev/recon/class_dump_mod.lua` after game updates.
That writes `classes.txt`, `enums.txt` and `props.txt` (gitignored). Don't commit dumps.

## Enums
- `ETeamType`: NONE 0, SERT_RED 1, SERT_BLUE 2, **SUSPECT 3**, CIVILIAN 4, SQUAD 5
- `ELimbType`: None 0, RightLeg 1, LeftLeg 2, RightArm 3, LeftArm 4, Head 5
- `EAITeamTactic`: None, Suppress, Cover, Flank, Push, Charge, Custom

## Classes and members
| Class | Useful members |
|---|---|
| `ReadyOrNotPlayerState` | `Team` (writable), `SetTeam(NewTeam)`, `Server_SetTeam`, Kills/Deaths/Arrests, `bIsVIP` |
| `ReadyOrNotCharacter` | `GetTeam()`, `DefaultTeam`, `HandleTeamChanged(Team)`, `CharacterHealth`, `InventoryComp`, `bGodMode`, `Kill()`, `IsHealthDepleted()`, `IsStunned()`, `bRepStunned`, `StartStun(StunType,Causer,Duration)`, `ApplyDamageToBone(Damage,HitBone,DamageEvent,Instigator,Causer)`, `Server_ApplyPointDamage(...)`, `Multicast_TakeDamage(...)`, arrest fields (`bSurrendered`, `bIsBeingArrested`, `bArrestComplete`, `ArrestedBy`), `bCarryingDead`, `IsOnSameTeam(A,B)` |
| `PlayerCharacter` / `BasePlayer_C` | the human pawn |
| `CyberneticCharacter` | AI base. `SWATCharacter` (BP `CyberneticsSwat_V2_C`, `CyberneticsSwatTrailer_C`), `SuspectCharacter`, `CivilianCharacter` |
| `CyberneticController` | `IsCharacterEnemy(InCharacter)`, `IsCharacterKnownEnemy`, `GetTrackedTarget()`, `bDisableSensePerception`, `AIPerceptionComponent`, `SightConfig`, `HearingConfig`, `TargetingComponent`, `bHasEverHeardSwat` |
| `SWATController` (BP `BP_SWAT_GOAP_Controller_C`) | activities: StackUp, BreachAndClear, KickDoor, C2Door, RamDoor, ShotgunDoor, ThrowGrenadeThroughDoor, MirrorUnderDoor, DisarmDoorTrap, DisarmStandaloneTrap, SearchAndSecure, ArrestTarget, PickUpCharacter, EngageLessLethal... (`Get*Activity`) |
| `CharacterHealthComponent` | limbs `Head/LeftArm/RightArm/LeftLeg/RightLeg` = `LimbHealthData{Health, MaxHealth, MaxHealthLimit, LowHealthThreshold, LimbDamageMultiplier(~1.25), MaxTickets, Tickets, ...}`, `SetLimbHealth(Limb,Amount)`, `SetMaxLimbHealth(Limb,Max)`, `HealthStatus`, revive fields (`MaxRevives`, `RemainingRevives`, `ReviveTime`, `bUnlimitedRevives`), `bEnableIncapacitation` |
| `ReadyOrNotGameMode` (BP `GM_COOP_C`) | `SuspectStartTag`, `SWATRedStartTag`, `SWATBlueStartTag`, `SpawnPlayerCharacter(Controller,Class,Transform,bNoFail)`, `SwapPlayerTeams()`, `IsTeamDead(Team,bIncludeArrested)`, `RespawnPlayer`, `bCanRespawn`, `RespawnMode` |
| `ReadyOrNotGameMode_PVP` | RoundWon/RoundEnd/MatchEnd/TimeLimitVictoryConditions. **A leftover PvP framework with suspect start tags**; it could become a real suspects-vs-SWAT round system. |
| `ReadyOrNotGameState` | `NumSwatActive/NumSuspectsActive/NumCiviliansActive`, `AllDoors`, `AllDoorTrapActors`, `AllSWATCharacters`, `KilledSWATCharacters`, `AIFactionManagers`, `GametypeDamageModifier` + Head/Leg/Arm modifiers, `Multicast_BroadcastChatMessage(RChatMessage{SenderName,Message,Color,AssociatedTeam,TargetTeam,...})`, `bUseReinforcements`, `Reinforcements_TimeRemaining`, `RoundTimeRemaining`, `bPvPMode`, `bShowEnemiesAsSuspects` |
| `AISpawn` | `DoSpawn()`, `GetSpawningTeamType()`, `ArchetypeOverride`, `GlobalWeaponOverride`, `SpawnArray`, `bAllowExplosiveVestSpawn`, `SpawnedCharacter`. The likely way to spawn extra SWAT or suspect helpers. |
| `AIFactionManager` | `SuspectTeams`, `TeamsOf`, `AlertOtherSuspectsInTeam_Blueprint`, `GetTeamTacticFor` |

## Mission maps (`_Core` World assets)
RoN_Gas_Core, Ron_Agency_Core, RoN_Beachfront_Core, RoN_Club_Core, RoN_Coyote_Core, RoN_Datacenter_Core, RoN_Dealer_Core,
RoN_Farm_Core, RoN_Hospital_Core, RoN_Importer_Core, RoN_Meth_Core, RoN_Penthouse_Core, RoN_Port_Core_NEW, RoN_Ridgeline_Core,
RoN_Campus_Core, RoN_Sins_Core, RoN_Station_Core, RoN_Streamer_Core, RoN_Valley_Core, RoN_TutorialV3_Core, plus `*_BarricadedSuspects_Core`
variants and DLC (RoN_Station_DLC01_Core, RoN_Dorms_Core, RoN_Lawmaker_Core, RoN_Narcos_Core). Full paths: `dev/recon/maps2.lua`.
Example: `/Game/ReadyOrNot/Level/RoN_Gas/Levels/RoN_Gas_Core`.

## Spawning AI (found 2026-11-13)
- `AIBlueprintHelperLibrary:SpawnAIFromClass(ctx, class, nil, Location, Rotation, true, nil)` with `/Game/Blueprints/Characters/AI/CyberneticsSwat_V2.CyberneticsSwat_V2_C` gives a pawn with a `BP_SWAT_GOAP_Controller_C`, team 0 and an **empty inventory**. Set `DefaultTeam` + `HandleTeamChanged(1)`.
- Items: `GameplayStatics:BeginDeferredActorSpawnFromClass(pawn, itemClass, Transform, 1, pawn, 0)` → `FinishSpawningActor` → `InventoryComp:AddInventoryItem(item)` → `InventoryComp:EquipItemOfClass(class, true)`.
- Map SWAT carry: `ArmorRevised/Armor_Light_V2`, `ArmorRevised/Helmets/BP_Helmet_Standard`, `WeaponsRevised/Secondary_G19_V2`, a primary (`Primary_MCX`, `Primary_BRN180`, `Primary_SPC9`, `Primary_Superbnova`), flashbangs, stinger, C2, door jam, zipcuffs, multitool (all under `/Game/Blueprints/Items/`).
- Navmesh point: `NavigationSystemV1:K2_GetRandomReachablePointInRadius(ctx, Origin, outTable, Radius, nil, nil)` fills `outTable.X/Y/Z`.
- `ReadyOrNotPlayerController:SpawnRandomAI(Count)` spawned a `CyberneticsSuspect_V2_C` on team 3 (useful for AI suspect helpers). Also `SpawnAI(TableName, Count)` and `SpawnAIAtLocation(TableName, Location, MoveLocation)`; table names unknown.
- Map SWAT have `Archetype` nil and no `AISpawn` actor; there are no `PlayerStart` actors on RoN_Gas_Core.
- `SavedLoadout` is a plain struct of item classes (`Primary`, `Secondary`, `Armor`, `Helmet`, ...). `BpGameplayHelperLib:EquipLoadoutOnPlayer(Loadout, Character, LoadoutEquipOptions)` exists but is untested with a Lua table.
- Player: `GameMode:SpawnPlayerCharacter(pc, BasePlayer_C class, Transform, true)` works; `RespawnPlayer(pc, false)` did nothing from the lobby.
