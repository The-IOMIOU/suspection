# Suspection: Suspect Mode for Ready or Not

**Flip Ready or Not around. You and your friends are the suspects. An armoured SWAT team breaches the building to
take you down.** Dig in during the setup phase, grab a human shield, protect your VIP, and wipe out the team.

It works in Steam co-op, and it plugs into the game's own screens: the normal loadout offers suspect weapons, your
character preview is a suspect you can customise, and the van intro shows your crew as suspects.

> **Status: v0.12.3.** Tested solo on the Gas Station map. Co-op with two real players is built but not fully tested.
> Built with AI (Claude Code). Unofficial; not affiliated with VOID Interactive.

---

## Quick start

1. Download the newest `SuspectMode_v*.zip` from **[Releases](../../releases)**.
2. Unzip it and double-click **`install.bat`** (every player).
3. Launch Ready or Not and play co-op as usual. Press **F8** in game for the menu.

Uninstall: run `uninstall.bat`. Problems: see **[Troubleshooting](docs/TROUBLESHOOTING.md)**.

## Documentation

| Read this | If you want to |
|---|---|
| **[Player guide](docs/PLAYER_GUIDE.md)** | Install it, learn the controls, understand every feature |
| **[Settings](docs/SETTINGS.md)** | Know what every setting and preset does |
| **[Troubleshooting](docs/TROUBLESHOOTING.md)** | Fix a crash or something that doesn't work, find the logs |
| **[Changelog](CHANGELOG.md)** | See what changed in each version |
| **[How it works](docs/ARCHITECTURE.md)** | Understand the mod's design and code |
| **[Handoff](docs/HANDOFF.md)** | Continue development (dev setup, test loop, what's verified) |
| **[Engine notes](docs/ENGINE_NOTES.md)** | Look up Ready or Not classes and fields the mod uses |
| **[Roadmap](docs/ROADMAP.md)** | See what's planned |

## Features

| | |
|---|---|
| **You are the suspects** | Suspect outfits for you and your friends, a suspect crew in the van intro, "SUSPECTS" on the pre-mission screen |
| **Character look** | In the normal loadout screen: pick body, head and gear (armour/helmet) with a live preview, synced to friends |
| **Suspect arsenal** | The loadout offers the suspect-only guns the game ships (AK-102/103, FAL, G3A3, M14, MPL, Saiga-12, 1911s...) and real frag grenades. Police less-lethal gear is removed |
| **Armoured SWAT enemy** | Uniform, masked helmet, plate carrier, SWAT voices. Team size scales with players (6 + 2 per player) |
| **Rounds** | Setup phase (you can't be hurt), breach with a short grace, SWAT hunt you, eliminate them to win. Also timer and kill-count modes |
| **Human shield** | Equip your ballistic shield next to a civilian: they stand in front of you, hands up, and SWAT hold fire for 20 s |
| **Protect the VIP** | A civilian becomes the VIP; SWAT hunt them too, you lose if they die |
| **Balance** | You take less damage, stuns are short, SWAT aim is adjustable. Presets: standard, easy, hardcore, survival, custom |
| **No police stuff** | No reporting to TOC, no SWAT objectives, no flashbangs |
| **In-game menu** | F8 opens a menu in the game's own style to change everything, for the host and the friend |

## Controls

| Key | What it does |
|---|---|
| **F8** | Open / close the Suspect Mode menu |
| **Arrow keys** | Navigate the menu, or the CHARACTER LOOK panel in the loadout screen |
| **F7** (host) | Turn the mode on / off |
| **F9 / F10 / F11** | Change body / head / gear in a mission (Shift = previous) |
| **Ballistic shield** next to a civilian | Human shield |

## Requirements

- Ready or Not on Steam (PC), the same game version for every player.
- Every player installs the same Suspect Mode version.
- The game has no anti-cheat, and the developers support mods; still, only play modded with friends who also run the mod.

## Repository layout

```
mod/RonSuspect/Scripts/   main.lua (the mod), config.lua (default settings)
installer/                install.bat, uninstall.bat, README.txt (go into the release zip)
tools/build_dist.sh       builds the release zip (UE4SS + mod + installer)
dev/                      dev-only tools: Lua bridge into the live game, screenshots, recon scripts
docs/                     player guide, settings, troubleshooting, architecture, handoff, engine notes, roadmap
```

## Credits

- [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) (MIT): the mod loader, bundled in the release zip.
- Ready or Not belongs to VOID Interactive. This repository contains no game files, extracted assets or decompiled code.
  All weapons, outfits and animations used are the game's own, loaded from your installed copy.
- Built with Claude Code.
