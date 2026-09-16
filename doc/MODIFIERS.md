# Combat Modifiers Guide

Reviewed against the working tree and Neverlands wiki on **2026-09-15**.
This book explains the four percentage-labelled modifier ratings, their source
names, player/NPC inputs, shared combat consumers and editing rules.
[STATS](STATS.md) explains primary parameters; [CHARACTER](CHARACTER.md) explains
build composition; [FORMULAS](FORMULAS.md) owns numerical equations and tuning.

Use the [Character](domains/character.md) and [Combat](domains/combat.md) domain
chains, the [linked-definition evidence](design/reference/character/observations/2026-09-15_stats_guide_linked_definitions.md),
[combat calibration design](design/features/combat_calibration.md),
[MVP scope](design/launch_mvp_plan.md) and [Combat handbook](features/arena_combat.md).
[COMBAT](COMBAT.md) owns fight state, action validation and results. A modifier
changes a calculation input; it does not authorize an action or change teams.

## Contents

1. [Scope and evidence](#1-scope-and-evidence)
2. [Modifier catalog and adjacent inputs](#2-modifier-catalog-and-adjacent-inputs)
3. [Composition and player flows](#3-composition-and-player-flows)
4. [Formulas and gameplay effects](#4-formulas-and-gameplay-effects)
5. [UI, UX and artwork](#5-ui-ux-and-artwork)
6. [Implementation and state ownership](#6-implementation-and-state-ownership)
7. [Editing and extension recipes](#7-editing-and-extension-recipes)
8. [Use cases and cross-feature effects](#8-use-cases-and-cross-feature-effects)
9. [Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope and evidence

The wiki's [Модификатор](http://wiki.neverlands.ru/wiki/Модификатор) defines four
ratings: Crushing, Accuracy, Evasion and Fortitude. These all have local physical
combat consumers. Source definitions and equipment/stat dependencies are known;
the numerical opposed equations are authorized local fits, not recovered source
code. Source potion, clan, holiday and other temporary rating bonuses are only
partially represented by local systems.

The [September 15 audit](design/reference/character/observations/2026-09-15_levels_stats_and_modifiers.md)
and [linked-page follow-up](design/reference/character/observations/2026-09-15_stats_guide_linked_definitions.md)
preserve source provenance. The source's historical remarks about rating
importance do not establish a new current coefficient. Published, observed,
implemented, fitted and source-only labels have the meanings in
[STATS](STATS.md#1-scope-and-evidence).

## 2. Modifier catalog and adjacent inputs

### Four implemented rating consumers

| Neverlands / local label | Player equipment keys | NPC display-stat key | Published meaning → current consumer |
|---|---|---|---|
| Сокрушение / Crushing | `crushing` | `crushing` | Luck-linked critical offense → adds to attacker critical rating |
| Точность / Accuracy | `accuracy` | `accuracy` | Dexterity/Luck-linked ability to connect attacks → attacker hit, opposed dodge and physical block calculations |
| Уловка / Evasion (also Dodge locally) | `evasion`, `dodge` | `evasion` | Dexterity-linked evasion → defender hit resistance and dodge rating |
| Стойкость / Fortitude | `fortitude` | **`endurance`** | Luck-linked critical resistance → defender critical rating; source mentions possible additional unknown dependencies |

NPC `endurance` means Fortitude in this adapter. It is not the primary Health
stat, HP, fatigue or general physical damage reduction. Player equipment uses
`fortitude`; copying the NPC key onto a player item does not activate it.
The NPC adapter's fallback `stats.crit_chance` is a legacy **rating input**,
not a stored final probability. Use explicit documented display-stat fields for
new content; [NPC](NPC.md) owns profile composition and snapshots.

The four modifier definitions are not the four numeric-skill categories.
[SKILLS](SKILLS.md) covers Умения (combat/resistances/magic/peace);
[PERKS](PERKS.md) covers Навыки (boolean choices).

### Adjacent inputs are not extra modifier categories

| Quantity | Current meaning and reader |
|---|---|
| Armor / Класс Брони | Player `defense`, `armor`, `armor_class` sum into raw equipped armor. Health's hidden factor affects physical mitigation, not displayed armor or the independent block rating. NPC armor is authored. |
| Penetration | Player `armor_pierce`, `armor_piercing`; NPC `armor_penetration`. Opposes armor and contributes to physical block penetration. It is not Accuracy or an automatic shield break. |
| Physical resistance | Separate effective numeric skill and combat mitigation input; not Fortitude |
| Elemental resistance | Element skill plus supported elemental/all-resistance item ratings in the bounded magic reader; not a fifth core modifier |
| Attack power / weapon damage | Damage inputs rather than hit chance; item min/max and mastery affect shared physical power |
| AP and MP | Package budgets/resources; they determine legal actions and costs, not the displayed four ratings |

[Armor](http://wiki.neverlands.ru/wiki/Класс_Брони) publishes an elemental-magic
contribution of 10% armor, with elemental resistance also involved. The bounded
local magic resolver currently omits armor. Exact ordering remains uncertain;
that omission must not be documented as a source rule.

## 3. Composition and player flows

### Equipment and requirements

An item definition's `stat_modifiers` is merged with an owned instance's
`properties.stat_modifiers`, then `properties.effects`. Later identical raw
keys override earlier ones. Supported effect names are normalized, and
nonbroken equipped items contribute to Character's readers. Distinct aliases
that a reader sums can both contribute: prefer one canonical key for each
effect to avoid accidental duplicate bonuses. See [ITEMS](ITEMS.md#3-fields-slots-and-effective-properties).

Numeric strings such as `"+50%"` yield **50 rating units**. They do not multiply
the current rating by 1.5 and do not guarantee a 50% final chance. Primary-stat
bonuses use their own integer-valued composition. Unsupported keys are not
made effective by being present in JSON or an item description.

The player acquires a valid item, equips it through Inventory after server
requirement/slot checks, and sees the effective build on the character sheet.
Subsequent combat calculations read those inputs. Unequipping or breaking an
item removes the relevant contribution; saved stat allocations and old logs
are unchanged. Equip/use expiry checks do not imply the passive aggregation
filters every already-equipped expired item.

### Temporary-effect boundary

The source [buff/debuff article](http://wiki.neverlands.ru/wiki/Бафы_и_дебафы)
describes effects on ratings as well as stats, mass, movement/work and XP.
Local `metadata.active_effects` and its displayed `/99` count are presentation,
not a generic application/stacking/expiry engine. Injuries have their own
implemented model and reduce primary stats, indirectly altering derived
ratings; they do not uniformly subtract the same percentage from every
equipment modifier.

Published but **source-only** details include:

- A 99-effect limit including injuries; food/alcohol reserve additional effect
  slots, poison has an exception and turn-limited effects are separate. The
  source also describes replacing a weaker injury at the injury limit.
- Temporary clan/holiday/quest bundles; one weekend example combines
  +150 to each core rating, +50 AP, different PvP/PvE XP percentages and a
  Wanderer bonus. These are examples, not universal weekend configuration.
- Imps changing timed work by ±10%, with up to five of each kind; instant
  Doctor/Trading/Hunting actions are excluded. They are not removable by the
  ordinary cleansing scroll described there.

Adding a timed rating effect requires a real authoritative owner and its
stacking/cap/expiry rules. [MEDICAL](MEDICAL.md), [SCROLLS](SCROLLS.md),
[SKILLS](SKILLS.md) and [PERKS](PERKS.md) retain their separate current consumers.

## 4. Formulas and gameplay effects

[FORMULAS: opposed chances](FORMULAS.md#combat-02--hit-dodge-critical-and-physical-block)
owns the complete equations, clamps and action/body adjustments. The central
comparison is a fitted rating difference, not a displayed percentage roll:

```text
opposed(a,b,scale) = scale * (a-b) / (abs(a)+abs(b)+100)
attack accuracy = 3*attacker Dexterity + 2*attacker Luck + item Accuracy
hit resistance = 2*defender Dexterity + item Evasion
dodge rating = 5*defender Dexterity + item Evasion
critical offense = 5*attacker Luck + item Crushing
critical defense = 5*defender Luck + item Fortitude
```

| Outcome | Base / scale / bounds before action-specific details | Meaning |
|---|---|---|
| Hit | 85 + opposed(accuracy, hit resistance, 15); clamp 5–95% | Accuracy raises connection probability; it does not bypass a selected defense automatically |
| Dodge | 5 + opposed(dodge rating, accuracy, 35); clamp 0–60% | Evasion/Dexterity oppose attacker accuracy |
| Critical | 10 + opposed(critical offense, critical defense, 75); clamp 1–85% | Crushing raises, Fortitude lowers the opposed critical probability |
| Physical block | 45 + opposed(block defense, block offense, 35); clamp 5–95% | Defense uses raw armor + 3*defender Dexterity; offense uses item Accuracy + 2*Penetration + 3*attacker Dexterity |

Body parts, aimed attacks and number of protected zones supply further
adjustments. The block offense term does not silently reuse the Luck-inclusive
hit-accuracy expression. Health's hidden physical armor factor is applied in
the damage path; it is not added to this block rating.

For an ordinary torso attack, Luck 40 on both sides and zero Crushing/Fortitude
give critical ratings 200 versus 200, hence 10%. Adding 100 Crushing gives
300 versus 200: `10 + 75*100/(300+200+100) = 22.5%` before any other adjustment.
Giving the defender 100 Fortitude restores equal ratings and 10%. This is an
illustrative local calculation, not a live Neverlands measured probability.
Server RNG decides the actual result; rendered rounding is not authority.

All participant types use the same physical pipeline. Equipment suppression
for unarmed/fist mode is owned by the existing combat profile/attribute rules;
do not implement another set of odds for scroll entry, Arena or NPCs.
NPC exact profiles and artifact/family coefficients remain explicit inputs,
not guessed from their portrait or number of illustrated items.

## 5. UI, UX and artwork

Profile/character sheets and combat inspection cards expose the named ratings.
The percentage suffix is source-style presentation of a rating; an opponent,
action and selected defense are still needed to calculate a chance. Fight logs
record actual resolved hits, misses, dodges, blocks and critical damage, not a
retroactive calculation from today's equipment.

[Arena helper](../app/helpers/arena_helper.rb) and
[fighter card](../app/views/arena_matches/_fighter_card.html.erb) own combat
labels, including NPC `endurance` → Fortitude. The
[shared character sheet](../app/views/shared/_neverlands_character_sheet.html.erb)
and [Inventory handbook](features/player_inventory.md) own build/equipment
presentation. [COMBAT](COMBAT.md) owns log emphasis and navigation.
[ARTWORK](ARTWORK.md) supplies portrait/equipment image specifications; the
ratings themselves need no raster artwork. This documentation change adds no
new asset, label or UI behavior.

## 6. Implementation and state ownership

| Owner | Contract |
|---|---|
| [InventoryItem](../app/models/inventory_item.rb) | Merged template/instance effect values; no automatic consumer for arbitrary keys |
| [Character](../app/models/character.rb) | Supported equipped effect sums and effective primary-stat inputs |
| [CombatAttributes](../app/services/arena/combat_attributes.rb) | Shared adapters for real players, NPC snapshots and unarmed mode |
| [Calibration](../app/lib/game/combat/calibration.rb) | Pure configurable physical rating/damage calculations |
| [CombatResolver](../app/services/arena/combat_resolver.rb) | Opposed rolls, selected-zone defense, damage and structured outcomes using supplied RNG |
| [CombatProcessor](../app/services/arena/combat_processor.rb) | Committed action/living-participant lifecycle and persisted turn results |

Player stat/equipment reads are live inputs to subsequent resolution; authored
NPC combat profiles become participation snapshots. Ordinary action budgets
remain stored for both armed and unarmed fights. Normal allocation/equipment
routes are reserved throughout active fights. Broken or expired worn gear no
longer contributes on a live read; injury penalties expire naturally. This
does not make every numeric input an immutable match-start snapshot. Calibration
configuration is cached in-process; reload/restart app and workers after
editing it. Historical actions/logs are persisted outcomes, not projections
to be rewritten when coefficients change.

## 7. Editing and extension recipes

1. **Tune a supported item:** find its stable template in [ITEMS](ITEMS.md), use
   one supported rating key, inspect instance overrides and broken state, then
   verify Inventory → equip → effective display → shared combat → unequip.
   A worn template edit can affect current readers; an instance override can
   mask it. Do not modify the character's permanent allocations as compensation.
2. **Tune an NPC:** edit its exact level profile and documented adapter fields,
   using `endurance` for NPC Fortitude and explicit Health separately. Verify
   new fight snapshots; do not expect a seed edit to rewrite an existing fight.
3. **Tune an equation:** edit
   [combat_calibration.yml](../config/gameplay/combat_calibration.yml) and the
   existing calculator. Keep hit, dodge, critical, block and damage independent.
   Test opposed boundaries and both participants' inputs; update FORMULAS,
   this guide, STATS and the affected Combat design/handbook.
4. **Add a temporary source bonus:** first identify its source, lifetime,
   stacking/cap and resource/permission owner. An `active_effects` display row
   or unknown JSON key is not completion. Keep it source-only until a tested
   shared consumer executes it.

There is no separate modifier-point allocation UI. Players change modifiers
through supported build inputs. Pure equations must remain free of database
queries; RNG is injected at the existing combat boundary.

## 8. Use cases and cross-feature effects

| Preconditions → action | Current result / boundary |
|---|---|
| Equal Luck 40, no ratings → equip +100 Crushing | Illustrative critical probability increases 10→22.5% for an otherwise unadjusted torso attack; no guaranteed critical and no flat +100 damage. |
| Defender equips Fortitude | Opponent's critical probability can fall. Ordinary incoming physical damage and HP capacity do not directly change from Fortitude alone. |
| Attacker chooses head; defender protects head | The server validates packages/budgets, then uses the shared hit/dodge/block path. Matching the zone enables a block attempt; it is not unconditional immunity. |
| Accuracy item in Arena → equivalent wilderness PvP/PvE | Same physical reader and equations after valid entry. [SCROLLS](SCROLLS.md) still owns attack admission and charges. |
| Injury reduces Dexterity/Luck | Derived hit/evasion/critical inputs can change through primary stats; equipment rating bonuses are not all multiplied by the injury percentage. [MEDICAL](MEDICAL.md) owns cure/expiry. |
| Add NPC inspection `endurance` | Fortitude changes in new valid snapshots; it does not increase HP or Health armor. Decorative NPC gear alone changes neither. |
| Change Crushing or Evasion → walk/search/shop | No direct movement, loot chance, price or carrying bonus. Those use World/Skills/Economy/primary-stat inputs; a source temporary bundle may define separate effects. |
| Lost participant retains impressive ratings | Defeat still removes them from active targeting/actions. Only historical logs and final statistics retain them; ratings do not bypass the living-participant rule. |

## 9. Verification, gaps and maintenance

See [calibration specs](../spec/lib/game/combat/calibration_spec.rb),
[resolver specs](../spec/services/arena/combat_resolver_spec.rb),
[character input specs](../spec/models/character_combat_inputs_spec.rb),
[mastery specs](../spec/services/arena/mastery_calibration_spec.rb) and
[bounded magic specs](../spec/services/arena/magic_calibration_spec.rb).
[Combat acceptance](features/arena_combat.md#september-15-stat-and-roster-acceptance)
records the previous local browser run; it is distinct from the live Arena
and scroll evidence indexed by [COMBAT](COMBAT.md).

- **[EVIDENCE]** Exact source opposed coefficients, all Fortitude dependencies,
  hidden universal level factors and low-HP degradation remain unknown.
- **[IMPL]** Generic timed rating effects and source effect-cap rules have no
  complete engine. Display metadata is not enforcement.
- **[IMPL] / bounded magic:** elemental armor and the published limited
  technique level-chance table are not wired into the current subset. That
  table is not permission to replace physical hit probabilities.
- **Audit boundary:** live player inputs versus stored budgets and passive
  equipped-item expiry require the character-state consistency audit; this
  guide does not assert a new freeze/expiry guarantee.

Maintain this guide with changes to rating keys, composition, stat dependencies,
opposed rolls, NPC snapshots, temporary effects or labels, following
[DOCUMENTATION](DOCUMENTATION.md#22-change-triggered-documentation-updates).
Keep numerical examples synchronized with FORMULAS and current code; a
documentation check is not a source-parity or runtime acceptance test.
