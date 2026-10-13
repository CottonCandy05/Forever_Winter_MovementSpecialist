# MovementSpecialist — The Forever Winter

Movement, stamina and stagger overhaul for The Forever Winter. Works on all playable characters.

---

## Requirements

1. **UE4SS v3.0.1** — [Download from GitHub](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest)

---

## Installation

1. Make sure **UE4SS** is installed and working.
2. Copy the **MovementSpecialist** folder into:
   `\The Forever Winter\Windows\ForeverWinter\Binaries\Win64\ue4ss\Mods\`

Done. The mod auto-enables itself.

---

## Uninstall

Remove the **MovementSpecialist** folder from `ue4ss\Mods\`

---

## Keybind

| Key | Action |
|-----|--------|
| **M** | Toggle mod on/off |

You can press M anytime, even while running. You don't need to stop moving. When the mod is off, the game plays exactly as the developers intended with zero changes.

---

## What This Mod Changes

**Faster Movement**
All characters move faster — walking, sprinting, crouching, everything. Each character still feels different from the others, heavier characters are still slower, lighter ones still quicker, but everyone gets the same proportional buff.

**Sprint In The Innards Hub**
You can now sprint inside the Innards at a comfortable jog speed instead of being forced to walk everywhere.

**Double Jump**
Every character can double jump. Jumping costs zero stamina.

**Stamina**
The mod runs its own stamina system. Stamina only drains while actively sprinting on the ground — walking, jumping, and being in the air are all free. Regen speed matches whatever the game gives you so your skill tree upgrades still count. If you fully run out of stamina, you'll be locked to walking until it fully refills.

**Adrenal Surge**
When your health drops below 30%, you get a temporary speed burst with massively reduced stamina drain for a few seconds. It automatically re-arms once your health recovers above 60%.

**No Damage Stagger**
Getting shot no longer freezes your character in place. You still take full damage but you can keep moving through it instead of getting stun-locked to death by bullet spam.

**Skill Tree Compatible**
Any speed or stamina upgrades you unlock in the skill tree still work and stack with the mod.

---

## Spot The Difference (Vanilla vs MovementSpecialist)

| Feature / Mechanic | Base Game (Vanilla) | MovementSpecialist (Modded) |
|---|---|---|
| **Jump Count** | Single jump only | **Double jump** enabled on all characters |
| **Jump Stamina Cost** | Costs 15 stamina per jump | **0 stamina** (Both first and double jumps are completely free) |
| **Airborne Traversal** | Stamina drains mid-air while jumping or falling | **Paused mid-air** (Only ground sprinting drains stamina) |
| **Innards Hub Sprint** | Disabled (Forced to walk everywhere) | **Full sprint enabled** at a brisk, comfortable jog pace |
| **Damage Stagger & Flinch** | Enemy bullets stagger you, freeze movement & lock weapon fire | **Stagger immunity** (Take full damage, but keep running and shooting) |
| **Landing & Impact Stuns** | Hard landings lock controls for up to 0.75s | **Stun-breaking** (Landing recovery animations cancelled for smooth momentum) |
| **Exhaustion State** | Micro-stagger stutter loop (stops, gains a sliver, stumbles again) | **Clean walk gate** until stamina hits 100%, then cleanly unlocks sprint |
| **Adrenal Surge (< 30% HP)** | None | **8-second burst:** speed boost + 80% stamina cost reduction (re-arms > 60% HP) |
| **Air Control & Drag** | Floaty hang time with heavy mid-air friction | **Snappy ballistic arc** with zero mid-air friction (momentum preserved) |
| **Skill Tree Scaling** | Standard perks | **All speed & stamina upgrades** compound directly on top of mod buffs |
| **In-Game Toggle** | None | Press **M** to seamlessly toggle mod on/off anytime on the fly |

---

## Character Breakdown

Rather than making every character move at the exact same flat speed, each character receives tailored buffs that amplify their native role:

| Character | Role & Feel | Walk Speed | Sprint Speed | Crouch Speed | Hub Jog | Jump Height | Stamina Tank |
|---|---|---|---|---|---|---|---|
| **Scav Girl** | Agile Scout (Fastest & lightest) | 330 | 1040 | 255 | 530 | 740 | 80 |
| **Shaman** | Combat Veteran (Balanced benchmark) | 310 | 960 | 240 | 500 | 710 | 85 |
| **Old Man** | Tactical Marksman (Steady & dependable) | 305 | 950 | 235 | 495 | 705 | 85 |
| **Mask Man** | Sharpshooter (Lean & precise) | 310 | 940 | 240 | 500 | 700 | 75 |
| **Gunhead** | Heavy Gunner (Durable & solid) | 300 | 930 | 230 | 490 | 700 | 90 |
| **Bag Man** | Heavy Hauler (Slowest pace, massive stamina & carry) | 285 | 870 | 220 | 450 | 680 | 105 |

