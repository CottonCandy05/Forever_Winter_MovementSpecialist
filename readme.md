# MovementSpecialist — The Forever Winter

Movement, stamina and stagger overhaul for The Forever Winter. Works on all playable characters.

---

## Requirements

1. **Signature Bypass** — [Download from Nexus](https://www.nexusmods.com/theforeverwinter/mods/57)
2. **UE4SS v3.0.1** — [Download from GitHub](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest)

---

## Installation

1. Extract **Signature Bypass** into:
   `\The Forever Winter\Windows\ForeverWinter\Binaries\Win64\`
2. Extract **UE4SS** into:
   `\The Forever Winter\Windows\ForeverWinter\Binaries\Win64\`
3. Copy the **MovementSpecialist** folder into:
   `\The Forever Winter\Windows\ForeverWinter\Binaries\Win64\ue4ss\Mods\`
4. Enable in UE4SS `mods.txt` by adding:
   ```
   MovementSpecialist : 1
   ```
5. Enable in UE4SS `mods.json` by adding:
   ```json
   {
     "mod_name": "MovementSpecialist",
     "mod_enabled": true
   },
   ```

Done.

---

## Disable

In `mods.txt` change:

```
MovementSpecialist : 0
```

In `mods.json` change:

```json
{
  "mod_name": "MovementSpecialist",
  "mod_enabled": false
},
```

---

## Uninstall

1. Remove the **MovementSpecialist** folder from `ue4ss\Mods\`
2. In `mods.txt` remove:
   ```
   MovementSpecialist : 1
   ```
3. In `mods.json` remove:
   ```json
   {
     "mod_name": "MovementSpecialist",
     "mod_enabled": true
   },
   ```

---

## Usage

* Press **M** to toggle the mod on/off at any time, even while moving. When off, the game plays exactly as the developers intended with zero changes.

---

## What This Mod Does

**Faster Movement**
Every character gets buffed walk speed, sprint speed, crouch speed and hub jog speed. Characters keep their unique feel — lighter characters are still faster, heavier characters are still slower — but everyone moves noticeably quicker than vanilla.

**Overhauled Sprint**
Sprinting is significantly faster. Sprint also works inside the Innards hub now at a comfortable jog speed instead of forcing you to walk everywhere.

**Double Jump**
All characters can double jump. Jumping costs zero stamina so you're free to jump as much as you want.

**Better Stamina**
Stamina drain and recovery uses the game's own regen rate so skill tree upgrades still apply. Jump and sprint stamina costs from the base game are removed — the mod handles its own drain system. If you fully deplete stamina you'll be locked to walking until it fully recovers.

**Adrenal Surge**
When your health drops below 30%, you get a temporary speed burst and 80% reduced stamina drain for a few seconds. Automatically re-arms once your health goes above 60%.

**No Damage Stagger**
Getting shot no longer locks you in place. You still take full damage but your character won't freeze in a hit reaction animation, so you can always keep moving.

**Scales With Skill Tree**
Any movement speed or stamina upgrades you unlock in the skill tree still work and stack with the mod's buffs.

---

## Supported Characters

| Character | Sprint Speed | Stamina Pool | Feel |
|-----------|-------------|-------------|------|
| Shaman | 960 | 85 | Balanced all-rounder |
| Scav Girl | 1040 | 80 | Fast and agile |
| Old Man | 950 | 85 | Steady and reliable |
| Bag Man | 870 | 105 | Slow but tanky |
| Mask Man | 940 | 75 | Lean and precise |
| Gunhead | 930 | 90 | Solid and heavy |

Every character keeps their identity. Nobody becomes the same.

---

## Keybinds

| Key | Action |
|-----|--------|
| **M** | Toggle mod on/off (works even while moving) |

That's it. No other keybinds.
