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

* **Faster Movement:** All characters move faster across the board — walking, sprinting, and crouching. Lighter characters stay nimble and heavier characters stay tanky, but everyone gets a substantial speed boost.

* **Snappy Ballistic Jumps:** Replaces the floaty "moon gravity" feel with a tight, snappy jump arc. Jumping while sprinting preserves 100% of your forward momentum through the air instead of slowing you down mid-jump.

* **Double Jump:** All characters can double jump to clear tall obstacles, gaps, and ledges. Both first and double jumps cost zero stamina.

* **No Landing Stuns:** Touchdowns after big jumps or drops no longer freeze your character in place with a landing recovery animation. You land running and keep your momentum fluid.

* **No Damage Stagger (Anti-Stunlock):** Getting shot by enemy bullets or mechs no longer locks your character in flinch animations or stops you from shooting back. You still take full damage, but you can keep running, jumping, and fighting without getting stunned to death.

* **Smart Stamina System:** Stamina only drains while actively sprinting on the ground. Walking, jumping, and being airborne are 100% free. If you completely run out of stamina, you walk until it fully refills, then cleanly regain sprint and double-jump without stuttering.

* **Adrenal Surge (Clutch Escape):** When your health drops below 30%, you get an automatic 8-second speed burst with 80% reduced stamina drain to help you escape or reposition. It automatically re-arms once your health recovers above 60%.

* **Skill Tree & Rig Compatible:** Any speed, stamina, or gear upgrades you unlock in the character skill tree stack directly on top of the mod's buffs.

---

## Spot The Difference (Vanilla vs MovementSpecialist)

| Feature / Mechanic | Base Game (Vanilla) | MovementSpecialist (Modded) |
|---|---|---|
| **Jump Count** | Single jump only | **Double jump** enabled on all characters |
| **Jump Stamina Cost** | Costs 15 stamina per jump | **0 stamina** (Both first and double jumps are completely free) |
| **Damage Stagger & Flinch** | Enemy bullets stagger you, freeze movement & lock weapon fire | **Stagger immunity** (Take full damage, but keep running and shooting) |
| **Landing & Impact Stuns** | Hard landings lock controls for up to 0.75s | **Stun-breaking** (Landing recovery animations cancelled for smooth momentum) |
| **Adrenal Surge (< 30% HP)** | None | **8-second burst:** speed boost + 80% stamina cost reduction (re-arms > 60% HP) |
| **Air Control & Drag** | Floaty hang time with heavy mid-air friction | **Snappy ballistic arc** with zero mid-air friction (momentum preserved) |
| **Skill Tree Scaling** | Standard perks | **All speed & stamina upgrades** compound directly on top of mod buffs |


---

## Character Breakdown

Rather than making every character move at the exact same flat speed, each character receives tailored buffs that amplify their native role:

| Character | Walk Speed<br>*(Vanilla → Mod)* | Sprint Speed<br>*(Vanilla → Mod)* | Crouch Speed<br>*(Vanilla → Mod)* | Hub Jog<br>*(Vanilla → Mod)* | Jump Height<br>*(Vanilla → Mod)* | Stamina Tank |
|---|---|---|---|---|---|---|
| **Scav Girl** | 315 → **330** | 630 → **1040** | 160 → **255** | 315 → **530** | 600 → **740** | 80 |
| **Shaman** | 299 → **310** | 598 → **960** | 150 → **240** | 299 → **500** | 600 → **710** | 85 |
| **Old Man** | 295 → **305** | 590 → **950** | 145 → **235** | 295 → **495** | 600 → **705** | 85 |
| **Mask Man** | 299 → **310** | 598 → **940** | 150 → **240** | 299 → **500** | 600 → **700** | 75 |
| **Gunhead** | 290 → **300** | 580 → **930** | 145 → **230** | 290 → **490** | 600 → **700** | 90 |
| **Bag Man** | 275 → **285** | 550 → **870** | 140 → **220** | 275 → **450** | 600 → **680** | 105 |

