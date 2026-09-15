# Game Formula Reference

Reviewed against the working tree on **2026-09-14**. This book inventories the
current game's numerical rules, their inputs, rounding, owners and editing
consequences. It covers progression, skills/perks, combat, NPC rewards,
recovery, injuries, movement, inventory, trade and configured transport. It also
identifies calculations that exist in code but are not active gameplay.

Use [NPC.md](NPC.md) for creatures, groups, cells, equipment and drops,
[ITEMS.md](ITEMS.md) for item definitions/effects and
[WORLD.md](WORLD.md) for geography, routes and cell actions.
[COMBAT.md](COMBAT.md) explains how fight inputs and calculations connect through
the complete player/NPC lifecycle; [SCROLLS.md](SCROLLS.md) explains scroll
admission, activation and permissions. Keep their numerical summaries/examples
synchronized with changed formulas here. The
[documentation architecture](DOCUMENTATION.md) defines ownership: this is a
cross-domain reference, while detailed design, evidence and runtime acceptance
remain in their canonical documents. In particular,
[combat calibration](design/features/combat_calibration.md) owns the rationale
and tolerances for the user-authorized fitted model after 10+10+2 fights.

Before changing an existing or adding a new calculation, follow the
[context/update map](DOCUMENTATION.md#21-required-context-and-update-map) and
the affected feature handbook linked from its section below. A formula's
consumers determine which NPC/item/location entries also need updating.

## Contents

- [1. Reading and editing formulas](#1-reading-and-editing-formulas)
- [2. Experience levels and grants](#2-experience-levels-and-grants)
- [3. Character stats and equipment](#3-character-stats-and-equipment)
- [4. Skills, perks and abilities](#4-skills-perks-and-abilities)
- [5. Combat](#5-combat)
- [6. Experience, loot and premium](#6-experience-loot-and-premium)
- [7. Recovery, wear and injuries](#7-recovery-wear-and-injuries)
- [8. World movement and encounter timing](#8-world-movement-and-encounter-timing)
- [9. Inventory and economy](#9-inventory-and-economy)
- [10. Transport](#10-transport)
- [11. Compatibility and absent formulas](#11-compatibility-and-absent-formulas)
- [12. Change impact, verification and maintenance](#12-change-impact-verification-and-maintenance)
- [Use cases and cross-feature effects](#use-cases-and-cross-feature-effects)

## 1. Reading and editing formulas

**Captured** values come from preserved Neverlands UI/wiki/script evidence.
**Calibrated** equations are pragmatic local fits authorized by the user; they
are not recovered Neverlands source code. **Authored** values are explicit
content/configuration policy. **Compatibility** identifies code that must not
be advertised as an active mechanic without a caller. Most sections combine
captured inputs with calibrated effects; provenance is stated at that boundary.

Notation: `floor`, `round`, `min`, `max` and `clamp(x,low,high)` mean exactly
those operations. A percentage rating such as Accuracy 440 is not automatically
a 440% probability. HP, MP, AP, XP and learned skill levels are distinct units.
Timers use seconds unless specified; NV uses decimal currency arithmetic.
`rand(a..b)` is an inclusive integer draw; `rand(n)` is `0..n-1`.

The server supplies authoritative records, time and randomness. Formula changes
belong in the existing pure calculator or cohesive domain owner, with record
adapters supplying inputs. Do not copy arithmetic into ERB/Stimulus, add a
parallel NPC/PvP pipeline, or turn a displayed rounded number back into an input.

| What to tune | Primary owner | Important consumers |
|---|---|---|
| Level costs, grants, XP caps | [character_progression.yml](../config/gameplay/character_progression.yml) | Progression, allocation, NPC reward ceiling |
| Learned skill growth | [PassiveSkillRegistry](../app/lib/game/skills/passive_skill_registry.rb), [SkillProgressionFormula](../app/lib/game/formulas/skill_progression_formula.rb) | Skills form and saved point spending |
| Primary/derived stats | [Character](../app/models/character.rb) | Profile, equipment requirements, combat, carrying capacity |
| Physical coefficients, family modifiers, XP/loot/recovery | [combat_calibration.yml](../config/gameplay/combat_calibration.yml), [Calibration](../app/lib/game/combat/calibration.rb) | Shared combat and reward/recovery owners |
| Action costs and selectors | [combat_actions.yml](../config/gameplay/combat_actions.yml), [CombatProfile](../app/services/arena/combat_profile.rb) | Preview and authoritative turn validation |
| Opposed chances and magic | [CombatResolver](../app/services/arena/combat_resolver.rb) | Every player/NPC strike |
| Premium limits | [combat_benefits.yml](../config/gameplay/combat_benefits.yml), [PremiumBenefits](../app/lib/game/combat/premium_benefits.rb) | Drop eligibility and XP cap only |
| Movement/fatigue/actions | [world_rules.yml](../config/gameplay/world_rules.yml) | Server move/action offers, fatigue, passive timing |
| NPC levels, HP, rosters, sample rewards | [outdoor_npcs.yml](../config/gameplay/outdoor_npcs.yml) and managed records | NPC inputs and encounter selection; see NPC book |
| Prices, equipment/consumable properties | ItemTemplate, InventoryItem; [starter Shop data](../db/seeds/data/starter_shop.json) | Equipment, use, purchase and resale |

## 2. Experience levels and grants

[CHARACTER](CHARACTER.md) traces the complete level-up/build flow and when saved
or effective values change; [ECONOMY](ECONOMY.md) explains the NV grant writer.

Runtime/acceptance owner: [Character Progression](features/character_progression.md).

### PROG-01 — Cumulative experience

Owners: [Catalog](../app/lib/game/progression/catalog.rb),
[LevelUpService](../app/services/players/progression/level_up_service.rb).
Provenance: captured progression table and corrected cumulative interpretation;
see [progression design](design/features/progression_stats_skills.md) and
[Character handbook](features/character_progression.md#level-grants-and-the-combat-handoff).

```text
cost[L] = row L's experience_to_next_level (incremental cost)
threshold[0] = 0
threshold[L] = sum(cost[0] ... cost[L-1])
remaining = max(threshold[current level + 1] - total XP, 0)
```

Earned XP is added to lifetime XP; leveling does not subtract it. Under the
character lock, the service loops through every supported threshold crossed
and grants each reached level's row once: primary-stat points, combat/peace
skill points, perk points and NV. The table supplies all rewards, not a fixed
number of stats per level. Unsupported next levels report no next threshold;
the current table covers **0 through 27**. A cost in row 27 does not by itself
enable level 28 without a complete row 28.

At level 17 the threshold is **25,000,000** and the next threshold is
**50,000,000**. Thus total XP 29,946,496 leaves 20,053,504 to level 18; treating
25,000,000 as the next absolute threshold would grant levels incorrectly.

### PROG-02 — Current level table

Each row's grants are received **on reaching that level**; level-zero setup is
a separate initial seed/allocation concern. `cost` is the cost to the next
level. `cap` is standard maximum XP per fight, not guaranteed XP. `NPC max`
is the captured group-capacity value stored in the table: **the current
encounter selector does not enforce it by player level**; authored rosters have
their separate 1–10 member validation.

| Level | XP cost | Stats | Combat | Peace | Perks | NV | Fight cap | NPC max (data only) |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 100 | 15 | 10 | 2 | 1 | 0 | 50 | 1 |
| 1 | 200 | 3 | 4 | 3 | 1 | 50 | 50 | 1 |
| 2 | 500 | 3 | 5 | 4 | 0 | 100 | 100 | 1 |
| 3 | 1000 | 3 | 5 | 4 | 0 | 150 | 100 | 1 |
| 4 | 1700 | 5 | 4 | 5 | 1 | 200 | 100 | 2 |
| 5 | 2000 | 5 | 5 | 5 | 0 | 300 | 200 | 2 |
| 6 | 4500 | 5 | 6 | 6 | 0 | 350 | 200 | 3 |
| 7 | 8000 | 10 | 6 | 7 | 0 | 250 | 500 | 3 |
| 8 | 12000 | 5 | 7 | 8 | 1 | 300 | 500 | 3 |
| 9 | 20000 | 7 | 8 | 9 | 0 | 400 | 1000 | 3 |
| 10 | 150000 | 15 | 10 | 12 | 1 | 500 | 2500 | 4 |
| 11 | 300000 | 7 | 5 | 5 | 0 | 400 | 5000 | 4 |
| 12 | 400000 | 12 | 10 | 15 | 1 | 500 | 10000 | 5 |
| 13 | 700000 | 10 | 15 | 15 | 1 | 600 | 20000 | 5 |
| 14 | 1400000 | 12 | 15 | 20 | 0 | 600 | 30000 | 6 |
| 15 | 7000000 | 15 | 15 | 12 | 1 | 800 | 50000 | 6 |
| 16 | 15000000 | 15 | 20 | 15 | 0 | 1000 | 75000 | 8 |
| 17 | 25000000 | 15 | 20 | 25 | 0 | 1500 | 100000 | 8 |
| 18 | 30000000 | 15 | 20 | 25 | 1 | 2000 | 100000 | 10 |
| 19 | 80000000 | 15 | 20 | 25 | 0 | 2500 | 100000 | 10 |
| 20 | 240000000 | 10 | 10 | 15 | 0 | 1000 | 100000 | 10 |
| 21 | 600000000 | 20 | 20 | 25 | 1 | 5000 | 125000 | 10 |
| 22 | 1500000000 | 15 | 15 | 20 | 0 | 10000 | 150000 | 10 |
| 23 | 3000000000 | 25 | 20 | 15 | 0 | 25000 | 150000 | 10 |
| 24 | 4500000000 | 20 | 20 | 25 | 1 | 50000 | 170000 | 10 |
| 25 | 6000000000 | 20 | 20 | 25 | 1 | 75000 | 170000 | 10 |
| 26 | 9000000000 | 20 | 20 | 15 | 1 | 100000 | 200000 | 10 |
| 27 | 15000000000 | 20 | 20 | 15 | 1 | 125000 | 220000 | 10 |

Changing costs affects future threshold evaluation of existing lifetime XP;
it does not migrate prior grants. Changing grant rows does not retroactively
credit existing characters. Handle any intended reconciliation explicitly.

## 3. Character stats and equipment

Runtime consumers: [Character Progression](features/character_progression.md),
[Inventory](features/player_inventory.md) and [Combat](features/arena_combat.md).

### STAT-01 — Effective primary stats

Owner: [Character](../app/models/character.rb), with the existing allocation and
inventory services. Keys are Strength `strength`, Dexterity `dexterity`, Luck
`luck`, Health `vitality`, Knowledge `intelligence`.

```text
base stat = 1 + allocated points for that stat
effective stat before injury = base + equipment bonuses + applicable perk
More Strength bonus = floor(character level / 2), only when owned
P = clamp(sum(active injury penalties), 0, 90)
effective stat = max(floor(before injury * (100-P)/100), 1), when P > 0
```

Without an active penalty, the injury floor is not applied. Only Strength gets
the More Strength bonus. Equipment effect aliases are normalized centrally;
numeric strings/percent suffixes are parsed as values, not secretly applied as
multipliers. Template modifiers are merged with instance `stat_modifiers`, then
instance `effects` (later keys override), before summing distinct equipped
items. Broken items are excluded from Character's stat contributions.

### STAT-02 — Vitals, capacity and action points

Captured base conversions and AP thresholds; item bonuses are explicit content:

| Quantity | Current calculation |
|---|---|
| Saved base maximum HP | `5 * base Health` |
| Saved base maximum MP | `7 * base Knowledge` |
| Effective maximum HP | Saved max HP + equipped `hp` and `max_hp` bonuses |
| Effective maximum MP | Saved max MP + equipped `mp`, `mana`, `max_mp`; legacy nil saved maximum falls back to 50 |
| Carrying weight capacity | `5 * effective Strength + 10 * effective Health + 10 * level` |
| AP per turn | `80 + (level >= 5 ? 10 : 0) + (level >= 10 ? 10 : 0) + effective Extra Action Points` |

Base vital recalculation uses base allocated stats, not temporary equipment,
perk or injury projections. Adding effective Health/Knowledge via equipment
therefore does not automatically multiply the saved HP/MP maximum; items can
author explicit vital bonuses. Allocation recalculation clamps current vitals
down to saved maxima; it is not a free refill. AP can exceed 100 through the
skill. Mana availability and the fight profile's maximum magic selector are
separate limits.

### STAT-03 — Combat ratings and weapons

The shared [CombatAttributes adapter](../app/services/arena/combat_attributes.rb)
reads player inputs and NPC snapshots. Player armor sums equipped `defense`,
`armor`, `armor_class`; Accuracy sums `accuracy`; Evasion sums `dodge` and
`evasion`; Crushing uses `crushing`; Fortitude uses `fortitude`; Penetration
uses the supported armor-piercing aliases. These ratings feed opposed equations
below; there is no additional implicit defense per character level.

```text
weapon item damage = round((damage_min + damage_max) / 2)
W = sum(weapon item damage) + equipped flat attack/attack_power
M = matching weapon mastery; average the family masteries for two weapons
M without a weapon = effective Unarmed Combat
```

Weapon family mapping is explicit (knife, sword, axe, blunt, polearm, staff,
throwing, exotic); a name/image does not infer it. The Profile's attack power
is rounded unmitigated calibrated attack, not promised damage against a target.
Its base critical display is not the opponent-dependent critical probability.
NPC visible gear properties do not sum as player inventory does: exact NPC
stats and family coefficients supply their combat inputs; see [NPC.md](NPC.md).

## 4. Skills, perks and abilities

Runtime owner: [Character Progression](features/character_progression.md);
[Professions](features/professions.md) owns the separate absent profession loops.
The complete [SKILLS](SKILLS.md) and [PERKS](PERKS.md) books explain their
catalogs, allocation/ownership, UI, consumers, editing and worked use cases.

### SKILL-01 — Spending learned skill points

Captured source rates are in
[PassiveSkillRegistry](../app/lib/game/skills/passive_skill_registry.rb);
[SkillProgressionFormula](../app/lib/game/formulas/skill_progression_formula.rb)
and [SkillAllocationService](../app/services/characters/skill_allocation_service.rb)
own the calculation/transaction.

```text
tier = min(floor(saved skill / 25), 3)
gain from one point = min(rate[tier], 100 - saved skill)
```

Rate columns correspond to saved levels `0–24`, `25–49`, `50–74`, `75–99`.
Multiple points apply sequentially, so crossing a band changes the next gain.
Saved skills cap at 100. Effective skills add equipment bonuses without that
allocation cap; e.g. effective weapon mastery 130/150 remains meaningful.
Only saved levels determine point cost. Combat and peace pools are independent.
Undoing unsaved form choices is not a refund of previously saved allocations.

| Source ID | Key | Pool | Gain per point by band |
|---:|---|---|---|
| 0 | `unarmed_combat` | combat | 10:8:6:4 |
| 1 | `sword_mastery` | combat | 8:6:4:2 |
| 2 | `axe_mastery` | combat | 8:6:4:2 |
| 3 | `bludgeoning_mastery` | combat | 8:6:4:2 |
| 4 | `knife_mastery` | combat | 8:6:4:2 |
| 5 | `throwing_mastery` | combat | 8:6:4:2 |
| 6 | `polearm_mastery` | combat | 8:6:4:2 |
| 7 | `staff_mastery` | combat | 8:6:4:2 |
| 8 | `exotic_weapon_mastery` | combat | 6:4:4:2 |
| 9 | `two_handed_mastery` | combat | 10:8:6:4 |
| 10 | `dual_wielding` | combat | 4:4:2:2 |
| 11 | `extra_action_points` | combat | 2:2:2:2 |
| 16 | `fire_magic_resistance` | combat | 6:4:2:2 |
| 17 | `water_magic_resistance` | combat | 6:4:2:2 |
| 18 | `air_magic_resistance` | combat | 6:4:2:2 |
| 19 | `earth_magic_resistance` | combat | 6:4:2:2 |
| 20 | `physical_damage_resistance` | combat | 6:4:2:2 |
| 12 | `fire_magic` | combat | 8:6:4:2 |
| 13 | `water_magic` | combat | 8:6:4:2 |
| 14 | `air_magic` | combat | 8:6:4:2 |
| 15 | `earth_magic` | combat | 8:6:4:2 |
| 22 | `caution` | peace | 2:2:2:2 |
| 23 | `stealth` | peace | 2:2:2:2 |
| 24 | `observation` | peace | 2:2:2:2 |
| 26 | `wanderer` | peace | 2:2:2:2 |
| 27 | `linguistics` | peace | 2:2:2:2 |
| 30 | `self_healing` | peace | 2:2:2:2 |
| 33 | `fast_mana_regeneration` | peace | 2:2:2:2 |
| 34 | `leadership` | peace | 6:4:3:2 |

Active effects: weapon masteries affect attack/AP; Extra AP changes the turn
budget; physical resistance reduces damage; Observation affects loot;
Wanderer affects travel; Self-Healing and Fast Mana Regeneration affect recovery.
Two-Handed Mastery/Dual Wielding can gate item requirements but add no separate
damage coefficient; the dual-weapon AP surcharge is fixed, not skill-scaled.

The four elemental magic/resistance pairs are registered and can be allocated.
The resolver looks up skills by attack element, but current injected attacks
use `arcane` and `mind`, not fire/water/air/earth; do not promise those four
skills improve the current two spells. Caution, Stealth, Linguistics and
Leadership have no general numeric effect implemented here beyond any explicit
item requirement. No automatic skill XP per swing, dodge, travel or healing is
currently awarded.

### PERK-01 — Boolean abilities and professions

[PerkRegistry](../app/lib/game/skills/perk_registry.rb) contains four selectable
perks. Unlocking spends one available perk point; it is not a percentage or
skill-growth curve. The retained source exclusion IDs do not create unnamed
selectable perks.

| Source ID / perk | Implemented consequence |
|---|---|
| 7 — More Strength | `floor(level/2)` effective Strength |
| 15 — Careful Fighter | Halves per-item post-fight wear chance |
| 34 — Merchant | Profession/license prerequisite; selling also needs an active trading license |
| 35 — Healer | Medical prerequisite; treatment also needs an active Doctor license and suitable bag |

Trading and Doctor proficiency are profession data, not additional members of
the 29-skill allocation registry. The current game has no general profession
level-up/yield formula. Qualification, licenses, item requirements and medical
treatment have bounded implementations described below and in their handbooks.

### Source-only perk formulas

Published perk descriptions and inactive equations are indexed in
[PERKS: remaining catalog](PERKS.md#3-remaining-neverlands-catalog), with
[dated wiki provenance](design/reference/character/observations/2026-09-14_skills_and_perks.md#public-wiki-provenance).
They include other stat bonuses, lifetime HP, capacity, elemental resistance
and Nature Child's Drink variant. **None is an active local formula merely
because it is documented.** Use that catalog's flags and unresolved basis,
stacking and rounding notes before implementing a new consumer.

The [perk grant overview discrepancy](PERKS.md#grants-and-the-wiki-overview-discrepancy)
is separate from arithmetic: the wiki overview stops at24, while the preserved
experience table/current configuration also grants at25–27. Keep PROG-02
authoritative for current runtime; no grant reconciliation occurred in this
documentation task.

## 5. Combat

[Combat design](design/features/combat.md) owns the intended fight contract;
the calibration document linked above owns the fitted coefficients' rationale.

Runtime and shared Arena/PvP/PvE acceptance: [Arena Combat](features/arena_combat.md).
Update that handbook when a formula changes its combat contract.

All match types share [CombatProcessor](../app/services/arena/combat_processor.rb).
[CombatProfile](../app/services/arena/combat_profile.rb) owns budgets;
[CombatResolver](../app/services/arena/combat_resolver.rb) owns strike outcomes.
Changing these owners affects Arena, NPC, PvP and mixed teams together.

### COMBAT-01 — Physical action cost and package validation

Captured action tables plus calibrated mastery fit:

Ordinary persisted participation profiles retain their AP/cost values.
`no_weapons` rederives AP/physical costs and forces normal blocks, overriding
stale equipment profile values; [CHARACTER](CHARACTER.md#6-implementation-and-state-ownership)
explains this exception and the separately live player-stat inputs.

```text
weapon cost[i] = ItemTemplate.requirements.ap (default 45) - floor(mastery[i]/15)
unarmed cost = 45 - floor(unarmed mastery/15)
simple AP = max(round(mean(weapon costs)) + (two weapons ? 5 : 0)
                + sum(signed equipped attack-cost bonuses), 1)
aimed AP = simple AP + 20
package AP = sum(attack AP) + attack-count penalty + selected block/magic AP
```

An explicit equipped attack seed overrides derivation (largest valid seed,
clamped `1..250`). A persisted participation profile takes precedence over
derived values; the profile owner also supports explicit trusted participant,
NPC, match and character data. Match-level attack/action-list overrides do not
silently override NPC-specific action lists. An explicit empty list disables
inherited injected actions. Profiles are persisted for reload/reconnect.

| Attack count | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---:|---:|---:|---:|---:|---:|
| Extra AP | 0 | 0 | 25 | 75 | 150 | 250 |

Physical Simple damage multiplier is 1; Aimed is 1.2 with +15 hit rating.
The package cannot combine head and legs attacks. Blocks must be actual
allowed selectors, not an arbitrary client list. AP/MP and action availability
are revalidated on the server; duplicate/terminal turns do not spend twice.

| Table | Allowed physical selections and AP |
|---|---|
| normal | Head 35; torso 30; abdomen 30; legs 35; head+torso 50; head+abdomen 60; torso+abdomen 50; torso+legs 60; abdomen+legs 50; legs+head 80 |
| shield_40 | Each single zone 40; adjacent pairs head+torso / torso+abdomen / abdomen+legs 85; legs+head 100 |
| shield_70 | Head 45; head+torso / torso+abdomen / abdomen+legs 70; legs+head+abdomen 130 |
| shield_90 | Head+torso+abdomen or torso+abdomen+legs 90 |

An item explicitly declares its shield table; having a shield-family name is
insufficient. Multiple conflicting equipped table identities fall back to
normal. Do not invent symmetry in the captured selector rows.

### COMBAT-02 — Hit, dodge, critical and physical block

These are **calibrated** opposed-rating equations. `A` is attacker, `D` defender;
`Dex`, `Luck`, `Acc`, `Eva`, `Crush`, `Fort`, `Pen`, `Armor` are effective inputs.

```text
opposed(a,b,scale) = scale * (a-b) / (abs(a)+abs(b)+100)
hit% = clamp(85 + opposed(5*DexA+AccA, 2*DexD+EvaD, 15)
                  + action hit bonus + body hit, 5, 95)
dodge% = clamp(5 + opposed(5*DexD+EvaD, 5*DexA+AccA, 35)
                 + body dodge - (aimed ? 5 : 0), 0, 60)
crit% = clamp(10 + opposed(5*LuckA+CrushA, 5*LuckD+FortD, 75)
                 + (aimed ? 10 : 0) + (head ? 5 : 0), 1, 85)
block% = clamp(45 + opposed(ArmorD+3*DexD, AccA+2*PenA+3*DexA, 35)
                  + body block - 4*max(covered zones-1,0), 5, 95)
```

| Target | Hit offset | Dodge offset | Block offset | Physical damage multiplier |
|---|---:|---:|---:|---:|
| Head | -10 | +3 | -5 | 1.3 |
| Torso | 0 | 0 | +5 | 1.0 |
| Abdomen (`stomach`) | +5 | -2 | +2 | 1.1 |
| Legs | -5 | -5 | -3 | 0.9 |

Each probability uses `rand(100) < chance`. The unrounded chance decides the
outcome; one-decimal rounding is diagnostic presentation only. Integer rolls
therefore discretize a fractional chance. Ordering: hit → dodge → covering
physical block → critical → damage. A dodged attack can retain a rolled
critical-attempt log. A successful physical block prevents the hit; a failed
shield block can produce the shield-piercing description. These are different
outcomes even when the resulting damage is zero.

### COMBAT-03 — Physical damage

Calibrated model v1; pure numeric owner
[Calibration](../app/lib/game/combat/calibration.rb):

```text
fatigueFactor(F) = 1 - clamp(F-50,0,50)/50 * 0.5
attack = (1.5*Strength + W) * (1 + M/100) * damageMultiplier * fatigueFactor(A)
penetrationFraction = clamp(PenA/200, 0, 0.75)
armorRemaining = ArmorD * armorMultiplierD * fatigueFactor(D) * (1-penetrationFraction)
resistanceFraction = clamp(physicalResistanceD/200, 0, 0.75)
variance = 1 + (rand(1..5)-3)/2 * 0.18
damage = round(max(attack-armorRemaining,0) * actionMultiplier * bodyMultiplier
               * (1-resistanceFraction) * variance * (critical ? 2 : 1))
```

The `/2` in variance is floating-point: possible factors are
`0.82, 0.91, 1.00, 1.09, 1.18`. Physical armor subtracts before action/body
multiplication; resistance and penetration are capped independently. Zero
damage is legitimate, including a critical or shield-piercing hit.

Player `damageMultiplier` comes from trusted `artifact_grade`: none 1.0,
small 1.1, medium 1.2, large 1.3. This is separate from subscription benefits.
NPCs use the following family coefficients with their exact numeric profiles:

| Family | W | Damage multiplier | Armor multiplier |
|---|---:|---:|---:|
| Orc | 3 | 1 | 1 |
| Goblin | 2 | 1 | 1 |
| Skeleton | 5 | 1 | 1 |
| Bandit | 19 | 1 | 1 |
| Robber | 23 | 1 | 1 |
| Ogre | 40 | 2.55 | 3 |

When an NPC has no positive Strength input, its explicit legacy `stats.attack`
is the base attack instead of `1.5*Strength+W`. No level-based stat curve is
silently added. Level affects player grants, equipment and reward comparisons;
the strike equation itself has no extra universal level multiplier.

Raw rolled damage and credited HP loss are separate:
`credited = min(raw damage, victim HP before the strike)`, then
`HP = max(HP - raw damage, 0)`. Already committed returns can be logged after a
lethal hit, but cannot earn damage against HP already lost or another defeat.
Result statistics keep physical, magical, total and defeated-opponent figures.

### COMBAT-04 — Magic attacks and barriers

Captured action availability/costs; calibrated damage. Magic must be injected
into the accepted profile; the existence of a catalog row alone grants no spell.

| Action | AP | MP | Element / effect |
|---|---:|---:|---|
| Spirit Arrow | 50 | 5 | arcane; +5 hit bonus |
| Mind Blast | 90 | 5 | mind; +10 hit bonus; 1.35 damage factor |
| Magic Shield | 45 | 20 | Reduce incoming magic by 20% |
| Rainbow Barrier | 60 | 40 | Reduce incoming magic by 45% |
| Crystal Sphere | 90 | 65 | Reduce incoming magic by 65% |

```text
K = max(effective Knowledge,1)
base = spell MP cost * (1+(K-1)/20) * (1+matching elemental skill/100)
base *= (Mind Blast ? 1.35 : 1)
R = matching elemental resistance skill + matching equipped resistance ratings
magic damage = round(base * (1-clamp(R/200,0,0.75))
                     * (1-committed magic barrier reduction) * (critical ? 2 : 1))
```

Magic uses the shared hit/critical rolls but bypasses physical dodge, physical
block and armor. It does not use the physical variance/body-damage multiplier
or the generic attack multiplier (the Spirit Arrow catalog's 1.05 is not used
by this branch). Body targeting still affects hit/critical chance. Equipment
resistance keys are `<element>_resistance`, `all_resistances`,
`elemental_resistance`; current arcane/mind skill keys are absent from the
allocatable registry, so the normal learned contribution is zero. A committed
magic barrier, rather than a physical shield name, selects reduction.

Package MP is the sum of attack, block and other allowed magic-action MP costs.
It must fit current MP, and each individual cost must fit the persisted
`max_magic_mana` profile ceiling. That ceiling defaults to the player's saved
`max_mp` when no override is supplied, independently of equipment-aware maximum
MP and current MP. Current `magic_types` is empty; it supplies no additional
free-form magic skills beyond the injected catalog attacks/barriers.

### COMBAT-05 — NPC decisions, teams and deadlines

[NpcCombatAi](../app/services/arena/npc_combat_ai.rb) uses living opposing
players only and chooses the lowest current HP target. An authored defense
threshold uses `current HP / max HP < defend_hp_below` plus
`rand < defend_chance`; without both metadata fields it does not take that
defensive branch. `passive`/`aggressive` labels alone are not a numeric chance.

Captured `response_attack_counts` are sampled uniformly as packages; they do
not infer NPC AP from player AP. Otherwise AI adds simple attacks up to the
configured maximum (`1..4`) while the package fits the profile (with a one-hit
fallback). Body choices exclude the head+legs combination. Optional response
block keys are sampled independently. Targeted NPC exchanges do not mean every
remaining NPC automatically strikes on every player turn.

Defeated participants cannot re-enter targets, active rosters, readiness or
new turns; only previously committed returns finish. Defeat/results/history
remain persisted even when the Character later regenerates HP. Win/loss
counters update once per finalized player; a wholly NPC opposing side counts
as NPC combat, otherwise as player combat. Draws add neither win nor loss.

Manual opponent switches remaining are
`max(opposing participation count - 1 - switches already used, 0)`.
The opposing count retains original participants for the budget, but a new
manual choice requires multiple living enemies and an eligible living target.
Automatic handoff after defeat chooses a living opponent and spends no manual
switch. It does not restore spent switches or make a dead opponent selectable.

Arena acceptance requires a positive saved maximum and exact
`current HP * 100 >= saved max HP * 50`; nil/zero maximum rejects. This
unrounded saved-maximum gate is distinct from equipment-aware fight HP and
the one-decimal vital display. Room level/alignment/capacity
restrictions are separate authored eligibility gates.

Arena application turn choices are 120/180/240/300 seconds (ordinary default
180); training NPC applications use 300. Human Duels require applicant confirmation after acceptance; NPC/Group start
rules are separate. Historical scheduled pending matches retain due recovery. A turn expires strictly
after its start + timeout. Whole-fight deadlines expire at or after their
timestamp: World explicitly configures **300 seconds**, the user-approved
five-minute policy; an unconfigured match falls back to twice its turn timeout.
The global timeout ends in a draw; eligible per-turn claims can award victory
or accept a draw. Do not substitute HP comparison for these state transitions.
See [ArenaMatch](../app/models/arena_match.rb) and the Combat handbook for
claim eligibility, no-op packages and already committed returns.
The training NPC application also has a five-minute waiting expiry, trauma 30
and enemy-side level range 0–33; these are application parameters, not a
mannequin stat-scaling formula.

## 6. Experience, loot and premium

Reward/finalization owner: [Arena Combat](features/arena_combat.md);
[Inventory](features/player_inventory.md), [Shop/Economy](features/shop_economy.md)
and the [event catalog](features/game_shell.md#gameplay-event-catalog) own item,
wallet and notice handoffs respectively.

### REWARD-01 — Shared NPC and player experience

Owner: [ExperienceAwarder](../app/services/arena/experience_awarder.rb).
Captured solo totals have precedence; the general fallback is calibrated.
Draws, invalid winners and no eligible damaged player/defeated NPC enemies yield no award.

For a match containing exactly one player, the applicable explicit
`encounter_experience_reward` or `encounter_defeat_experience_reward` is the
total before cap. A present invalid value resolves to zero; explicit zero
suppresses fallback. A loss award still requires a defeated enemy NPC.

Otherwise, for each recipient at their participant level:

```text
n = count of defeated NPCs plus player opponents who were defeated or took credited damage
NPC contribution = maxHP * 0.85 * 0.75^max(playerLevel - npcLevel - 2, 0)
Player contribution = min(maxHP, credited damage taken) * 0.85
                      * 0.75^max(playerLevel - enemyLevel - 2, 0)
if n == 1 and enemy is NPC and template XP > 0: use template XP instead
risk = 1 for NPC-only enemies; otherwise trauma 10/30/50/80 => 1/1.1/1.2/1.35
lossFactor = 1 on victory; on defeat: 1 if any player enemy, otherwise 0.1
gross = round(sum(contributions) * (1 + 0.45*(n-1)) * risk * lossFactor)
```

With more than one player on the recipient's team, let `p` be team size and
`D` its total credited damage. Dead contributors remain included:

```text
contributionShare = own credited damage / D, or 1/p when D == 0
share = 0.2/p + 0.8*contributionShare
earned = floor(gross * share)
final XP = min(earned, floor(current level fight cap * entitlement cap multiplier))
```

A one-player team uses gross directly. Each recipient's gross is computed at
their level; this is not one common XP pot divided irrespective of levels.
The credited damage field includes the team's credited combat damage, not a
separate NPC-only contribution counter. Untouched player surrender awards no XP.
Player levels/maxHP are snapshotted before settlement grants to prevent an
earlier recipient level-up changing a later recipient calculation. Trauma
factors are monotonic local fits to the wiki's qualitative higher-risk/higher-XP
rule, not measured Neverlands constants.
Finalization guards against duplicate grants and uses the shared level-up
service. Template XP is a current template read; encounter totals are match
metadata.

### ARENA-01 — Admission and deadlines

[ARENA](ARENA.md#3-applications-and-admission-rules) explains these terms in the
player flow, including hall gates, side assembly, examples and editing impact.
[Arena design](design/areas/arena.md) owns the application contract;
[EquipmentRule](../app/services/arena/equipment_rule.rb) reads equipped items and
character `artifact_grade`. Unarmed accepts no equipment; no-artifacts accepts
only `none`; limited accepts configured grades whose artifact multiplier is
at most `arena_rules.limited_artifact_max_multiplier` (currently1.1). This
threshold is fitted. Unknown grades reject restricted offers.

HP admission requires positive maxHP and exact `currentHP * 100 >= maxHP * 50`,
without rounded display percentages. Group ranges must be integer0–33, min≤max; capacity1–30 (closed10),
1×1 normalizes to1×2. Allowed waits5/10/15/30/45/60 minutes determine
`expires_at = created server time + wait`; a deadline is reached at `now >=
expires_at`. Turn timeout is120/180/240/300 seconds, global fight deadline300.
Changing these rules requires model/service/HTTP coverage plus lobby UI review.

### REWARD-02 — Premium limits

Captured limits in [PremiumBenefits](../app/lib/game/combat/premium_benefits.rb):

| Effective entitlement | Inclusive drop window | XP maximum multiplier |
|---|---|---:|
| Standard / no active recognized tier | `max(level-2,0)..level+2` | 1.0 |
| Premium | `max(level-2,0)..level+2` | 1.5 |
| Gold | `max(level-4,0)..level+4` | 2.0 |
| VIP | `max(level-6,0)..level+6` | 2.5 |

Expiry is strict: `expires_at > server now`. Unknown/malformed/expired values
use standard benefits. Configuration accepts only supported windows and
multipliers and fails closed. The multiplier raises the **cap**, not earned
XP: earned 50 under a 100→150 cap still awards 50. Level 17 standard eligibility
is 15–19, Gold 13–21, VIP 11–23. An NPC's narrower limit still wins.

### REWARD-03 — Search, probabilities and amounts

Owners: [CombatProcessor](../app/services/arena/combat_processor.rb),
[NpcLootAwarder](../app/services/arena/npc_loot_awarder.rb),
[LootEntry](../app/services/game/loot_entry.rb). Search requires a defeating
player, `search_enabled != false`, entitlement eligibility and any narrower
NPC `search_max_level_difference`. It occurs on NPC defeat, not only victory.

```text
baseChance% = chance <= 1 ? chance*100 : chance
bonus = observation_max_bonus * effective Observation / (Observation + observation_scale)
effectiveChance% = clamp(baseChance% * (1+bonus),0,100)
success iff rand(10000) < effectiveChance% * 100
```

Current scale is 100 and maximum bonus parameter 1. For Observation 100, chance
is multiplied by 1.5 (12% becomes 18%). Require explicit finite chance `0..100`;
`1` means 100%, `0.01` means 1%. Rolls are independent, with no guaranteed
one-drop rule or pity accumulation.

A nonempty template table replaces fallback. If empty and `calibrated_loot`
is true, fallback is NV 12%, Minor Health Potion 3%, weapon 1%; amount
`max(npcLevel + rand(8..12),1)`, weapon `assassin_dagger` at level ≥13 otherwise
`penknife`, quantity 1. Rat Tail is an explicit calibrated 3% entry. Skeleton
search is disabled; Orc/Goblin have maximum difference 2. NPC paper-doll gear
does not become loot. Failed item-capacity/entry processing is recorded as
processed, not retried as another random roll; successful item/NV mutations
and their deduplication marker commit together.

## 7. Recovery, wear and injuries

[MEDICAL](MEDICAL.md) connects these equations to injury lifecycle, restrictions,
bag/Doctor requirements and free/paid treatment. [CHARACTER](CHARACTER.md)
distinguishes current HP/MP, saved maxima and effective primary-stat penalties.

[Vitals design](design/features/character_vitals.md) supplies the recovery and
injury context for these calculations.

Runtime owners: [Character Progression](features/character_progression.md),
[Combat](features/arena_combat.md) and [Medical Care](features/medical_care.md).

### RECOVERY-01 — Elapsed HP/MP regeneration

Owner: [VitalsService](../app/services/characters/vitals_service.rb).
Current intervals/skill/fatigue factors are calibrated in `combat_calibration.yml`.
Active matches block regeneration; the combat flag otherwise allows recovery
after its ten-second lockout. Elapsed time is measured from the later of the
last regeneration anchor (or creation) and last combat time.

```text
HP per second = effective maxHP / 600 * (1 + Self-Healing/100) * fatigueFactor
MP per second = effective maxMP / 900 * (1 + Fast Mana Regeneration/100) * fatigueFactor
elapsed = max(now - anchor,0)
accumulated = rate * elapsed + saved fractional remainder
new current = min(current + floor(accumulated), effective maximum)
new fractional remainder = accumulated % 1
```

At least one elapsed second is needed. Fractional carry prevents refresh rate
from destroying sub-unit regeneration. The current rate applies to elapsed
time at evaluation; the service does not integrate a historical timeline of
every equipment/fatigue change. Percent displays are `round(current/max*100,1)`
with zero for a zero maximum. Flat healing/mana restore is capped at missing
vitals; consuming an item does not invent a percentage heal.

### WEAR-01 — Durability after a fight

Captured per-item chances, owned by
[EquipmentWearResolver](../app/services/arena/equipment_wear_resolver.rb):

| Context | Victory | Draw | Defeat |
|---|---:|---:|---:|
| Arena / non-World match | 0% | 0% | 1% |
| `source: world_npc` | 2% | 30% | 50% |

Careful Fighter divides chance by 2, including Arena defeat 0.5%. Each equipped,
durable, unbroken item rolls independently on `rand(10000) < chance%*100`.
A success removes **one durability point**, minimum zero. Reaching zero
unequips the item. No damage-per-hit wear curve is added.

### INJURY-01 — Defeat injury and stat penalty

Owner: [InjuryAwarder](../app/services/arena/injury_awarder.rb),
[CharacterInjury](../app/models/character_injury.rb). Source-backed injury
categories/state with explicit local award/duration policy:

- Defeated players only; at most one injury per player/match, and no new injury
  at 99 active injuries.
- Combat injury flag always awards combat severity. Otherwise a decisive
  timeout with positive trauma always awards heavy severity. Otherwise roll
  `rand(100) < clamp(trauma_percent,0,100)`.
- After a successful ordinary roll, an **independent** `rand(100)` chooses
  light80%, medium18%, heavy2%. Fight risk controls occurrence, never a fixed
  severity; a high-risk ordinary fight can still leave no injury or a light one.
  These are user-directed local rarity weights, not recovered source odds.

`P(no injury) = 1 - risk/100` and
`P(severity) = risk/100 * severity_weight/100` for ordinary defeated players.

| Fight risk | No injury | Light | Medium | Heavy |
|---|---:|---:|---:|---:|
| 10% | 90% | 8% | 1.8% | 0.2% |
| 30% | 70% | 24% | 5.4% | 0.6% |
| 50% | 50% | 40% | 9% | 1% |
| 80% | 20% | 64% | 14.4% | 1.6% |

Edit `injuries.severity_weights` in
[combat_calibration.yml](../config/gameplay/combat_calibration.yml) to tune the
conditional mix. The loader requires exactly light/medium/heavy, nonnegative
integer percentages totaling100. Restart the app/workers after configuration
changes. [Calibration.injury_severity](../app/lib/game/combat/calibration.rb)
is a pure calculation with explicit chance/severity rolls; the shared match
finalizer supplies server RNG and prevents retries from rerolling a completed
uninjured result. Existing injuries retain their saved severity and expiry.
The separate source-backed combat/decisive-timeout cases bypass this table.

| Severity | Base duration | Primary-stat penalty | Added duration for each already active injury |
|---|---|---:|---|
| Light | 30 minutes | 5% | 7.5 minutes |
| Medium | 2 hours | 15% | 30 minutes |
| Heavy | 6 hours | 30% | 1.5 hours |
| Combat | 24 hours | 40% | 6 hours |

`expiry = now + base duration + prior active count * extension`.
Injury is active only while unhealed and `expires_at > now`. Combined primary
penalties cap at 90% (STAT-01). Heavy/combat injuries block movement while
active. Expiry/healing preserves injury/fight history.

### MEDICAL-01 — Treatment and licenses

Owner: [TreatInjury](../app/services/characters/treat_injury.rb) and
[Medical Care handbook](features/medical_care.md). Quoted NV price must be an
integer in `0..80` light, `0..150` medium, `0..500` heavy, `0..7000` combat.
Paid requests expire after **five minutes** and require patient acceptance;
free treatment completes immediately. Acceptance rechecks same cell, no
movement/combat, Healer perk, active Doctor license, matching usable owned bag
and bag requirements through `RequirementChecker`.

`effective Doctor = max(valid saved profession_skills.doctor + usable equipped
doctor bonuses, 0)`. Saved data must be a nonnegative integer; absent/malformed
data contributes zero. Flat `doctor` and nested `skill_bonuses.doctor` item
effects add points; broken, expired or unequipped items do not qualify. This
profession counter is separate from allocatable Skills and the Healer perk.

The seeded bags require Knowledge/Doctor **20/100, 45/300, 90/400, 160/600**.
Changing seed requirements changes admission, not cure amount/chance. At 99/100
a light-bag request fails with unchanged state; at 100/100 it may proceed if
all other checks pass. Removing a qualifying item after quoting makes paid
acceptance fail atomically. See [Medical Care](features/medical_care.md).
Combat injuries cannot be self-treated.

Success marks the injury healed, removes one bag durability use, transfers the
agreed NV from patient to healer and records/publishes the event atomically.
There is no extra random cure roll or Doctor-skill XP gain. Bag requirements,
use counts, prices and potion healing are authored item data in
[combat_care seeds](../db/seeds/combat_care.rb), not inferred from the artwork.

| Bag / kit | Severity | Base NV price | Uses | Required Knowledge | Required effective Doctor |
|---|---|---:|---:|---:|---:|
| Beginner healer bag | Light | 300 | 10 | 20 | 100 |
| Skilled healer bag | Medium | 750 | 10 | 45 | 300 |
| Experienced healer bag | Heavy | 1500 | 10 | 90 | 400 |
| Combat first-aid kit | Combat | 7000 | 1 | 160 | 600 |

The seeded small health elixir restores a flat 50 HP up to the effective
maximum. Bag purchase price is distinct from the agreed treatment fee.

## 8. World movement and encounter timing

[Movement design](design/features/movement.md) owns the travel contract;
[World map design](design/areas/world_map.md) owns cell/action context.

Runtime/acceptance owner: [World](features/world.md), handing initiated fights
to [Arena Combat](features/arena_combat.md).

### WORLD-01 — Walking time

Owner: [TravelTime](../app/services/game/movement/travel_time.rb),
[world_rules.yml](../config/gameplay/world_rules.yml). An explicit positive
cell `travel_seconds` wins. Otherwise:

```text
reduction = floor(clamp(effective Wanderer,0,100) * 6 / 100)
travel seconds = clamp(30-reduction,24,30)
```

Examples: Wanderer 0 →30s, 50 →27s, 100 →24s. Adjacent movement includes eight
neighbors, validated by the direction/coordinate rules. There is no implicit
diagonal square-root factor or terrain multiplier. The accepted command
persists its deadline; a browser countdown cannot shorten it.

The moving-command display uses
`clamp(ceil(ends_at-now),0,travel_seconds)`; timed local actions display
`max(ceil(deadline-now),0)`. Rounding these displays up is not an extra gameplay
second or authority to finish early.

### WORLD-02 — Fatigue and local actions

Owner: [FatigueService](../app/services/characters/fatigue_service.rb),
[PerformLocalAction](../app/services/game/world/perform_local_action.rb).

```text
recovered = floor(max(now - fatigue anchor,0) / 180)
current fatigue = max(clamp(stored fatigue,0,100) - recovered,0)
accepted movement adds rand(1..2) points, clamped at 100
```

Move/Look/Enter reject fatigue ≥86 at acceptance. Drink immediately subtracts
2 fatigue points and holds a 60-second action lock. A configured Nature Child
branch would subtract 4, but that perk is not currently selectable; do not
advertise it as available. Empty Look uses 28 seconds. The captured missing-bait
Fish action uses 30 seconds and awards no fish/profession progress. Timers,
fatigue and visible feedback share authoritative server action offers.

### WORLD-03 — Group selection, waits and respawn

Owners: [EncounterRosterSelector](../app/services/game/world/encounter_roster_selector.rb),
[PassiveEncounterCheck](../app/services/game/world/passive_encounter_check.rb),
[TileNpc](../app/models/tile_npc.rb). See [NPC.md](NPC.md) for the actual cells.

For complete rosters with weights `w`, selection chance is `w/sum(weights)`;
omitted weights mean 1. Select one entire group, then uniformly resolve any
explicit member level ranges. Fixed-width ranges need no draw. Range selection
does not scale HP or stats. These are local authoring policies, not recovered
Neverlands population equations. The maximum is ten members, not an automatic
group-size roll.

Passive delays choose a configured window uniformly, then integer seconds
uniformly inside it. Unequal-length windows therefore do not produce one
uniform distribution over their union. Defaults for an unconfigured anchor
are 10–30 seconds; captured/current cells explicitly override this (e.g.
300–360 seconds for starter samples, 60–360 for strong habitats). The scheduled
due time persists; refresh is not another chance roll. A valid encounter start
consumes the old wait. Sampled anchors can schedule again after Finish.

Fixed defeated anchors respawn only if timing is configured:
`delay = clamp(base respawn seconds + rand(-variance..variance),1,86400)`.
Without configured timing, they stay defeated. Sampled anchors do not enter
that fixed respawn lifecycle. Near-city difficulty is authored content policy,
not a global distance-level equation; strong habitat validation checks
`abs(x-gate_x)+abs(y-gate_y) >= 8` for both Forpost gates.

## 9. Inventory and economy

[ECONOMY](ECONOMY.md) explains stock/funds, qualification, quotes, receipts and
payment flows around these equations; [MEDICAL](MEDICAL.md) owns treatment use
cases and [CHARACTER](CHARACTER.md) explains capacity and build inputs.

[Item/equipment design](design/features/items_inventory_equipment.md) and
[Economy design](design/features/economy_trading_shops.md) supply the capacity,
acquisition and settlement contracts behind these calculations.

Runtime/acceptance owners: [Inventory](features/player_inventory.md) and
[Shop/Economy](features/shop_economy.md).

### INVENTORY-01 — Weight, stacks and effects

Owners: [Inventory](../app/models/inventory.rb),
[InventoryItem](../app/models/inventory_item.rb),
[Manager](../app/services/game/inventory/manager.rb). The ordinary initial
inventory has 30 slots. Active weight capacity comes from Character's carrying
formula, not the stored compatibility `weight_capacity` value.

```text
added weight = item unit weight * added quantity
new weight must be <= character carrying capacity
space in existing stack = template stack_limit - existing quantity
add min(remaining quantity, stack space), then create another stack if needed
```

Creating stacks must fit the slot count. A failed capacity check cannot leave a
partial multi-stack grant. Item transfer moves the same quantity/weight between
inventories subject to destination capacity and item protection/ownership.
Removing units subtracts their weight, with recorded weight clamped at zero.

Known consumable effects are flat `heal_hp`, flat `restore_mp`, and the legacy
`reset_allocation` branch. The first recognized effect is applied, then one
unit/use consumed; this is not an arbitrary list of combinable effects.
Targeted attack scrolls use the separate entry adapter below, not this generic
effect dispatcher. Durability decrease is `max(current - amount,0)`. Item/equipment requirements
compare explicit required level/stats/skills/permissions against current
authoritative values; there is no hidden item-level scaling formula.

### SCROLL-01 — Attack entry

Owner: [AttackScroll](../app/services/game/inventory/attack_scroll.rb), with
[RequirementChecker](../app/services/game/inventory/requirement_checker.rb) and
[starter Shop definitions](../db/seeds/data/starter_shop.json). Inputs are an
owned server-issued action key and target nickname. The server rechecks:

```text
abs(attacker.level - target.level) <= 3  # inclusive, wiki rule
Duel Permit I: level >= 5, effective Stealth >= 20
Fist Attack: level >= 10, no skill gate
new fight global limit = 300 seconds; turn limit = 300 seconds
new Permit trauma = 10%; new Fist trauma = 80%
Fist after removing equipment: HP = min(current HP, effective naked max HP)
                              MP = min(current MP, effective naked max MP)
```

The target window comes from the wiki. Both live 17-to-5 attempts rejected
without charge, a result consistent with that rule but insufficient to measure
its ±3 boundary or isolate the generic error's cause. Local out-of-window
rejection uses the captured generic message, "Error using item. Scroll use
failed." Requirements are source-backed. Low/maximum ordinary
trauma map to the captured Arena categories; they are a cross-source inference,
not a measured scroll injury rate. Severity uses the shared injury formula.
This is not the separate guaranteed special combat-injury attack.

`RULES` and `LEVEL_DIFFERENCE` are the small entry-rule edit points. Changing
them changes admission only; attacks, blocks, dodge, crit, armor, XP and
injuries continue through the combat owners in section 5. Fist removes both
players' gear before snapshots, uses derived unarmed AP/block costs and omits
artifact damage multipliers; stale preview overrides cannot retain a shield.
Gear stays in Inventory afterward; source persistence is pending observation.

An ordinary Permit entering an open live fight joins opposite the living target
and preserves that fight's trauma, equipment rules, round commits and deadlines.
Closed/stale fights, defeated targets and Fist intervention reject without cost.
The latter is an explicit evidence boundary. Location equality uses validated
Presence context (cell plus room), not browser coordinates. One charge is
consumed only on committed entry; the ten-minute offer expires at its deadline,
and a completed retry returns the original match without another charge.
See [ITEMS](ITEMS.md#attack-scroll-use), [scroll design](design/features/scrolls.md)
and [source observations](design/reference/inventory/observations/2026-09-14_attack_scrolls.md).

### ECON-01 — Shop purchase, sale and NV transfers

Purchase exchanges **one item** for its current authored decimal `base_price`;
stock decreases by one, Shop NV rises by price and player NV falls by price.
Selling requires an active trading license, an accepted unprotected/unbroken
item, stock capacity and enough Shop NV. It removes one unit, increases stock
and transfers the quoted payout. An accepted offer is revalidated under locks;
browser prices cannot set settlement amounts.

Captured resale brackets, owned by
[ResalePrice](../app/services/game/shop/resale_price.rb):

| Trading proficiency | 0–99 | 100–224 | 225–349 | 350–474 | 475–599 | ≥600 |
|---|---:|---:|---:|---:|---:|---:|
| Base-price percentage | 20% | 30% | 40% | 50% | 60% | 70% |

```text
sale NV = round(base price * bracket% / 100 * durability fraction, 2)
durability fraction = current durability / maximum, or 1 for non-durable items
```

Use decimal arithmetic and round once after both factors. Invalid durable
state outside `0..maximum` has zero quote and is rejected at sale; nonpositive
base price has zero quote. Trading is trusted
`metadata.profession_skills.trading`, a nonnegative integer, default zero;
it is not the allocatable Leadership skill. Direct NV transfer has no authored
fee and debits/credits the same positive amount. Player-to-player paid item
sales are deliberately unavailable pending a buyer-acceptance flow; no price
equation makes them enabled.

### ECON-02 — Licenses and qualifications

[LicenseRules](../app/services/game/shop/license_rules.rb) supports Trading
tiers I/II/III lasting **3/10/30 days**, and Doctor I/II/III **5/10/15 days**.
`expires_at = activation time + duration days`; ownership of an item whose
name says “license” grants no permission. Valid typed licenses activate at
purchase, instead of becoming ordinary inventory stacks. Active duplicate
licenses are blocked; licenses do not silently stack duration.

Trading requires Merchant and its bounded qualification; Doctor requires
Healer, and tiers above I also require the Traumatologist unlock. Qualification
gates are explicit booleans/state transitions, not proficiency formulas. Prices
are per-template catalog values, not derived from tier/duration. See
[Shop economy](features/shop_economy.md) for the current Market receipt flow
and remaining quest content.

## 10. Transport

[Airship design](design/features/airship_travel.md) owns the paid journey and
region-handoff contract that these fare/time rules support.

Configured journey and acceptance owner: [Airship Travel](features/airship_travel.md).

### TRANSPORT-01 — Authored fare, time and path interpolation

Owners: [AirshipJourney](../app/models/airship_journey.rb),
[AirshipTravel](../app/services/game/world/airship_travel.rb),
[airship_routes.yml](../config/gameplay/airship_routes.yml). Captured Forpost
fares are Khalgan Fair 350 NV, Telior Island 150 NV, Oktal 150 NV.
**These fare declarations alone are not operational routes**: current baseline
lacks destination/path/dated schedule content, so boarding remains unavailable
until explicitly authored. The generic configured transport capability exists.

```text
arrival = explicit departure + authored flight duration
progress = clamp((now-departure)/(arrival-departure),0,1)
segment fraction = (elapsed-left offset)/(right offset-left offset)
same-region position = left coordinate + fraction*(right coordinate-left coordinate)
```

Waypoints must have strictly increasing integer offsets spanning the duration.
Region boundaries switch to the next explicitly authored waypoint at its
timestamp; there is no guessed cross-region coordinate transformation.
Reconciliation rounds sampled coordinates for the persisted local cell.
Waiting is before departure, in-flight before arrival, arrived at/after arrival;
explicit disembarkation ends the trip. Paid reservation fare/deadlines/path are
immutable snapshots. No repeating timetable or price-distance formula is
inferred. See the [Airship handbook](features/airship_travel.md).

## 11. Compatibility and absent formulas

These boundaries prevent a formula inventory from accidentally promising a
feature. They describe current code, not newly approved design:

| Code/data | Current boundary |
|---|---|
| `PassiveSkillRegistry.calculate_effect` | Returns 0.0 as a generic compatibility hook; active named skills use their explicit owners above |
| `Npc#roll_initiative` | Agility + `rand(1..10)` helper exists; shared combat does not call it to order exchanges |
| `Npc#attack_damage_range` | Returns `0..0` for nonpositive attack; otherwise `base ± max(integer base/4,1)`. This legacy helper is not the calibrated strike range |
| `ActionCatalog.body_part_multiplier` and body `block_difficulty` data | Current physical resolver uses its own explicit body constants; changing unused YAML alone will not retune strikes |
| `Character#equipped_items_resistance` | Nested-resistance helper with a 0–0.15 cap has no active shared combat caller; magic uses the flat rating path in COMBAT-04 |
| `Character#reduced_mana_cost` | Compatibility `max(base_cost.to_i,1)`; no learned mana-discount curve. Fight actions use catalog/profile validation |
| Progression `max_npcs_in_group` | Captured table, not an enforced player-level encounter selector limit |
| Legacy `reset_allocation` consumable effect | Clears allocated stats and learned skills; refunds sum of stat allocations but only **one point per positive skill**, not the original tier-based spend. It does not clear/refund perks despite its success text. This is a limited implementation, not a documented source-accurate full reset |
| NPC visible `wisdom` and equipment properties | Inspection content where no explicit adapter reads it; images/properties alone add no damage/armor |
| Profession skill-up, herb/fish yield, crafting quality, gathering success, quest reward curves, dungeon scaling | No general active formulas; their owning handbooks describe absent/bounded runtime |

Do not “complete” these gaps by importing generic RPG equations. Record new
Neverlands evidence or an explicitly authorized calibrated policy, implement
it in the existing owner, and then change the status here. Full source formula
identity remains unknowable without source code; that does not disable the
authorized v1 calibration already implemented.

## Use cases and cross-feature effects

These checked examples illustrate current rules; their complete equations,
provenance and owners remain in the named sections. Tuning one input can
affect multiple features without changing all their formulas.

| Preconditions / use case | Calculation and result | Consumer and boundary |
|---|---|---|
| Lifetime XP crosses multiple supported thresholds | Add XP once; grant each reached row | [SKILLS](SKILLS.md)/[PERKS](PERKS.md) gain their separate unspent pools; old allocations are not repriced |
| Sword learned 24, equipment+50, spend 2 | Learned 24→32→38; effective 88 | Skills tiers use learned values; item requirements/combat read effective values |
| Level 17 with More Strength, no injury | Bonus 8 Strength | Shared physical attack and capacity can change; no direct HP or hit-probability bonus is invented |
| Wanderer 50, no authored duration | `30-floor(50*6/100)=27 s` | [WORLD](WORLD.md) persists the accepted deadline; later stat changes do not rewrite it |
| Eligible NPC 12% base chance, Observation 100/200 |18% /20% effective chance | [NPC](NPC.md)/[COMBAT](COMBAT.md) retain independent entry eligibility and random rolls; chance is not a promised drop |
| Careful Fighter, Arena/World NPC defeat |1%→0.5% /50%→25% per qualifying item | [ITEMS](ITEMS.md) wear changes; injury and loot probabilities do not |
| maxHP 600, Self-Healing 100, fatigue≤50, recovery allowed |2 HP/sec;10 s gives 20 HP before maximum cap | Out-of-combat recovery cannot heal an injury record or create Doctor proficiency |
| Permit I with Stealth 20 | Skill gate passes | [SCROLLS](SCROLLS.md) still validates target/level/presence and charge atomically; premium loot windows do not widen attack eligibility |
| Change an illustration | No numerical change | [ARTWORK](ARTWORK.md) alters presentation, never formula inputs by inference |

## 12. Change impact, verification and maintenance

### Editing procedure

1. Find the formula ID and authoritative owner above. Identify whether the
   change is to an input (one item/NPC), shared coefficient, probability,
   threshold, rounding step or state transition.
2. Record supporting evidence or the agreed calibration in the relevant design
   owner. Preserve old observations as historical evidence. Do not relabel a
   fit as a measured source coefficient.
3. Change the smallest existing owner. Keep pure numeric calculation separate
   from DB reads, locks, RNG selection and committed side effects. For a new
   coefficient, extend validation at the loading boundary.
4. Check dependent effects: stats → capacity/requirements/AP/damage/recovery;
   NPC HP/level/count → survival and XP; loot → inventory/economy; travel →
   encounters/fatigue. Test another context using the same combat pipeline.
5. Decide how existing state is handled. Config changes do not retroactively
   regrant levels, reroll loot, resnapshot fights or rewrite accepted travel
   deadlines. NPC reward readers can still read current template fields.
6. Update this book, the affected handbook/design and relevant [NPC](NPC.md),
   [ITEMS](ITEMS.md), [WORLD](WORLD.md), [ARTWORK](ARTWORK.md) or
   [event catalog](features/game_shell.md#gameplay-event-catalog) entries under
   the context/update map, then run proportional automated checks and required
   final browser acceptance.

Configuration lifetimes differ: progression/action/calibration readers cache
per process, benefits include a class-load constant, and world/NPC catalogs
offer specific reload methods. Restart/reload affected application and worker
processes when deploying such changes; a YAML edit or reader reload does not
sync managed database content. Never use a full seed as an implicit formula
migration or reconciliation of earned player state.

### Verification map

| Changed behavior | Existing focused coverage / check |
|---|---|
| Level table and thresholds | [catalog specs](../spec/lib/game/progression/catalog_spec.rb), Character progression specs |
| Skill rates and band crossing | [skill formula specs](../spec/lib/game/formulas/skill_progression_formula_spec.rb), allocation request/service specs |
| Physical damage and probabilities | [calibration specs](../spec/lib/game/combat/calibration_spec.rb), [mastery specs](../spec/services/arena/mastery_calibration_spec.rb), CombatResolver specs |
| Magic and barriers | [magic calibration specs](../spec/services/arena/magic_calibration_spec.rb) |
| Group/defeat XP | [defeat experience specs](../spec/services/arena/npc_defeat_experience_spec.rb), ExperienceAwarder specs |
| Loot, entitlement limits and retry | NpcLootAwarder/PremiumBenefits specs, [World combat lifecycle](../spec/requests/world_npc_combat_lifecycle_spec.rb) |
| Fractional recovery | [elapsed recovery specs](../spec/services/characters/vitals_elapsed_recovery_spec.rb) |
| Medical transitions | [treatment specs](../spec/services/characters/treat_injury_spec.rb) |
| Inventory/trade | InventoryItem/Manager/ResalePrice and Shop request/system specs |
| Movement/encounters/transport | TravelTime, FatigueService, TileNpc, habitat and [AirshipJourney specs](../spec/models/airship_journey_spec.rb) |

Cover before/at/after boundaries, zero/max values, deterministic rolls, explicit
overrides and affected persistence/retry behavior. Use `bin/verify combat` for
focused combat work, broader profiles when required by [AGENTS.md](../AGENTS.md),
and `bin/verify docs` for this documentation-only task. A passed formula spec
is not a new Neverlands observation or UI acceptance result.

**Maintain this book during every task that changes a relevant formula or
input contract.** Add new active formulas here with purpose, provenance,
inputs/units, order of operations, rounding/caps, owner, affected behavior and
verification pointers. Update table values when their owner changes. If a
previously dormant helper becomes live, update its status and consumers.
Unrelated edits need no artificial document touch. The maintenance requirement
is part of [DOCUMENTATION.md](DOCUMENTATION.md#410-game-reference-books).

## September 14 PvP loss contribution

[Source fight](design/reference/combat/observations/2026-09-14_arena_fist_duel.md): loser damage194, no kill, XP177; winner
credited225/one kill/XP566. A living player opponent who took credited damage
now qualifies for the shared reward calculation. `pvp_loss_multiplier=1.0`
replaces the NPC-only0.1 defeat factor on PvP. With the retained coefficients,
level17 versus24,194HP credited and30%trauma gives
`round(194 * .85 * 1.1)=181`, close to177 but explicitly approximate.
The winner566 is preserved evidence, not a claimed match to this general fit.
Level, alignment, premium and spell-dependent reward coefficients remain
unknown. NPC explicit loss totals, NPC kill eligibility, caps, team sharing and
once-only finalization keep their existing contracts.
