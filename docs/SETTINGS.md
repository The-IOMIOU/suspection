# Settings reference

Every setting of Suspect Mode, what it does, and where to change it.

## Where settings come from

Settings are applied in this order, each one overriding the previous:

1. **`config.lua`** (`...\Win64\ue4ss\Mods\RonSuspect\Scripts\config.lua`): the defaults, one per line with a comment.
2. **The preset** (`Preset` setting): overrides the values it sets (see the table below). `custom` overrides nothing.
3. **`settings.txt`** (same folder): what you changed in the **F8 menu** or with `!set`. It's written automatically
   and wins over everything else. Delete it to go back to the defaults.

**In co-op the host's settings decide the rules.** A friend changing something in the menu sends it to the host.
Outside a match (main menu, station) the menu changes your own saved settings.

`config.lua` is read once when the game starts: after editing it by hand, restart the game. Menu changes apply
immediately, but team size, timers and presets take effect from the next mission.

## How to change a setting

| Way | Example |
|---|---|
| **F8 menu** | Press F8, Up/Down to the row, Left/Right to change it |
| **Chat** | `!set EnemyAccuracy 0.4`, `!set ProtectVIP off`, `!preset hardcore`, `!menu` |
| **config.lua** | Edit the value, save, restart the game |

Booleans accept `true`/`false` or `on`/`off` in chat.

## Presets

| Setting | standard (default) | easy | hardcore | survival |
|---|---|---|---|---|
| Win condition (`WinMode`) | eliminate | eliminate | eliminate | timer (10 min) |
| SWAT team (`SwatBase` + `SwatPerPlayer` x players) | 6 + 2 | 4 + 1 | 8 + 3 | 6 + 2 |
| Reinforcements (`ReinforceEvery`) | off | off | every 150 s, 2 waves of 3 | every 120 s, 3 waves of 2 |
| SWAT aim (`EnemyAccuracy`) | 0.55 | 0.35 | 0.9 | 0.55 |
| Your toughness (`SuspectHealthMult`) | 2.5 | 4 | 1.5 | 2.5 |
| Setup time (`PrepSeconds`) | 60 | 90 | 45 | 60 |
| Breach grace (`BreachGrace`) | 10 | 15 | 5 | 10 (default) |
| SWAT told where you are (`SwatIntelEvery`) | every 30 s | every 45 s | every 20 s | every 20 s (default) |

`custom` = use `config.lua` / your menu choices exactly.

## All settings

### Rules

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `Enabled` | true | F7 (host) | Turns the whole mode on or off |
| `Preset` | standard | yes | See the presets table |
| `WinMode` | eliminate | yes | `eliminate` = kill the whole SWAT team; `timer` = survive `SurviveSeconds`; `kills` = kill `KillTarget` SWAT |
| `SurviveSeconds` | 600 | yes | Length of the survive timer (timer mode) |
| `KillTarget` | 4 | yes | Kills needed (kills mode) |
| `PrepSeconds` | 60 | yes | Setup time before the breach. You can't be hurt and SWAT is blind |
| `BreachGrace` | 10 | yes | Seconds SWAT stay blind after the breach |
| `SpawnAway` | true | no | Move players away from the SWAT entry point at the start |
| `ProtectVIP` | true | yes | A civilian becomes the VIP; SWAT win if they die |

### SWAT (the enemy)

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `SwatBase` | 6 | yes | SWAT at the breach... |
| `SwatPerPlayer` | 2 | yes | ...plus this many per player (2 players = 10 SWAT) |
| `SwatMax` | 24 | no | Never more than this many alive at once |
| `ReinforceEvery` | 120 (0 in standard) | yes | Seconds between reinforcement waves, 0 = off |
| `ReinforceSize` | 2 | yes | SWAT per wave |
| `ReinforceWaves` | 3 | yes | Number of waves. Wiping the team only wins once waves are used up |
| `EnemyAccuracy` | 0.55 | yes | SWAT aim from 0 to 1 (1 = the game's normal aim) |
| `SwatIntelEvery` | 20 (30 in standard) | no | Every N seconds all SWAT learn where the players are (0 = they must spot you) |
| `SwatVoices` | true | yes | Enemies use SWAT voice lines |
| `DressEnemiesAsSwat` | true | yes | Enemies wear SWAT uniform, masked head, plate carrier and helmet |
| `EnemyMode` | hunters | no | `hunters` = the working mode. `swat` = the old experimental team swap (the SWAT AI never shoots, don't use it) |
| `HunterDropMin` / `HunterDropMax` | 2500 / 4500 | no | How far (cm) from a player SWAT are placed when they arrive |

### You (the suspects)

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `SuspectHealthMult` | 2.5 | yes | Damage you take is divided by this |
| `StunResist` | true | yes | Flash/stinger/gas stuns are cut short |
| `StunMaxSeconds` | 0.75 | no | Longest a stun can last when `StunResist` is on |
| `ShieldSeconds` | 20 | yes | How long SWAT hold fire while you hold a human shield |
| `ShieldCooldown` | 30 | yes | Wait before grabbing another hostage |
| `Helpers` | 0 | no | AI suspects on your side. **Leave at 0**: it is unfinished (they can render invisible) |

### Looks

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `DressPlayersAsSuspects` | true | yes | Players, the van intro and the loadout preview look like suspects |
| `DressKeepArmor` | true | no | Default gear when you haven't picked one in the look panel |
| `SuspectLook` | 0 | no | 0 = your look comes from the look panel / your name; 1..n forces a look from `looks.txt` |

### Loadout

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `SuspectArsenal` | true | no | Adds the suspect weapons and frag grenades to the loadout, removes police less-lethal gear |
| `SuspectWeaponsOnly` | true | yes | Primary/sidearm lists hold only suspect guns. Off = vanilla guns too |

### Other

| Setting | Default | Menu | What it does |
|---|---|---|---|
| `NoReporting` | true | yes | No reporting to TOC, map SWAT objectives hidden |
| `AnnounceEvery` | 60 | no | Seconds between status lines in chat |
| `ToggleKey` | F7 | no | Host key to turn the mode on/off |
| `StatusKey` | F8 | no | Key that opens the menu |

## Files the mod writes

All in `...\Win64\ue4ss\Mods\RonSuspect\Scripts\`. All safe to delete (the mod recreates them).

| File | Contents |
|---|---|
| `settings.txt` | Your menu / chat setting changes |
| `looks.txt` | Every suspect look the mod has seen (body, head, materials) |
| `mylook.txt` | Your chosen body, head and gear |
