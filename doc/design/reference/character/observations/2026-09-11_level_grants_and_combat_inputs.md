# Neverlands Level Grants and Combat Inputs Recheck

---
doc_type: neverlands-observation
domain: character
captured_at: 2026-09-11
source_type: official-wiki-and-authenticated-live
evidence_status: current
supersedes: []
---

## Scope and method

Re-read the official [experience table](http://wiki.neverlands.ru/wiki/Таблица_опыта)
and [damage article](http://wiki.neverlands.ru/wiki/Урон) over public HTTP on
September 11. Compare published inputs with the current Rails owners and the
[stronger NPC cycle](../../combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md).
No player level-up, allocation reset or premium purchase was performed live.
This is published-rule evidence, not a newly observed source level-up UI flow.

## Published level grants

The table grants free primary-stat points when a level is reached; it does not
raise each primary stat by that amount. The level-0 starting pool is15, in
addition to five primary stats at1 each. Later grants vary by level. The
published total excludes stat-granting perks.

| Reached level | New stat points | Cumulative base stats plus granted points |
|---|---:|---:|
| 0 | 15 | 20 |
| 1 | 3 | 23 |
| 2 | 3 | 26 |
| 3 | 3 | 29 |
| 4 | 5 | 34 |
| 5 | 5 | 39 |
| 6 | 5 | 44 |
| 7 | 10 | 54 |
| 8 | 5 | 59 |
| 9 | 7 | 66 |
| 10 | 15 | 81 |
| 11 | 7 | 88 |
| 12 | 12 | 100 |
| 13 | 10 | 110 |
| 14 | 12 | 122 |
| 15 | 15 | 137 |
| 16 | 15 | 152 |
| 17 | 15 | 167 |
| 18 | 15 | 182 |
| 19 | 15 | 197 |
| 20 | 10 | 207 |
| 21 | 20 | 227 |
| 22 | 15 | 242 |
| 23 | 25 | 267 |
| 24 | 20 | 287 |
| 25 | 20 | 307 |
| 26 | 20 | 327 |
| 27 | 20 | 347 |

Rows28–29 also publish20 new stat points, but contain unknown values in other
reward columns. The local finite catalog stops at the last complete row27;
this is a completeness boundary, not absence of all published data above27.

The XP-to-next column is the **increment needed for that level**, not a
cumulative threshold. At level17 the live profile showed29,946,496 combat XP
and20,053,504 remaining, totaling50,000,000. Summing published rows0–17 gives
exactly50,000,000; row17 alone is25,000,000. This disambiguates the table and
supersedes the July audit's cumulative-column interpretation. Reaching level17
requires sum(rows0–16)=25,000,000. Reaching levels1/2/3/4/10 requires
100/300/800/1,800/50,000 respectively. Skill columns
show the new grant followed by a parenthesized cumulative total. Per-fight XP
caps explicitly exclude paid-service benefits. Maximum NPC group size also
depends on other factors; the column alone is not an encounter generator.

## Combat inputs and evidence limits

The official damage article names Strength, weapon and other item damage,
weapon mastery, artifact coefficients, and temporary food/potion effects as
physical-damage inputs. Armor class and physical resistance reduce damage.
Level difference substantially affects combat; NPCs additionally have hidden
strength coefficients and periodic peaks. It does not publish a complete
numerical damage, block, dodge or critical-chance formula.

The live dagger swap in the stronger-NPC cycle changed several stats, item
damage and weapon type together. Bandit/Robber13–15 also differ in armor,
Dexterity, Luck and equipment. Those observations prove dependency and outcome
variation; they cannot isolate a coefficient or justify fitting a formula to
one overkill. Higher level alone does not prescribe an identical full loadout.

The official [Dexterity](http://wiki.neverlands.ru/wiki/Ловкость),
[Luck](http://wiki.neverlands.ru/wiki/Удача),
[modifiers](http://wiki.neverlands.ru/wiki/Модификатор) and
[weapon skills](http://wiki.neverlands.ru/wiki/Боевые_умения) articles were also
re-read. Dexterity contributes to hit/dodge; Luck to critical attacks and
critical defense. Crushing modifies critical frequency, Accuracy hit chance,
Evasion dodge chance, and Fortitude resistance to critical attacks. These
percent-style displayed modifiers are not direct probabilities (values exceed
100). Weapon mastery increases physical damage and reduces attack AP; no
numerical reduction formula is supplied. Do not confuse Fortitude with the
separate physical-resistance skill or use it as an unsupported flat damage cut.

## Local audit and ownership

A direct comparison checked all28 supported level rows against six published
columns (stat, NV, perk, peace-skill, combat-skill grants and maximum NPC group
size): all168 values matched `config/gameplay/character_progression.yml`.
The live profile independently verifies cumulative threshold composition as
described above. The machine comparison did not normalize the fight-cap column.
Stored row values remain unchanged; the local threshold reader must sum costs.

- [Progression design](../../../features/progression_stats_skills.md#level-and-experience-table)
  owns the normalized grants and allocation model.
- [Progression handbook](../../../../features/character_progression.md#level-grants-and-the-combat-handoff)
  owns current persistence, effective-value consumers and validation.
- [Combat design](../../../features/combat.md) and
  [combat handbook](../../../../features/arena_combat.md) own resolution.
- [MVP plan](../../../launch_mvp_plan.md) owns delivery status.

`Character#stats` combines the base1, saved allocation, supported More Strength
perk and equipped stat modifiers. `LevelUpService` grants unspent pools under a
character lock; saving allocation makes them effective. The resolver already
reads effective primary values and equipment-backed attack/defense, but its
inherited numerical chance/damage constants are not verified Neverlands
formulas. Weapon-mastery and artifact damage coefficients remain an explicit
combat implementation/evidence gap; recording their input names does not
implement them.

### September12 runtime successor

The user subsequently authorized evidence-grounded fitted completion. See
[combat calibration](../../../features/combat_calibration.md) for the now
implemented equations and content policy. Earlier local gap/disabled-state
notes here are historical. No observation or source outcome above is changed
by the local approximation.
