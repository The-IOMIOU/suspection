# Changelog

Download any version from the [Releases page](../../releases). Every player installs the same version.

## v0.12.2 - Station hub crash fix
- Fixes a crash in the police station hub: the mod force-loaded suspect outfit assets there (the log showed 5 loads, then
  the crash). Outfit assets now load only on the loadout screen and in the pre-mission van, never in the hub or a mission.
- Every asset is loaded at most once per session, and each load is logged as `[SuspectMode] loading <asset> (map <map>)`,
  so a future crash log shows exactly what was loaded.
- The log line shows the exact version (`v0.12.2 loaded`).

## v0.12.1 - Crash hardening + documentation
- **Main-menu safe mode:** at the main menu the mod only prepares the loadout lists and the F8 menu; it no longer touches
  the menu scene (a friend's game crashed ~5 s into the main menu on v0.12, with no error in the log).
- `install.bat` removes dev-only files that a copied folder may bring (RonBridge), and backs up an existing `dwmapi.dll`.
- New docs: player guide, settings reference, troubleshooting, architecture, changelog. README rewritten.

## v0.12 - Character look + van intro
- The normal loadout screen's preview is your suspect, with a **CHARACTER LOOK** panel (body, head, gear) that changes it live.
- The pre-mission van intro shows your crew as suspects instead of the SWAT squad.
- Players and mannequins are dressed with follower meshes. Fixes the "invisible body with floating armour" bug.

## v0.11 - Suspect weapons only
- New menu setting **Suspect weapons only** (on by default): the loadout offers only suspect guns. Off = vanilla guns too.
- Menu changes made outside a match are saved locally.

## v0.10 - Suspect loadout
- The vanilla loadout screen offers 20 suspect-only weapons (AKs, FAL, G3A3, M14, MPL, Saiga-12, 1911s...) and real frag grenades.
- Police less-lethal gear removed (flashbangs, stingers, CS, 9-Banger, launchers, pepper spray, Taser).
- F8 menu restyled like the game's own UI. The pre-mission screen says SUSPECTS.
- The release zip is pinned to the tested UE4SS build.

## v0.9 - On-screen menu
- F8 opens an on-screen settings menu (arrows to navigate). The police station hub no longer starts the mode.

## v0.8 - Settings in chat, armoured SWAT
- `!set`, `!preset`, `!menu` chat commands, saved by the host in `settings.txt`.
- Enemies wear a plate carrier and helmet. The AI squad is fully removed. Win as soon as the SWAT team is down.

## v0.7 - Human shield, no reporting
- Equip the ballistic shield next to a civilian to hold them as a human shield (upright, hands up). SWAT hold fire.
- Map SWAT objectives hidden. Crash fixes.

## v0.6 - Hostages and VIP
- First human shield (F6), AI suspect helpers (now disabled), protect-the-VIP rule, host command channel.

## v0.5 - Look editor, no reporting
- F9/F10/F11 look editor synced to friends. No "Report" prompts.

## v0.4 - Presets
- Presets (standard / easy / hardcore / survival / custom), "eliminate the team" main mode, SWAT voices, enemy aim
  slider, players dressed as suspects.

## v0.3 - Enemies look like SWAT
- Every enemy dressed in SWAT uniform and masked head. Breach grace period.

## v0.2 - Enemies that shoot
- Enemies are the game's suspect AI (the SWAT AI never shoots players). Waves, moved start, win/lose.

## v0.1 - First slice
- Team swap, setup timer, win modes, tougher players, chat HUD, installer.
