# Troubleshooting

## First: how to tell what's wrong

Two files tell almost everything. When you report a problem, send both.

| File | Where |
|---|---|
| **`UE4SS.log`** | `Ready Or Not\ReadyOrNot\Binaries\Win64\ue4ss\UE4SS.log` (Steam: right-click Ready or Not, Manage, Browse local files) |
| **Crash report** | The newest folder in `%LOCALAPPDATA%\ReadyOrNot\Saved\Crashes\` (paste that path in the Explorer address bar). The useful file is `CrashContext.runtime-xml` |

In `UE4SS.log`, the mod's own lines start with `[SuspectMode]`. A healthy start contains
`[SuspectMode] v0.12 loaded` (the version number) and, at the main menu, `loadout: suspect weapons only (...)`.

---

## The game crashes when it starts

This is almost always the **mod loader (UE4SS)** failing on that PC, not the Suspect Mode script.

0. **Install from the release zip, don't copy someone's folder.** A copied `ue4ss` folder brings the copier's dev tools,
   saved looks and settings. In the log that shows as `Starting Lua mod 'RonBridge'`, which is not part of the release.
   Run `uninstall.bat`, then `install.bat` from the newest release zip (v0.12.1+ also removes leftover dev files).
   Since v0.12.1 the mod leaves the main menu scene alone (log line `main menu: scene untouched (safe mode)`); a friend's
   game crashed about 5 s into the main menu on v0.12.
1. **Check it really is the mod.** In `...\Binaries\Win64\`, rename `dwmapi.dll` to `dwmapi.dll.off` and launch.
   - Game starts: the loader is the problem, keep reading.
   - Still crashes: it's not the mod. Verify the game files in Steam (Properties, Installed Files, Verify integrity).
2. **Another mod using the same file.** ReShade, some FPS tools and other mod loaders also install a
   `dwmapi.dll`. The installer overwrites it. Remove the other tool or tell us which one it is.
3. **Game version.** UE4SS finds the game's internals by scanning the exe. A different game build (a beta branch, an
   update newer than the mod) can break that. In Steam, Properties, Betas: make sure it's "None".
   Both players should be on the same game version.
4. **Antivirus.** Some antivirus tools block `dwmapi.dll` / `UE4SS.dll`. Check the quarantine and add an exception for
   the `Win64` folder.
5. **Overlays.** If it still crashes, try with the Discord / GeForce / MSI Afterburner overlays turned off.
6. **Send the two files** from the top of this page.

To play without the mod meanwhile, run `uninstall.bat` (or keep `dwmapi.dll` renamed).

## The game crashes in the station hub or during a mission

Check the last `[SuspectMode] loading ...` lines in `UE4SS.log` right before the end: they name the asset and the map.
v0.12.2 never loads assets in the hub or during a mission (a crash in the hub came right after 5 forced loads in v0.12.1).

## (older) The game crashes during a mission

Send the two files. Note what you were doing (setup phase, after the breach, opening the loadout...). The mod
avoids loading assets mid-mission because that crashed in testing, but other causes are possible.

## Nothing happens / it plays like normal Ready or Not

- `UE4SS.log` has no `[SuspectMode]` lines: the mod isn't installed in the right folder. Re-run `install.bat` and give it
  the folder that contains `ReadyOrNot` (the one Steam's "Browse local files" opens).
- `[SuspectMode] ... loaded` is there but nothing happens: check `Enabled` in the F8 menu, or press F7 (host).
- The police station hub is not a mission. The mode starts when a real mission starts.

## My friend sees something different from me

- Both players must run the **same version** (compare `[SuspectMode] v... loaded` in both logs).
- Rules come from the **host**. A client's own `config.lua` doesn't change the rules.
- Looks are synced through a `#look` chat line, re-sent every minute. A late joiner sees your look within a minute.

## The look panel says "No suspect looks yet" / the lists are short

Looks are collected from suspects the mod sees in missions (`looks.txt`). Play one mission on a map with suspects;
the looks appear after that. Each map adds its own.

## The F8 menu doesn't open

- The menu needs a running player controller: press F8 again after the main menu has fully loaded.
- Check `UE4SS.log` for `menu error`.

## Reset everything

Delete `settings.txt`, `looks.txt` and `mylook.txt` in `...\ue4ss\Mods\RonSuspect\Scripts\`. Re-run `install.bat`
to restore `config.lua`.

## Remove the mod completely

Run `uninstall.bat`, or delete `dwmapi.dll` and the `ue4ss` folder from `...\Binaries\Win64\`. Nothing else on your
PC is changed. Your game saves are never touched.
