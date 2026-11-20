# Player guide

Everything you need to install Suspect Mode, play it with a friend, and understand what each feature does.
If something goes wrong, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md). Every setting is listed in [SETTINGS.md](SETTINGS.md).

---

## 1. What Suspect Mode is

Ready or Not normally puts you in a SWAT team clearing a building full of suspects. **Suspect Mode flips it.**
You and your friends are the suspects. You get time to dig in, then an armoured SWAT team breaches the
building and comes for you. You win by wiping out the team (or by surviving, depending on the mode).

It is a mod for the PC (Steam) version of Ready or Not. It runs through **UE4SS**, a free mod loader for
Unreal Engine games, which is bundled in the download. It does not touch your save files, and it is removed
completely by `uninstall.bat`.

---

## 2. Installing

Every player in the group installs the **same version**.

1. Go to the [Releases page](../../../releases) and download the newest `SuspectMode_v*.zip`.
2. Unzip it anywhere (your Downloads folder is fine).
3. Double-click **`install.bat`**.
   - It looks for the game in the default Steam folder.
   - If it can't find it, it asks you to paste the game folder. In Steam: right-click **Ready or Not** →
     **Manage** → **Browse local files**, copy the address of the window that opens, and paste it.
4. Launch Ready or Not from Steam as usual.

The installer copies two things into `Ready Or Not\ReadyOrNot\Binaries\Win64\`:

| What | Why |
|---|---|
| `dwmapi.dll` | Starts UE4SS when the game starts |
| `ue4ss\` folder | UE4SS itself, plus `ue4ss\Mods\RonSuspect\` (this mod) |

**Updating:** download the new zip and run `install.bat` again. Your saved settings and look are kept.

**Uninstalling:** run `uninstall.bat` (or delete `dwmapi.dll` and the `ue4ss` folder from `Win64`).
The game is then exactly vanilla again.

---

## 3. Playing with a friend

1. Both players install the same version.
2. One player hosts a co-op game as normal through Steam; the other joins.
3. **The host's game runs the mode.** The host's settings decide the rules (team size, timers, aim...).
   Your friend can still change settings from the menu: the change is sent to the host.
4. Your look (what suspect you are dressed as) is sent to the other players automatically.

> Co-op has been built for but not yet fully tested with two real players. If something looks different on
> your friend's screen, please report it (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)).

---

## 4. A round, step by step

1. **Pick your gear.** The normal loadout screen now offers suspect weapons and lets you pick your suspect look
   (see section 6).
2. **The van.** The pre-mission van shows your crew as suspects; the screen says "SUSPECTS 1/1 READY".
3. **Setup phase** (60 s by default). You're moved away from the SWAT entry point. During setup you can't be
   hurt and SWAT can't see you. Use it to take position, grab a hostage, pick a room to defend.
   Chat counts down: `Setup time: 0:45`.
4. **Breach.** `SWAT IS BREACHING! 10 operators inbound.` An armoured SWAT team (6 + 2 per player by default)
   enters. For the first 10 seconds they are still blind (breach grace), so nobody dies instantly.
5. **The fight.** SWAT get told where you are every 30 s, so they keep hunting you. Chat shows `SWAT left: 7`.
6. **The end.**
   - `SUSPECTS WIN - entire SWAT element neutralised`: you killed (or they surrendered) the whole team.
   - `SWAT WINS - all suspects are down`: every player is down.
   - `SWAT WINS - the VIP was killed`: if the VIP rule is on and the VIP died.

---

## 5. Controls

| Key | Who | What it does |
|---|---|---|
| **F8** | anyone | Open / close the **Suspect Mode menu** (all settings) |
| **Up / Down** | anyone | In the menu or the look panel: pick a row |
| **Left / Right** | anyone | In the menu or the look panel: change the value |
| **F7** | host | Turn the whole mode on / off (restarts the setup timer) |
| **F9** / **Shift+F9** | anyone | Next / previous suspect body (works in a mission) |
| **F10** / **Shift+F10** | anyone | Next / previous suspect head |
| **F11** | anyone | Cycle gear: none, armour, helmet, armour + helmet |
| **Ballistic shield slot** | anyone | Next to a civilian: grab them as a human shield (section 7) |

Chat commands also work (type them in the in-game chat): `!menu`, `!set EnemyAccuracy 0.4`, `!preset hardcore`.

---

## 6. The loadout screen

The game's own loadout screen is used, but with suspect content.

**Weapons.** With **Suspect weapons only** ON (default), the weapon lists hold only suspect guns:

| Slot | Weapons |
|---|---|
| Primary | AK-102, AK-103, AR-18, FAL, G3A3, M14, M16A4, M4A1, M76, MPL (SMG), Saiga-12, 870, TAC-700 (sniper), VKS |
| Sidearm | M1911, M2011, M92FS, P250, P99 |
| Tactical | **Frag grenades** (real ones), C2, lockpick gun, door jam |
| Long tactical | Ballistic shields (needed for the human shield), battering ram, breaching shotgun, mirror gun |

Police less-lethal gear is removed: flashbangs, stingers, CS gas, 9-Banger, M320/M32 launchers, pepper spray,
Taser. Turn **Suspect weapons only** OFF in the F8 menu to get all the normal guns back as well.

**Character look.** The 3D preview shows your suspect, and a **CHARACTER LOOK** panel sits on the right:

| Row | What it changes |
|---|---|
| BODY | Which suspect outfit you wear (hoodies, jackets, street clothes...) |
| HEAD | Which head, can be mixed with any body |
| GEAR | None, armour, helmet, or armour + helmet on top |

Up/Down picks a row, Left/Right changes it, and the preview updates live. Your choice is saved (`mylook.txt`)
and sent to the other players.

> The list of looks grows as you play: the mod remembers every suspect it has seen (`looks.txt`).
> A fresh install starts empty; play one mission with suspects and the looks appear.

---

## 7. Human shield

Equip your **ballistic shield** while standing within 3 m of a civilian. Instead of the shield, you grab the
civilian: they stand up in front of you with their hands up, glued to you as you move, and the shield itself is
hidden.

- While you hold them, **SWAT hold fire** for up to 20 seconds.
- Switch to any other weapon to let them go. After 20 s they slip away on their own.
- Then you wait 30 s before you can grab someone again (so it's a tactic, not god mode).
- Seated / scripted civilians can't be grabbed; the mod picks the nearest one who is standing.
- With no civilian nearby, the shield is just a normal shield.

---

## 8. The VIP

At the breach, the civilian nearest to you becomes **the VIP** (chat tells you how far away they are).
SWAT will hunt the VIP too. If the VIP dies, SWAT win. Turn it off with **Protect a VIP** in the menu.

---

## 9. What's different from vanilla

| Vanilla | Suspect Mode |
|---|---|
| You are SWAT | You are suspects (look, loadout, van intro, "SUSPECTS" on screen) |
| AI squad follows you | No AI squad |
| Suspects attack you | An armoured SWAT team attacks you (SWAT uniform, plate carrier, helmet, SWAT voices) |
| Report bodies / arrests to TOC | No reporting at all, SWAT objectives hidden |
| Flashbangs and less-lethal | Frags and real guns |
| Normal health | You are tougher (damage divided by 2.5 by default), stuns are short |

---

## 10. Known limits

- The station hub's own character customization stand still shows SWAT uniforms; use the loadout screen.
- Looks only come from suspects you have met on maps you played.
- The "SWAT" enemies are the game's suspect AI dressed as SWAT (the real SWAT AI refuses to shoot players).
  They fight like armed suspects, not like a coordinated SWAT stack.
- Co-op with two real players is not fully tested yet.
