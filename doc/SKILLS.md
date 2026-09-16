# Skills Guide

Reviewed against the working tree and preserved Neverlands evidence on
**2026-09-14**. **Skills** is our name for **Умения**: learned numeric values
plus applicable equipment bonuses. This book explains the current catalog,
allocation, gameplay consumers, formulas, limitations and editing procedure.
Implemented consumers come first; selectable definitions without a working
effect and profession counters are explicitly separated below.

Use [PERKS](PERKS.md) for yes/no **Навыки**, [FORMULAS](FORMULAS.md) for the
numerical reference, [ITEMS](ITEMS.md) for requirement/equipment data and
[COMBAT](COMBAT.md) for shared PvP/PvE execution. The
[Character domain](domains/character.md), [source summary](design/reference/character/README.md),
[progression design](design/features/progression_stats_skills.md),
[MVP plan](design/launch_mvp_plan.md) and
[Character Progression handbook](features/character_progression.md) own design,
delivery and runtime acceptance. [Professions](domains/professions.md) owns
use-grown counters, not ordinary point allocation.

[CHARACTER](CHARACTER.md) places these values in the complete build and
level-up flow. [MEDICAL](MEDICAL.md) explains Doctor and recovery consumers;
[ECONOMY](ECONOMY.md) explains Trading resale, qualification and licenses.

## Contents

- [1. Scope, evidence and terminology](#1-scope-evidence-and-terminology)
- [2. Implemented skill catalog](#2-implemented-skill-catalog)
- [3. Partial definitions and profession counters](#3-partial-definitions-and-profession-counters)
- [4. Allocation and business rules](#4-allocation-and-business-rules)
- [5. Formulas and effects on related systems](#5-formulas-and-effects-on-related-systems)
- [6. Use cases and cross-feature effects](#6-use-cases-and-cross-feature-effects)
- [7. UI, UX and artwork](#7-ui-ux-and-artwork)
- [8. Implementation and editing](#8-implementation-and-editing)
- [9. Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope, evidence and terminology

The registry contains **29 allocatable skills**: 12 combat, five resistance,
four magic and eight peace. Combat, resistance and magic share the combat
point pool; peace has its own pool. A source ID identifies a captured row;
the stable string key is the persisted local identity. Numeric skill ID 7
means Staff Mastery; perk ID 7 means More Strength. They are separate namespaces.

### The four numeric-skill categories

These are the four **Виды умений** linked from the user's wiki reference.
They belong to **SKILLS**, not to the boolean Perks catalog.

| Neverlands category | Local category / registry key | Rows | Spending pool |
|---|---|---:|---|
| [Боевые умения](http://wiki.neverlands.ru/wiki/Боевые_умения) | Combat Skills / `combat` | 12 | combat |
| [Сопротивления](http://wiki.neverlands.ru/wiki/Сопротивления) | Resistances / `resistance` | 5 | combat |
| [Магические умения](http://wiki.neverlands.ru/wiki/Магические_умения) | Magic / `magic` | 4 | combat |
| [Мирные умения](http://wiki.neverlands.ru/wiki/Мирные_умения) | Peace Skills / `peace_world` | 8 allocatable | peace |

The wiki also discusses profession counters within peace skills; the source
profile displays them in their own Professions section. Those 15 use-grown
counters do not become a fifth allocation category. Later catalog tables order
entries by implementation status while retaining each row's category/pool context.

| Concept | Local meaning and authoritative storage |
|---|---|
| Learned skill | `Character.passive_skills[key]`; normal allocation caps the saved value at 100 |
| Equipment contribution | Derived from currently equipped, usable item effects; does not spend points |
| Effective skill | Learned value plus equipment contribution; may exceed 100 |
| Unspent skill points | `combat_skill_points` and `peace_skill_points`; counts of purchases, not resulting skill levels |
| Profession proficiency | Separate counters, e.g. `metadata.profession_skills.trading`; not in the 29-skill registry |
| Perk | Boolean ownership in `Character.perks`; see [PERKS](PERKS.md) |
| License | Timed `CharacterLicense` permission, shown under Your licenses / Abilities; see [SCROLLS](SCROLLS.md#7-peace-scrolls-and-purchased-licenses) |

The [supplied screenshots and September 14 wiki audit](design/reference/character/observations/2026-09-14_skills_and_perks.md)
preserve the visible numeric/perk distinction. Earlier
[allocation captures](design/reference/character/observations/2026-05-11_player_profile_and_development.md)
establish spending behavior and source IDs. Published category descriptions
come from [Умение](http://wiki.neverlands.ru/wiki/Умение) and its linked pages.
Descriptions below paraphrase the wiki; they do not establish local execution.

Status vocabulary: **ACTIVE** means a current gameplay consumer exists;
**PARTIAL** means allocation/requirements work but a named effect is absent;
**NOT_IMPLEMENTED** means no complete local feature. `[IMPL]` identifies a
known missing behavior; `[EVIDENCE]` identifies missing source detail. A
captured name with no implementation is not automatically an evidence gap.

## 2. Implemented skill catalog

All rows in this table are saved through the same allocation service. Rates
are gain per point for learned bands `0–24 / 25–49 / 50–74 / 75–99`.
The complete numerical owner is [SKILL-01](FORMULAS.md#skill-01--spending-learned-skill-points).

| ID / stable key | Local name / Neverlands label | Pool; rate | Current consumer / boundary |
|---|---|---|---|
| 0 `unarmed_combat` | Unarmed Combat / Рукопашный бой | combat; 10:8:6:4 | **ACTIVE** unarmed AP and damage, including fist-scroll fights; separate from the unavailable unarmed perk |
| 1 `sword_mastery` | Sword Mastery / Владение мечами | combat; 8:6:4:2 | **ACTIVE** matching sword AP/damage and explicit item requirements |
| 2 `axe_mastery` | Axe Mastery / Владение топорами | combat; 8:6:4:2 | **ACTIVE** matching axe AP/damage and requirements |
| 3 `bludgeoning_mastery` | Bludgeoning Mastery / Владение дробящим оружием | combat; 8:6:4:2 | **ACTIVE** `blunt` family AP/damage and requirements |
| 4 `knife_mastery` | Knife Mastery / Владение ножами | combat; 8:6:4:2 | **ACTIVE** knife AP/damage and requirements |
| 6 `polearm_mastery` | Polearm Mastery / Владение алебардами и копьями | combat; 8:6:4:2 | **ACTIVE** polearm AP/damage and requirements |
| 7 `staff_mastery` | Staff Mastery / Владение посохами | combat; 8:6:4:2 | **ACTIVE** physical staff AP/damage; not elemental spell proficiency |
| 11 `extra_action_points` | Extra Action Points / Доп. очки действия | combat; 2:2:2:2 | **ACTIVE** adds one AP per effective point to turn budget |
| 20 `physical_damage_resistance` | Physical Damage Resistance / Сопротивление физ. поврежд. | combat; 6:4:2:2 | **ACTIVE** shared physical mitigation, including weaponless attacks |
| 23 `stealth` | Stealth / Скрытность | peace; 2:2:2:2 | **ACTIVE requirement** Permit I needs effective 20; no general hidden-identity probability |
| 24 `observation` | Observation / Наблюдательность | peace; 2:2:2:2 | **ACTIVE** eligible NPC search probability; no successful gathering loop |
| 26 `wanderer` | Wanderer / Странник | peace; 2:2:2:2 | **ACTIVE** fallback walking duration; explicit cell duration wins |
| 30 `self_healing` | Self-Healing / Самолечение | peace; 2:2:2:2 | **ACTIVE** elapsed out-of-combat HP recovery; does not cure injury records |
| 33 `fast_mana_regeneration` | Fast Mana Regeneration / Быстрое восстановление маны | peace; 2:2:2:2 | **ACTIVE** elapsed out-of-combat MP recovery |

Source weapon descriptions associate mastery with weapon use, lower AP and
greater physical damage. The local family readers implement that connection
using the user-authorized fitted coefficients, not recovered server code.
[Wiki: combat skills](http://wiki.neverlands.ru/wiki/Боевые_умения).

### Bounded family readers and requirement-only skills

These four registered definitions have local readers, but a reader alone is
not proof of a shipped source-equivalent weapon branch.

| ID / key | Local / source label | Pool; rate | Flag, actual scope and wiki description |
|---|---|---|---|
| 5 `throwing_mastery` | Throwing Mastery / Владение метательным оружием | combat; 8:6:4:2 | **PARTIAL / source inactive**: local `throwing` family adapter exists; wiki calls the source skill unused. Do not infer a released throwing system |
| 8 `exotic_weapon_mastery` | Exotic Weapon Mastery / Владение экзотическим оружием | combat; 6:4:4:2 | **PARTIAL / limited source use**: local `exotic` family adapter exists; wiki names an apprentice-scythe exception to otherwise unused mastery |
| 9 `two_handed_mastery` | Two-Handed Mastery / Владение двуручным оружием | combat; 10:8:6:4 | **PARTIAL** allocation and explicit requirement reader; wiki associates it with two-handed weapons. No separate local damage coefficient |
| 10 `dual_wielding` | Dual Wielding / Владение двумя руками | combat; 4:4:2:2 | **PARTIAL** allocation and explicit requirement reader; wiki associates it with certain knives. The local dual-weapon AP surcharge is fixed |

Source for these descriptions: [combat skills](http://wiki.neverlands.ru/wiki/Боевые_умения).
Two usable equipped weapons use their family mastery average; selecting a
second weapon does not switch damage to the separate `dual_wielding` value.

## 3. Partial definitions and profession counters

### Allocatable skills with missing downstream effects

All eleven rows below can receive points, display effective values and satisfy
an explicit registered-skill requirement. The flag concerns the named gameplay
effect. Adding a registry row did not implement every wiki rule.

| ID / key | Local / source label | Pool; rate | Flag and concise wiki description |
|---|---|---|---|
| 16 `fire_magic_resistance` | Fire Magic Resistance / Сопротивление магии огня | combat; 6:4:2:2 | **PARTIAL**; reduces fire spell damage |
| 17 `water_magic_resistance` | Water Magic Resistance / Сопротивление магии воды | combat; 6:4:2:2 | **PARTIAL**; reduces water spell damage |
| 18 `air_magic_resistance` | Air Magic Resistance / Сопротивление магии воздуха | combat; 6:4:2:2 | **PARTIAL**; reduces air spell damage |
| 19 `earth_magic_resistance` | Earth Magic Resistance / Сопротивление магии земли | combat; 6:4:2:2 | **PARTIAL**; reduces earth spell damage |
| 12 `fire_magic` | Fire Magic / Магия огня | combat; 8:6:4:2 | **PARTIAL**; learning and damage of fire spells |
| 13 `water_magic` | Water Magic / Магия воды | combat; 8:6:4:2 | **PARTIAL**; learning and damage of water spells |
| 14 `air_magic` | Air Magic / Магия воздуха | combat; 8:6:4:2 | **PARTIAL**; learning and damage of air spells |
| 15 `earth_magic` | Earth Magic / Магия земли | combat; 8:6:4:2 | **PARTIAL**; learning and damage of earth spells |
| 22 `caution` | Caution / Осторожность | peace; 2:2:2:2 | **PARTIAL**; identifying who used an effect on you |
| 27 `linguistics` | Linguistics / Языковедение | peace; 2:2:2:2 | **PARTIAL**; portal/dimensional scroll and textbook requirements |
| 34 `leadership` | Leadership / Лидерство | peace; 6:4:3:2 | **PARTIAL / source inactive**; wiki says unused |

Sources: [resistances](http://wiki.neverlands.ru/wiki/Сопротивления),
[magic skills](http://wiki.neverlands.ru/wiki/Магические_умения),
[peace skills](http://wiki.neverlands.ru/wiki/Мирные_умения).
Current injected magic attacks use `arcane` and `mind`, so the resolver's
element-key lookup does not apply the four registered elemental pairs to those
attacks. Portal/study progression, elemental schools and identity-reveal rolls
remain absent. Linguistics requirements on catalog content do not make an
unsupported scroll executable. No broader Leadership formula is invented.

### Profession counters

These **15 screenshot rows are separate from the 29 allocation definitions**.
Their four-digit display has no `/100`; the image is not evidence of a 9,999
cap. Local English descriptions below are documentation translations unless
the bounded runtime explicitly supplies a name/key.

Implemented adjacent behavior comes first. Wiki descriptions in the last
column concern the profession, not a claim that the counter grows locally.

Doctor qualification reads `Character#doctor_proficiency`: a nonnegative integer
at `metadata.profession_skills.doctor` plus usable equipped `doctor` or nested
`skill_bonuses.doctor` points. Broken/expired equipment contributes nothing.
For example, saved 90 + a usable +10 item qualifies for a Doctor-100 bag;
removing the item before accepting a paid quote makes that quote fail without
spending NV or a bag use. This does not spend Skills points, grant Healer or
create a license. Edit authored bag thresholds in `db/seeds/combat_care.rb`;
see [MEDICAL-01](FORMULAS.md#medical-01--treatment-and-licenses) and the
[Medical handbook](features/medical_care.md) before changing any consumer.

| Source counter | Local status / known storage | Wiki description |
|---|---|---|
| Торговля / Trading | **PARTIAL** `metadata.profession_skills.trading`, read by Shop resale; no automatic growth | Shop/player trade and market stalls |
| Доктор / Doctor | **ACTIVE bag qualification** through saved profession counter + usable equipment; use-growth remains absent | Injury treatment |
| Воровство / Thievery | **NOT_IMPLEMENTED** counter loop | Steal NV after victory |
| Каллиграфия / Calligraphy | **NOT_IMPLEMENTED** | Produce scrolls, books, runes |
| Ювелирное дело / Jewelry | **NOT_IMPLEMENTED** | Improve equipment with gems |
| Ремесленник / Craftsmanship | **NOT_IMPLEMENTED** complete profession loop | Make and repair equipment |
| Алхимия / Alchemy | **NOT_IMPLEMENTED** | Make potions and dyes |
| Развитие горного дела / Mining | **NOT_IMPLEMENTED** | Extract underground resources |
| Рыбалка / Fishing | **NOT_IMPLEMENTED** successful catch/growth; no-bait entry is bounded World behavior | Catch and process fish |
| Охота / Hunting | **NOT_IMPLEMENTED** profession loop; NPC search is separate | Hunt and process animals |
| Кулинария / Cooking | **NOT_IMPLEMENTED** | Prepare food and drinks |
| Лесозаготовка / Logging | **NOT_IMPLEMENTED** | Find and cut trees |
| Плотник / Carpentry | **NOT_IMPLEMENTED** | Process wood |
| Сталевар / Steelmaking | **NOT_IMPLEMENTED** | Refine ore and alloys |
| Травник / Herbalism | **NOT_IMPLEMENTED** successful gathering/growth | Discover and harvest plants |

Descriptions: [wiki peace skills](http://wiki.neverlands.ru/wiki/Мирные_умения).
The screenshot has Fishing `0272`, Hunting `0063` and zeros elsewhere; those
are source-player observations, not seed defaults. The user's confirmed
fishing rule allows starting without a learned Fishing value; tools/bait and
successful use-growth belong to [Professions](domains/professions.md).
Do not derive a local Fishing-perk prerequisite from the screenshot or the
wiki's general profession wording.

## 4. Allocation and business rules

Enter the owner profile → **Skills**. Plus/minus modify a pending preview;
Reset clears that preview. Save posts spend counts. Revisit/reload reads the
persisted character and current equipment. There is no automatic learned-skill
gain from an attack, block, dodge, walk, sale or treatment.

1. The controller resolves and authorizes the current character and applies
   gameplay availability guards. A foreign character cannot be allocated.
2. HTTP counts are normalized and bounded to `0..100` per key. They mean
   **number of spends**, not the desired final skill value.
3. `SkillAllocationService` locks/reloads the character, ignores unknown keys
   and nonpositive spends, and recomputes each requested increment sequentially.
4. It counts actual spends before the learned cap. If either pool is too
   small, the entire batch fails; it cannot commit combat changes while
   rejecting peace changes.
5. Success merges learned values, subtracts actual pool costs and clears the
   passive-skill cache. Empty/no-effective-change requests fail without charge.

The row lock prevents overspending under concurrency. A repeated successful
skill request can spend again if points remain: this endpoint does not carry
a universal idempotency token. Capped extra requests cost nothing. Perks have
different duplicate behavior because ownership is boolean; see [PERKS](PERKS.md#4-selection-and-business-rules).

Starter pools are 10 combat and two peace; starter perk points are separate.
Reaching level 1 adds four combat, three peace and one perk point. Grants vary
by level through [the complete progression table](FORMULAS.md#2-experience-levels-and-grants),
currently complete through 27. Changing the table does not retroactively grant
points or reprice saved allocations.

## 5. Formulas and effects on related systems

Let `B` be the saved learned value, `E` current equipment contribution and
`S = B + E` the effective value. Spending uses **B**; consumers generally use
**S**, then apply their own bounds. Do not apply a blanket effective cap of 100
or add equipment twice. Formula inputs come from server state.

| Area | Logic and consequence | Numerical owner |
|---|---|---|
| Allocation | `tier = min(floor(B/25),3)`; gain is `min(rate[tier],100-B)`; each accepted spend costs one assigned pool point | [SKILL-01](FORMULAS.md#skill-01--spending-learned-skill-points) |
| Weapon/fist attack | Matching effective mastery changes AP discount and fitted pre-mitigation damage; two weapons average their family masteries | [Combat inputs](FORMULAS.md#stat-03--combat-ratings-and-weapons), [Combat](FORMULAS.md#5-combat) |
| Turn capacity | `80 + level 5 bonus 10 + level 10 bonus 10 + S(extra_action_points)` | [Vitals/AP](FORMULAS.md#stat-02--vitals-capacity-and-action-points) |
| Physical mitigation | Resistance fraction `clamp(S/200,0,0.75)` multiplies post-armor physical damage by `1-fraction`; not a block roll | [Physical damage](FORMULAS.md#combat-03--physical-damage) |
| NPC loot | Chance multiplier `1 + S/(S+100)` at current calibration; entitlement/target eligibility checked separately | [Search](FORMULAS.md#reward-03--search-probabilities-and-amounts), [NPC](NPC.md#6-loot-and-experience) |
| Walking | Fallback `clamp(30-floor(clamp(S,0,100)*6/100),24,30)` seconds; positive authored cell duration overrides it | [Walking](FORMULAS.md#world-01--walking-time), [WORLD](WORLD.md) |
| Recovery | HP: `maxHP/600*(1+S/100)*fatigueFactor`; MP uses maxMP/900; elapsed accumulation retains fractional remainder | [Recovery](FORMULAS.md#recovery-01--elapsed-hpmp-regeneration) |
| Equipment and scroll permission | Compare effective registered skill with each explicit requirement at mutation time; skill bonuses alone do not bypass target, ownership or availability checks | [ITEMS](ITEMS.md#3-fields-slots-and-effective-properties), [SCROLLS](SCROLLS.md#4-server-admission-rules) |
| Profession and medical actions | Trading proficiency influences resale; Healer/license/bag checks use separate owners. Doctor thresholds are enforced; no general profession XP/yield formula executes | [Economy](FORMULAS.md#9-inventory-and-economy), [Medical Care](features/medical_care.md) |

Spending rules/AP conversions are captured; combat, loot and recovery
coefficients use the authorized [calibration](design/features/combat_calibration.md).
Premium widens eligible NPC levels/raises the XP cap; it does not directly
increase learned skills or replace Observation's chance calculation.
Skills affect the shared fight pipeline in [Arena](ARENA.md), wilderness PvE
and scroll PvP. They do not confer separate Arena-only damage formulas.

## 6. Use cases and cross-feature effects

These are **illustrative applications of current rules**, not new live fights.

| Use case and preconditions | Action → result | Downstream effect / failure boundary |
|---|---|---|
| Sword learned 24, equipment+50, two combat points | Spend twice: `24→32→38`; effective becomes 88, pool decreases 2 | Tier selection uses learned 24/32, never displayed 74/82. A third spend is rejected if no points remain |
| Stealth 18, one peace point, Permit I owned | Spend once →20; use targeted scroll | The skill threshold passes; level, target location, HP, reservation and scroll ownership still must pass. Fist Attack has no Stealth requirement |
| Level 17 with Extra AP 100 | Build ordinary combat profile →200 AP | More actions may fit; server still validates complete attack/block cost and target. A persisted fight-specific override can take precedence |
| Effective physical resistance 100, post-armor damage 200, other multipliers 1 | Resistance 50% →100 damage | Same calculation against NPC/player; a successful earlier block would instead prevent the hit |
| Eligible NPC row at 12% base chance, Observation 100 | Multiplier 1.5 →18% | Still probabilistic. Observation 200 →20%; no learned cap is reused as the effective loot cap. Ineligible NPCs remain ineligible |
| Wanderer 50, no cell override | Submit adjacent movement →27-second deadline | Raising skill after the accepted command does not shorten its persisted deadline; explicit cell duration takes precedence |
| maxHP 600, Self-Healing 100, fatigue≤50, eligible for recovery | Rate 2 HP/sec; 10 elapsed seconds recover 20, capped at max | Active combat blocks recovery. Full HP does not remove a persistent injury or its stat penalty |
| Fire Magic 100, current injected arcane attack | Save skill succeeds | No matching elemental consumer for that attack; do not promise extra damage |
| Doctor bag threshold authored, Healer/license present | Treatment uses existing medical validation | Effective Doctor must meet the bag threshold; a perk/license alone does not qualify. Failed treatment leaves injury, uses and NV unchanged |

## 7. UI, UX and artwork

The source screenshot uses two columns, section headings, colored bullets,
help icons, `[learned/100]` and a separately colored bonus, plus profession
counters and remaining pools. The wiki identifies red dots as inactive source
skills; this does not determine whether a local adapter exists.
[Wiki: numeric skill overview](http://wiki.neverlands.ru/wiki/Умение).

Local **Skills** follows the captured two-column order: combat, resistance and
magic on the left; peace skills and 15 profession counters on the right.
Narrow layouts stack the columns. Each allocatable row shows learned
`[NNN/100]`, a separate red signed equipment bonus, plus/minus and a next-spend
gain or MAX. The gain preview is not an equipment bonus. Source-number filler
has been removed; each adjustment button has a named keyboard-accessible label.

Professions display uncapped saved `metadata.profession_skills` counters as at
least four digits, without `/100` or allocation controls. Doctor alone has the
implemented equipment-bonus consumer; other visible counters do not invent
profession growth or new effects. Missing/invalid/negative counters display 0.
[ProfileCatalog](../app/lib/game/skills/profile_catalog.rb) owns presentation
order; PassiveSkillRegistry and profession owners retain gameplay authority.

Save success updates the Turbo `skill-allocation` frame and flash; HTML
requests redirect. Errors preserve persisted values and display feedback.
The normal Reset button only clears pending selections, not saved skills.
The existing Inventory reset-scroll compatibility path is described separately
in [SCROLLS](SCROLLS.md#7-peace-scrolls-and-purchased-licenses); it is not a
complete historical-spend refund or perk-respec system.

Screenshots remain [evidence-only assets](design/reference/character/observations/2026-09-14_skills_and_perks.md#artifacts-and-copy-boundary).
The tables use HTML/CSS and generate no runtime bitmap. Future UI/assets must
follow [ARTWORK](ARTWORK.md#skills-and-perks-presentation-reference) and the
[adaptive client rules](design/areas/game_client_layout.md#adaptive-ui-requirements).

## 8. Implementation and editing

| Owner | Responsibility and public boundary |
|---|---|
| [PassiveSkillRegistry](../app/lib/game/skills/passive_skill_registry.rb) | Source IDs, stable keys, labels, category/pool, rates and cap; `calculate_effect` is a zero-returning compatibility helper, not the gameplay engine |
| [SkillProgressionFormula](../app/lib/game/formulas/skill_progression_formula.rb) | Pure tier/gain/spend calculation; validates range/rate; no record queries |
| [SkillAllocationService](../app/services/characters/skill_allocation_service.rb) | `new(character:).call(allocations:)` → updated skills/remaining pools or AllocationError; locked character write |
| [Character](../app/models/character.rb) | Learned/effective readers, equipment bonus composition, weapon-family mapping, AP and stat projections |
| [PassiveSkillCalculator](../app/lib/game/skills/passive_skill_calculator.rb) | Cached learned-value summary; not an equipment-aware substitute for Character's effective reader |
| [CharactersController](../app/controllers/characters_controller.rb) | Owner-only GET/PATCH `/characters/:id/skills`, normalization, availability and Turbo/HTML responses |
| [Skill form](../app/views/characters/_skill_allocation.html.erb), [Stimulus](../app/javascript/controllers/skill_allocation_controller.js) | Pending spend preview, undo/reset and submit; never authoritative pool or formula state |
| [Progression Catalog](../app/lib/game/progression/catalog.rb), [LevelUpService](../app/services/players/progression/level_up_service.rb) | Level grants from configuration; locked XP/grant/wallet changes |
| [RequirementChecker](../app/services/game/inventory/requirement_checker.rb) | Recognized item stat/skill requirements and separate effective Doctor proficiency; unknown keys currently are not enforced |
| [VitalsService](../app/services/characters/vitals_service.rb) | `tick_regeneration` locks character and persists elapsed capped recovery/fractions |

To edit a skill, locate its **stable key**, preserve identity, then distinguish
the requested change:

1. **Label/rate/category:** edit the registry and its formula tests. Rate
   changes affect future spends; existing learned values are not repriced.
   Moving pools needs an explicit policy for already spent points.
2. **Effect:** change the existing consumer/calibration, supplying effective
   values once. Inventory bonus parsing, combat snapshots, active movement
   deadlines and elapsed recovery have different timing; inspect the consumer
   before promising immediate effects on an already active action.
3. **Equipment bonus/requirement:** follow [ITEMS editing](ITEMS.md#6-editing-recipes).
   A spelling not recognized by the reader can display without enforcement.
4. **New source entry:** record source name/ID/category/rate and missing details,
   then add the stable definition, owner/controller allowance through the
   existing registry, explicit consumers and focused tests. Registration alone
   is insufficient to mark an effect ACTIVE. No parallel skill engine is needed.
5. **Profession:** extend the profession owner and its use-growth action, not
   the allocatable registry. Keep proficiency, perk, qualification and timed
   license separate; specify missing thresholds before claiming treatment parity.

There is no general skill-admin editor or automatic data migration from a
wiki page. Operators must use a reviewed migration/repair for intended existing
character changes. Reload cached catalogs/processes when changing their
definitions; a documentation edit itself changes no character or combat state.

## 9. Verification, gaps and maintenance

Protecting tests include [registry](../spec/lib/game/skills/passive_skill_registry_spec.rb),
[tier formula](../spec/lib/game/formulas/skill_progression_formula_spec.rb),
[allocation service](../spec/services/characters/skill_allocation_service_spec.rb),
[owner requests](../spec/requests/characters/skills_spec.rb),
[equipment-aware allocation](../spec/requests/skill_allocation_equipment_spec.rb),
[Skills UI](../spec/system/skill_allocation_spec.rb),
[elapsed recovery](../spec/services/characters/vitals_elapsed_recovery_spec.rb)
and [level grants](../spec/services/players/progression/level_up_service_spec.rb).
Consumer-specific checks/acceptance remain in the linked Combat, World,
Inventory, Medical and Character handbooks. These pointers are not a claim
that each historical suite ran again; current results are in [September16 acceptance](features/acceptance/2026-09-16_primary_list/README.md).

Remaining boundaries: `[IMPL]` successful profession growth, elemental schools and named missing
effects; `[EVIDENCE]` unrecovered exact source coefficients and unsupported
branches. Source-inactive Throwing/Leadership must not be invented into active
Neverlands features. Existing fitted active formulas remain authorized.

When skills, grants, rates, bonuses, requirements, consumers or UI change,
update this book, [FORMULAS](FORMULAS.md), the responsible handbook and the
actually affected [PERKS](PERKS.md), [COMBAT](COMBAT.md), [SCROLLS](SCROLLS.md),
[NPC](NPC.md), [ITEMS](ITEMS.md), [WORLD](WORLD.md) or [ARTWORK](ARTWORK.md)
sections in the same task. Recheck examples and status flags under
[the maintenance contract](DOCUMENTATION.md#22-change-triggered-documentation-updates).
