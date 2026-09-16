# Primary Stats Guide

Reviewed against the working tree and Neverlands wiki on **2026-09-15**.
This book explains every primary stat, its source definition, local keys,
derived quantities, consumers and editing rules. [CHARACTER](CHARACTER.md)
explains the whole build and development lifecycle; this book supplies the
parameter-level detail. [MODIFIERS](MODIFIERS.md) explains the four combat
ratings; [FORMULAS](FORMULAS.md) owns numerical rules and tuning.

Start at the [Character domain](domains/character.md),
[source summary](design/reference/character/README.md),
[progression design](design/features/progression_stats_skills.md),
[vitals design](design/features/character_vitals.md) and
[MVP boundary](design/launch_mvp_plan.md). The
[Character Progression handbook](features/character_progression.md) owns
current allocation/UI guarantees and acceptance.

## Contents

1. [Scope and evidence](#1-scope-and-evidence)
2. [Primary stats and linked definitions](#2-primary-stats-and-linked-definitions)
3. [Player flows and business rules](#3-player-flows-and-business-rules)
4. [Formulas and effects](#4-formulas-and-effects)
5. [UI, UX and artwork](#5-ui-ux-and-artwork)
6. [Implementation and state ownership](#6-implementation-and-state-ownership)
7. [Editing and extension recipes](#7-editing-and-extension-recipes)
8. [Use cases and cross-feature effects](#8-use-cases-and-cross-feature-effects)
9. [Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope and evidence

Five allocatable primary stats and their current physical-combat, requirement,
resource and capacity consumers are implemented. Wisdom, resets, general buff
composition and several published secondary effects are not. A supported
numeric field does not establish every Neverlands effect of that field.

| Label | Meaning in this book |
|---|---|
| Published | A rule/definition in the Neverlands wiki; not necessarily tested live |
| Observed | Preserved source UI or gameplay capture linked from the source index |
| Implemented | An identified local reader/writer provides the described behavior |
| Fitted | An authorized local approximation of a hidden source equation |
| Partial / source-only | Some consumers or the entire effect are absent locally |

The [linked-definition observation](design/reference/character/observations/2026-09-15_stats_guide_linked_definitions.md)
records article revisions, redirects and coverage. Its boundary includes all
gameplay-definition links on [Стат](http://wiki.neverlands.ru/wiki/Стат), not
every descendant item/quest article. Linked Умение and Навык catalogs remain in
[SKILLS](SKILLS.md) and [PERKS](PERKS.md); the linked XP table remains in
[FORMULAS: progression](FORMULAS.md#2-experience-levels-and-grants).

## 2. Primary stats and linked definitions

### Implemented stats first

| Source / local name | Stored key; accepted English alias | Published meaning | Current local consumers |
|---|---|---|---|
| [Сила / Strength](http://wiki.neverlands.ru/wiki/Сила) | `strength` | Physical and damaging-scroll power; lesser capacity contribution than Health | Fitted physical attack, capacity, item requirements; no damaging-scroll engine |
| [Ловкость / Dexterity](http://wiki.neverlands.ru/wiki/Ловкость) | `dexterity` | Connecting attacks and evading enemy attacks | Opposed accuracy, dodge and physical block; item requirements |
| [Удача / Luck](http://wiki.neverlands.ru/wiki/Удача) | `luck` | Critical attack/defense; the Stat page also links Accuracy | Opposed accuracy and critical probability through attacker/defender ratings; item requirements |
| [Здоровье / Health](http://wiki.neverlands.ru/wiki/Здоровье) | `vitality`; `health` | HP, mass and hidden armor; required by higher-level gear | Allocated base HP, effective capacity, fitted hidden physical armor and item requirements |
| [Знания / Knowledge](http://wiki.neverlands.ru/wiki/Знания) | `intelligence`; `knowledge` | MP, primitive/elemental magic, books/gear, Doctor and Alchemy qualifications | Allocated base MP, bounded magic attack, equipment and healer-bag requirements; no full Alchemy or source HP-restoration action |

The persisted vocabulary uses `vitality` and `intelligence`; player-facing
labels use Health and Knowledge. Case/spacing normalization is supported for
recognized English keys. Russian labels and `wisdom` are not allocation keys.
No class-specific stat growth is implied: levels grant spendable points.

Strength does not raise Accuracy directly. Luck does not multiply all outgoing
damage: locally it changes critical probability, and a critical uses the fitted
damage multiplier. Health is not HP, Knowledge is not MP, and Fortitude is not
Health. The Stat page's build recommendations and Dexterity's 2008–2011 history
are descriptive/historical, not a local auto-allocation rule or current `/3`
coefficient.

### Source-only stat: Wisdom

[Мудрость / Wisdom](http://wiki.neverlands.ru/wiki/Мудрость) affects primitive
magic in the source and is not ordinary player training. The article describes
privileged characters and historical council/robe/wig exceptions. Locally there
is no Wisdom point pool, allocation, equipment-to-combat reader or spell effect.
A zero player display or NPC inspection metadata is presentation only. Adding a
sixth generic player stat would contradict the established boundary.

### Quantities linked from the Stat page

| Linked concept | Definition and current boundary | Detailed owner |
|---|---|---|
| [Удар → Урон](http://wiki.neverlands.ru/wiki/Урон) | Damage is an outcome of stats, gear, mastery, defense, artifacts and hidden level factors; the displayed attack input is not promised damage | [COMBAT](COMBAT.md), [physical equation](FORMULAS.md#combat-03--physical-damage) |
| [Жизнь / HP](http://wiki.neverlands.ru/wiki/Жизнь) | Current/max resource; zero defeats a participant. Published low-HP combat degradation is absent locally | [CHARACTER](CHARACTER.md), [MEDICAL](MEDICAL.md) |
| [Мана / MP](http://wiki.neverlands.ru/wiki/Мана) | Current/max spell resource; zero MP does not prevent physical actions | [vitals](FORMULAS.md#stat-02--vitals-capacity-and-action-points), [magic](FORMULAS.md#combat-04--magic-attacks-and-barriers) |
| [Масса / capacity](http://wiki.neverlands.ru/wiki/Масса) | Maximum carried weight, distinct from occupied slots; source bonuses and overload rules exceed local hard-cap admission | [capacity rules below](#capacity-and-overload), [ITEMS](ITEMS.md), [ECONOMY](ECONOMY.md) |
| [Класс Брони / Armor](http://wiki.neverlands.ru/wiki/Класс_Брони) | Equipment defense, with a hidden Health factor locally applied to physical mitigation; published elemental armor contribution missing | [MODIFIERS: adjacent inputs](MODIFIERS.md#adjacent-inputs-are-not-extra-modifier-categories) |
| Уловка, Сокрушение, Точность and Модификатор | Percentage-labelled ratings; opposed chances require both participants | [MODIFIERS](MODIFIERS.md) |
| [Обнул / reset](http://wiki.neverlands.ru/wiki/Обнул) | Redistributes learned development; partial local item handler, no complete School/reset flow | [reset boundary below](#reset-and-temporary-effects) |
| [Бафы и дебафы](http://wiki.neverlands.ru/wiki/Бафы_и_дебафы) | Temporary positive/negative effects with their own lifecycle | [effect boundary below](#reset-and-temporary-effects), [MODIFIERS](MODIFIERS.md#temporary-effect-boundary) |
| [Примитивная магия](http://wiki.neverlands.ru/wiki/Примитивная_магия) | Knowledge/artifacts and chosen MP, with nonlinear damage | [COMBAT](COMBAT.md); fixed-cost local subset is partial |
| [Стихийная магия](http://wiki.neverlands.ru/wiki/Стихийная_магия) | Mastery, Knowledge, gear/book/perk and learned spells; elemental defenses | [SKILLS](SKILLS.md), [PERKS](PERKS.md), [magic/level boundary below](#magic-and-level-boundaries) |

## 3. Player flows and business rules

### Allocation and composition

1. Earn XP through an authoritative reward owner. The progression table grants
   stat, combat-skill, peace-skill and perk points separately. Gaining a level
   does not choose a primary stat for the player.
2. Open Character → Stats. Plus/minus controls edit an unsaved preview;
   Reset on that form clears the preview, not previously saved investments.
3. Save additions. The server checks ownership and recognizes supported keys;
   the HTTP parser converts each submitted value to an integer and clamps it
   to 0–100 before combining aliases. The allocation service keeps positive
   additions and rejects an empty selection or spending beyond available points
   under the character lock. Unsupported/nonpositive entries are ignored rather
   than making an otherwise valid selection fail. Rejection leaves saved stats,
   points and vitals unchanged. A valid subsequent spend is a new allocation,
   not a replay-protected purchase.
4. Persist additions and debit the stat pool together. Recalculate saved HP/MP
   maxima from allocated Health/Knowledge; clamp current resources if needed,
   without refilling them. Revisit/reload reads persisted development.
5. Equipment, the implemented More Strength perk and active injuries affect
   effective stats without rewriting allocated points. Consumers read those
   projections for requirements, capacity and combat.

[ITEMS](ITEMS.md) owns equip/use eligibility and broken/expired item checks.
Current passive stat aggregation excludes broken equipment; it does not itself
filter expiry. Do not infer that an expired item already worn automatically
loses every contribution. The source specifically says gear cannot increase
Health; the generic local parser still accepts Health aliases, so that parser
capability is not authority to author Health-boosting gear.

### Reset and temporary effects

**Source reset and partial local handler:** the wiki permits unlimited free School resets through
level 5; paid abilities, quest rewards, seasonal purchases and tradable scrolls
are other routes. The scroll requires level 5. Some variants include a totem
change; a reset also permits one appearance/avatar change. Profession learning
survives, but effective qualification depends on reselecting its profession
perk. The article warns about reset bugs under buffs; that warning is not a
local data-loss requirement. [SCROLLS](SCROLLS.md) owns the supplemental
`reset_scroll`: Inventory Manager already handles `reset_allocation`, clearing
allocated stats/passive skills and refunding the corresponding point pools.
That partial item handler does not implement the complete source School,
profession/perk reselection, totem or appearance workflow. [PERKS](PERKS.md)
owns reselection; the reset scroll has no ordinary Shop acquisition.

**Partial temporary effects:** local injuries have authoritative penalties and
expiry through [MEDICAL](MEDICAL.md). Consumables restore supported resources;
they do not constitute a general timed stat-buff engine. Source potions, food,
scrolls, clan/holiday effects and paid bonuses must each have a real reader,
clock, stacking rule and expiry before being called implemented. Profile
`active_effects` metadata is not such an engine.

## 4. Formulas and effects

The following are applications of current formulas, not newly observed damage
measurements. Full inputs, rounding and coefficients remain in
[FORMULAS, sections 3–5](FORMULAS.md#3-character-stats-and-equipment).

| Quantity | Current rule and consequence |
|---|---|
| Base stat | `1 + allocated points` |
| Effective stat before injury | Base + supported nonbroken equipped bonuses + applicable perk; only More Strength currently contributes `floor(level/2)` |
| Injured effective stat | Sum active penalties, clamp 0–90%; for a positive penalty use `max(floor(before_injury*(100-P)/100),1)` |
| Saved base HP / MP | `5*base Health` / `7*base Knowledge`; effective maxima add explicit equipped HP/MP bonuses |
| Carrying capacity | `5*effective Strength + 10*effective Health + 10*level` |
| Physical power | Strength enters the fitted shared attack equation with weapon damage, mastery, artifact and fatigue factors |
| Hit/dodge/crit/block | Dexterity, Luck and the relevant equipment ratings enter different opposed equations; see [MODIFIERS](MODIFIERS.md#4-formulas-and-gameplay-effects) |
| Hidden physical armor | Raw armor multiplied by `1 + .05*floor(clamp(effective Health,0,150)/30)` before other mitigation factors; the source gives approximate strength/range, while steps/cap are the local fit |

Health 29→30 with raw armor 100 changes this hidden armor contribution
100→105. Displayed item armor remains 100; physical block rating is independent.
Health 150 gives 125; zero raw armor remains zero. Injury can lower effective
Health across a breakpoint without changing saved HP maximum. These are
separate consumers, not a single universal defense stat.

Base Knowledge 20 gives saved max MP 140. An item with `knowledge: 5` changes
effective Knowledge to 25, but does not rewrite that saved maximum to 175.
An explicit `mp: 35` bonus would make effective maximum 175. The source's
Knowledge/equipment resource relationship is broader than this local split;
do not disguise that gap with an invented item bonus.

### Capacity and overload

Capacity and item weight are different numbers; slots impose another limit.
Acquisition/transfer currently rejects a projected weight above capacity.
Existing weight can nevertheless become excessive after an injury or unequip
lowers capacity. There is no implemented graduated overload movement, fatigue,
work or Arena-admission effect. The published tier table and Merchant exception
are preserved at
[FORMULAS: source-only overload](FORMULAS.md#source-only-overload-and-merchant-capacity).

The Mass article also supplies **source-only bonus families**, not local stock:

| Source bonus | Published magnitude / distinction |
|---|---|
| Strong Back boolean / clan version | +20% / +10–50%; separate systems |
| Equipment and containers | Strength or direct mass; ordinary backpack examples 2,500–5,000, gift bags 125–250, ancient pieces 250 |
| Consumables | Strong Back potion +200 or +300 for 20 h; fish sticks +500 for 3 h; meat pie +1,000 for one day |
| Timed services | Emerald Shop +1,000 for 10 days; Temple +50% for 5 days; seasonal service +1,000 for 21 days |
| Premium backpacks | 30-day bonuses +300/500/1,000/2,000/3,000; source prices 1/2/5/7/10 DNV |
| Merchant/Traveler equipment | 30-day Merchant Bag +750 mass and +50 Trading; Traveler backpack +1,000 mass; profession-tool-compatible shield-slot examples |

These examples are catalog research, not a supported purchase recipe. Local
capacity has no generic direct-mass, Strong Back or premium-container multiplier.
[PERKS](PERKS.md) and [ITEMS](ITEMS.md) own activation/content; [ECONOMY](ECONOMY.md)
owns prices and payments when such products are actually implemented.

### Magic and level boundaries

- Knowledge's published combat HP-restoration gate is native
  `Knowledge >= 2*(level+3)`: level 17 needs 40. Perks/buffs are excluded;
  the source leaves equipment qualification less clear. Automatic MP cost,
  fatigue-limited restoration and the exact conversion remain outside the
  local action set. Doctor bag requirements are a separate implemented gate.
- Primitive magic uses chosen MP (source minimum 5), Knowledge and artifacts;
  damage is nonlinear in MP. The local action catalog supplies fixed-cost
  attacks/barriers and fitted scaling. A mana selector does not establish the
  complete source formula.
- Elemental magic combines school mastery, Knowledge, equipment/books, perks
  and learned spells. The source describes nominal level-10 access, adjacent
  school pairings, opposing schools, seasons and two available spell tiers;
  planned higher tiers are historical plans, not implemented content. Full
  magic remains beyond the physical MVP boundary.
- Levels change local XP/grants, AP thresholds, capacity, perk effects and
  allowed wilderness group size. The wiki's additional hidden damage/defense
  level coefficients are not recovered. Its separate
  [technique success table](FORMULAS.md#source-only-level-sensitive-techniques)
  applies to a limited class of abilities, not all physical attacks.

## 5. UI, UX and artwork

Stats presents the five primary values with available points and allocation
controls. The shared character sheet combines effective stats, equipment,
resource bars and linked development pages. Public profile/fight cards expose
inspection values; they do not reveal the opponent-specific roll result.

[Character Progression](features/character_progression.md) owns controls,
validation feedback, keyboard/Hotwire behavior and recorded acceptance;
[Inventory](features/player_inventory.md) owns equipment presentation.
The shared sheet is
[`_neverlands_character_sheet.html.erb`](../app/views/shared/_neverlands_character_sheet.html.erb).
[ARTWORK](ARTWORK.md) owns player silhouettes/avatars and item production
specifications; [ITEMS](ITEMS.md#5-artwork-and-presentation) maps item images.
Stats and modifier values are text, not new generated images. This guide adds
no runtime artwork or changed UI.

## 6. Implementation and state ownership

| Owner | Responsibility and timing |
|---|---|
| [Character](../app/models/character.rb) | Saved allocations/resources/pools; effective stat and equipment readers, base-vital recalculation and capacity |
| [CharactersController](../app/controllers/characters_controller.rb) / [CharacterPolicy](../app/policies/character_policy.rb) | Current-player route authorization, submitted allocation parsing, response and action availability |
| [Characters::StatAllocationService](../app/services/characters/stat_allocation_service.rb) | `call(allocations:)`: locked validation, point debit, allocation/vital save; result includes allocation and remaining points |
| [StatBlock](../app/lib/game/systems/stat_block.rb) | In-memory calculation value object; its mutation helper is not a persisted buff workflow |
| [InventoryItem](../app/models/inventory_item.rb) | Template/instance effective properties; equipment changes feed future reads |
| [CombatAttributes](../app/services/arena/combat_attributes.rb) | Shared player effective inputs and NPC authored/snapshotted inputs |
| [Calibration](../app/lib/game/combat/calibration.rb) / [config](../config/gameplay/combat_calibration.yml) | Pure fitted calculations and numerical settings |
| [Inventory manager](../app/services/game/inventory/manager.rb) | Admission against current weight/slot capacity |

The older `Players::Progression::StatAllocationService` is not the controller's
current allocation owner. Extend the routed `Characters` service, not a second
pipeline. Changes to allocated stats/perks/equipment/injuries affect subsequent
effective reads; reward/grant writers and stored maxima remain distinct.
Ordinary combat budgets are stored in participation profiles; player combat
attributes are read live and unarmed budgets are recalculated. Mid-combat
allocation/profile consistency remains an audit concern, not a documented
freeze guarantee. NPC inspection Wisdom/HP does not become player-stat input:
explicit NPC `stats.health` supplies Health, with no inference from HP.

## 7. Editing and extension recipes

1. **Change an existing coefficient:** edit the existing calibration YAML and
   calculator, not a controller/view or a second Arena/Nature formula. Keep the
   source value versus fitted rounding clear. Reload/restart app and workers
   for cached configuration; changes affect subsequent calculations, not old
   logs. Update FORMULAS, STATS, MODIFIERS and affected Combat acceptance.
2. **Change a stat grant:** edit the progression table/catalog, preserving the
   published cumulative thresholds and one-time grant transition. Editing a
   table does not retroactively rewrite existing players' allocated points.
   Follow [CHARACTER](CHARACTER.md#7-editing-and-extension-recipes).
3. **Add item/NPC input:** use existing effect keys and level-profile fields.
   Equipment imagery is not an effect; NPC gear decoration does not sum player
   item bonuses. Validate the exact reader, requirement and authored value in
   ITEMS/NPC and their specs. Do not author Health equipment merely because an
   alias parser accepts it.
4. **Implement a source-only effect:** start from the source coverage record,
   identify the existing consumer and missing coefficient, then add its
   bounded writer/reader, validation, persistence/expiry and tests. New overload,
   reset or buff mechanics need their actual World/Inventory/Progression owners.
   Adding a JSON field or a documentation row alone is insufficient.

There is no general primary-stat formula editor in the player UI. Operator
changes to saved points must preserve progression accounting and existing
records. Use the [content guide](guides/managing_game_content.md) for supported
authored-content operations.

## 8. Use cases and cross-feature effects

Examples are illustrative applications of current code unless labelled source-only.

| Preconditions → action | Authoritative result and related effects |
|---|---|
| Health 20, HP 40/100, one point → allocate Health | Base Health 21, max HP 105, current HP still 40; capacity +10 absent other changes. [Medical recovery](MEDICAL.md) uses the resource separately. |
| Strength 20, Health 30, level 5, no modifiers | Capacity `100+300+50 = 450`. A new item exceeding this cap is rejected; a later stat penalty can leave existing weight over capacity without a current walking penalty. |
| Effective Strength/Health 20/30 → acquire a 15% injury | They become 17/25 after flooring. Physical power, Health armor and capacity can fall. Restoring HP does not remove the injury; healer treatment/expiry does. |
| Same saved build → equip valid Dexterity/Luck item | Future shared PvP/PvE rolls consume changed ratings. It does not guarantee a hit, change the selected block zone or add a separate Arena formula. |
| Bag's Doctor threshold met, Knowledge below its requirement → treat | [Medical](MEDICAL.md) rejects treatment; sufficient HP or a Healer perk alone does not supply Knowledge. |
| Buy an attack scroll with sufficient Strength | [SCROLLS](SCROLLS.md) still checks level, skill, ownership and target state. Strength itself neither authorizes PvP nor makes the initiation scroll deal damage. |
| Earn a level → inspect World/Inventory/new fight | Table grants and AP/level capacity inputs change; wilderness roster ceiling may change. No automatic stat allocation, full heal or universal level damage multiplier is invented. |
| Source-only low HP/overload effect or complete reset flow | Low-HP stat penalties and overload timing remain absent. Supplemental reset-allocation handling exists, but the complete source reset workflow does not. See the reset boundary above. |

## 9. Verification, gaps and maintenance

Behavior is protected by [allocation specs](../spec/services/characters/stat_allocation_service_spec.rb),
[character requests](../spec/requests/characters_spec.rb),
[model combat-input specs](../spec/models/character_combat_inputs_spec.rb),
[mana specs](../spec/models/character_mana_spec.rb),
[calibration specs](../spec/lib/game/combat/calibration_spec.rb) and
[progression system specs](../spec/system/inventory_progression_spec.rb).
Recorded local stat/roster browser acceptance remains in
[World](features/world.md#september-15-stat-and-roster-acceptance) and
[Combat](features/arena_combat.md#september-15-stat-and-roster-acceptance).
Creating this guide does not rerun those tests or establish new live evidence.

- **[IMPL]** Source overload tiers/bonus capacity, reset flows, most stat perks,
  low-HP combat penalties and general temporary effects are absent. Known
  formulas are preserved separately from missing coefficients.
- **[IMPL]** Gear-derived Knowledge does not automatically add its 7-per-point
  MP; generic Health equipment remains technically accepted despite the source
  restriction. Passive equipped-item expiry is not a universal filter.
- **[EVIDENCE]** Hidden level coefficients, low-HP penalty magnitude,
  overkill-versus-heal ordering, and exact source rounding/stacking remain
  uncertain. The Life page's `damage > 2*HP` claim does not resolve whether HP
  means current or maximum or how simultaneous restoration is ordered.
- **Partial/post-MVP:** full magic, including Knowledge-based restoration,
  variable-MP damage and elemental armor, retains the boundary in COMBAT.

Maintain definitions, accepted keys, active consumers, examples and source-only
flags whenever stats, grants, requirements, equipment, injuries or formulas
change, following the [documentation update rules](DOCUMENTATION.md#22-change-triggered-documentation-updates).
Update the relevant handbook and direct consumers in the same task.
