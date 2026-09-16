# Character Guide

Reviewed against the working tree and preserved Neverlands evidence on
**2026-09-15**. This book explains how a character's saved development becomes
effective stats, equipment requirements, combat inputs, recovery and carrying
capacity. It describes current rules and authoring procedures, not the live
inventory or build of a particular player.

Start with the [Character domain](domains/character.md), its
[source summary](design/reference/character/README.md),
[progression design](design/features/progression_stats_skills.md),
[vitals design](design/features/character_vitals.md) and
[MVP boundary](design/launch_mvp_plan.md). The
[Character Progression handbook](features/character_progression.md) owns exact
HTTP/UI guarantees and acceptance. [SKILLS](SKILLS.md) and [PERKS](PERKS.md)
own their complete catalogs; [FORMULAS](FORMULAS.md) owns the numerical reference.
[STATS](STATS.md) expands primary-stat definitions and linked resource/capacity
rules; [MODIFIERS](MODIFIERS.md) expands the four combat ratings, aliases and
opposed consumers. Their source-only flags do not extend this runtime boundary.

## Contents

1. [Scope and evidence](#1-scope-and-evidence)
2. [Character data and terminology](#2-character-data-and-terminology)
3. [Development and equipment flows](#3-development-and-equipment-flows)
4. [Calculations and gameplay effects](#4-calculations-and-gameplay-effects)
5. [Profile, UI and artwork](#5-profile-ui-and-artwork)
6. [Implementation and state ownership](#6-implementation-and-state-ownership)
7. [Editing and extension recipes](#7-editing-and-extension-recipes)
8. [Use cases and cross-feature effects](#8-use-cases-and-cross-feature-effects)
9. [Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope and evidence

Implemented: levels 0–27, cumulative XP, level rewards, permanent primary-stat
allocation, numeric skill allocation/equipment bonuses, four selectable perks,
derived character inputs, elapsed vitals recovery and public profile/location
presentation. A supported level or visible skill does not imply every source
ability or profession effect exists.

| Provenance | What it establishes |
|---|---|
| [Profile/development capture](design/reference/character/observations/2026-05-11_player_profile_and_development.md) | Primary-stat, development and dense profile presentation |
| [September 11 level/grant recheck](design/reference/character/observations/2026-09-11_level_grants_and_combat_inputs.md) | Published progression table and live cumulative-XP confirmation: 29,946,496 XP + 20,053,504 remaining = 50,000,000 for level 18 |
| [September 14 supplied screens/wiki audit](design/reference/character/observations/2026-09-14_skills_and_perks.md) | Numeric Умения versus boolean Навыки; complete observed/published catalogs, including entries without local consumers |
| [Combat calibration](design/features/combat_calibration.md) | Authorized local fits for hidden opposed combat, recovery and injury coefficients; not recovered Neverlands source code |
| [Runtime handbook](features/character_progression.md) | Local allocation, persistence, consumers and recorded acceptance; not independent proof of source parity |

All worked examples below are illustrative applications of the current rules,
unless explicitly identified as captured evidence.

## 2. Character data and terminology

### Implemented primary stats

| English / Neverlands | Persisted normalized key | Current influence |
|---|---|---|
| Strength / Сила | `strength` | Physical attack input, carrying capacity, equipment requirements |
| Dexterity / Ловкость | `dexterity` | Opposed hit/evasion inputs and requirements |
| Luck / Удача | `luck` | Accuracy, opposed critical attack/resistance and requirements |
| Health / Здоровье | `vitality` | Base HP when allocated; effective carrying capacity, hidden physical armor bonus and requirements |
| Knowledge / Знания | `intelligence` | Base MP when allocated, item/medical requirements and bounded magic inputs |

Each base stat is `1 + saved allocated points`. English presentation aliases
such as Health and Knowledge normalize to the keys above. Health is a primary
stat; **current HP** is a separate resource. Likewise Knowledge is not current MP.

| Other value | Saved or derived? | Owner / distinction |
|---|---|---|
| Level, total experience, four unspent point pools | Saved on `Character` | XP is cumulative; stat, combat-skill, peace-skill and perk pools are separate |
| `allocated_stats` | Saved additions | Equipment and injuries never rewrite these permanent investments |
| `passive_skills` | Saved numeric learning | [Skills](SKILLS.md): combat, resistance, magic and peace; learned cap versus equipment-enhanced value |
| `perks` | Saved boolean ownership | [Perks](PERKS.md): More Strength, Careful Fighter, Merchant and Healer currently selectable |
| `metadata.profession_skills` | Separate profession counters | Doctor and Trading have current consumers; not extra allocatable peace skills |
| `metadata.profession_unlocks`, `CharacterLicense` | Separate qualification and timed permission | [Economy](ECONOMY.md) / [Medical](MEDICAL.md); a perk alone is not every required permission |
| Saved max/current HP and MP, regeneration anchors/remainders | Saved resources | Base maximum recalculation and elapsed recovery have different entry points |
| Effective stats, ratings, capacity, skill bonuses | Derived on read | Current usable equipment, level/perks and active injuries supply inputs |
| Combat AP/attack/block profile | Saved per participation, with an unarmed override | Ordinary profiles retain their budget; `no_weapons` rederives AP/physical costs and forces normal blocking instead of inheriting old gear overrides |
| NV | Saved on the user's wallet | [Economy](ECONOMY.md); account-owned, not a separate balance per character |

The 29 numeric definitions and 42 source perks are cataloged in SKILLS/PERKS
with implementation flags. The source's 15 profession counters are distinct
again. Four numeric skill categories must not be used as a classification of
the boolean perk system.

### Authored defaults versus existing players

[The progression table](../config/gameplay/character_progression.yml) defines
level 0's starter grants: 15 stat points, 10 combat-skill points, 2 peace-skill
points, 1 perk point and 0 NV. Character defaults provide the starting pools;
the level-up service does not regrant row 0. New user wallets start at zero.
Named development seed accounts have separate one-time wallet grants; these
are not a universal player starting-money rule.

Existing saved HP/MP maxima remain authoritative until a supported writer
changes them. Do not assume reading a profile recalculates or repairs every
legacy or seeded character's saved maxima from its allocations.

## 3. Development and equipment flows

### Receive XP and gain a level

The fight reward owner computes the award and guards settlement.
`Players::Progression::LevelUpService#apply_experience!(amount)` accepts a
nonnegative integer amount, locks the character, adds cumulative XP and loops
through every newly reached supported level. Each reached row grants its stat,
combat-skill, peace-skill and perk points and credits its NV reward through the
shared wallet service, in the same transaction.

XP is not spent or reset on leveling. The level-up timestamp is recorded;
unspent points remain available for the player's later choices. Level-up alone
does not allocate those points or refill/recalculate HP/MP. Combat's settlement
guard prevents the same fight from awarding again; calling the general XP
writer twice with a positive amount is two awards, not an idempotent command.

The [September 15 wiki audit](design/reference/combat/observations/2026-09-15_wiki_experience_rules.md)
confirmed all 224 stored progression-table values without changing grants.
Fight caps are ceilings, not guaranteed earnings. The shared
[reward owner](FORMULAS.md#reward-01--shared-npc-and-player-experience) counts
actual removed player HP cumulatively, including restored HP damaged again;
NPC fallback and XP buff limits remain explicit there. Changing the progression
table changes thresholds/grants/caps, not those earning coefficients.

### Spend points

Profile development opens the relevant Stats, Skills or Perks surface.
Plus/minus controls change an unsaved preview; Save submits intent. Reload
shows the committed allocation and remaining pool. Minus does not refund a
previously saved allocation. The server checks ownership, availability, valid
keys and the pool reloaded under lock; forged controls cannot create points.

Primary-stat requests normalize aliases, ignore unknown keys and bound each
submitted field to `0..100`. The allocation service accepts positive integer
allocations, rejects empty/overspending requests and updates saved additions,
pool and base vitals atomically. No successful partial spend remains after a
failure. [Skills](SKILLS.md) explains tier-crossing gains and base cap 100;
[Perks](PERKS.md) explains boolean selection and implemented exclusions.

### Compose a build

Acquire an owned item, meet its requirements, equip into an allowed slot and
revisit Profile/Inventory to inspect effective values. Template modifiers merge
with instance `stat_modifiers`, then instance `effects`; later matching keys
override within an item, and distinct equipped items contribute their values.
Broken equipment is excluded from Character stat contributions.

Do not generalize one reader's rules to all equipment: Doctor bonuses also
exclude expired items, while the general primary-stat reader does not apply
that same expiry filter. [ITEMS](ITEMS.md#3-fields-slots-and-effective-properties)
owns exact effect aliases, requirements, slot conflicts, durability and instance
editing. Inventory actions are guarded during combat; unarmed admission uses
the shared combat entry rules to enforce the allowed equipment state.

## 4. Calculations and gameplay effects

Full equations, provenance, rounding and the complete 28-row grant table live
in [FORMULAS: progression](FORMULAS.md#2-experience-levels-and-grants) and
[character inputs](FORMULAS.md#3-character-stats-and-equipment).

| Quantity | Current calculation / consequence |
|---|---|
| XP threshold for level N | Sum `experience_to_next_level` from levels 0 through N−1 |
| Stat before injury | `1 + allocated + equipment + applicable perk`; More Strength adds `floor(level/2)` only to Strength |
| Stat with injury | Let `P = clamp(sum(active penalties),0,90)`; when P > 0, `max(floor(before * (100-P)/100),1)` |
| Base saved maximum HP / MP | Allocation recalculation uses `5 * base Health` / `7 * base Knowledge`, then clamps current values down without healing |
| Effective maximum HP / MP | Saved maximum plus explicit equipped vital bonuses; equipment Health/Knowledge does not itself rewrite base maxima |
| Carrying weight capacity | `5 * effective Strength + 10 * effective Health + 10 * level` |
| AP per turn | `80 + (level >= 5 ? 10 : 0) + (level >= 10 ? 10 : 0) + effective Extra Action Points` |

The injury floor applies only with an active penalty. Effective learned skills
can exceed 100 through equipment. AP is not HP or mana: it is the budget for a
submitted turn package; attack/block costs and item restrictions are described
in [COMBAT](COMBAT.md) and [COMBAT-01](FORMULAS.md#combat-01--physical-action-cost-and-package-validation).

Local physical damage currently has no additional level coefficient. The
[Level wiki audit](design/reference/character/observations/2026-09-15_levels_stats_and_modifiers.md) explicitly identifies
one in Neverlands; its magnitude is unknown and implementation remains open.
`Arena::CombatAttributes` adapts effective player stats, weapon damage/mastery,
armor, accuracy/evasion, crushing/fortitude, penetration, physical resistance,
fatigue and configured artifact effects into the shared opposed calculations.
Level influences grants, entry/experience limits and AP thresholds. NPC stats
come from authored participation snapshots, not the player allocation table.
Higher level therefore does not guarantee a fixed hit or win.

Profile Attack is a rounded unmitigated calculation preview. Critical chance
there is the base chance, not a prediction against every opponent. Armor and
ratings come from supported item effects; there is no hidden extra armor per
level. No weapon's picture or name supplies a missing stat.

[Recovery](FORMULAS.md#recovery-01--elapsed-hpmp-regeneration) uses effective
maximum resources, Self-Healing/Fast Mana Regeneration, fatigue, elapsed server
time and saved fractional carry. It is blocked during active matches. Injuries
are a separate persisted effect: [MEDICAL](MEDICAL.md) explains expiry and cure.

[Wanderer](SKILLS.md) affects the next World movement offer's duration. An
active movement command retains its accepted timing. Reduced capacity does not
automatically discard inventory or introduce an overweight walking penalty;
heavy/combat injury movement restrictions have their own checks. Weight and
slot limits are separate acquisition constraints.

## 5. Profile, UI and artwork

The profile presents identity/level, HP/MP, equipment, primary stats and derived
values, followed by development and location information. Numeric skills show
learned values and equipment contributions; perks show owned/not owned status.
Your licenses shows currently active typed permissions, not inventory items.

The public profile links a fight while the character's fight/result context
still awaits Finish, including a defeated participant at 0 HP. City and Arena
room remain distinct location labels. The
[September 14 live Duel](ARENA.md#september-14-live-human-duel) documents this
source behavior; the [profile handbook](features/character_progression.md)
owns its local display and navigation acceptance. Chat uses actual persisted
XP/results from Combat; it never computes a second level-up.

Player illustrations and equipment images are project-owned. Use
[ARTWORK's player brief](ARTWORK.md#player-illustration),
[Skills/Perks presentation](ARTWORK.md#skills-and-perks-presentation-reference)
and [ITEMS artwork mapping](ITEMS.md#5-artwork-and-presentation) for assets,
dimensions, containment and production prompts. Stats and requirements remain
HTML/text. This guide adds no new artwork or browser surface.

## 6. Implementation and state ownership

| Owner | Public responsibility / side effects |
|---|---|
| [Character](../app/models/character.rb) | Saved development and effective stat/skill/vital/capacity readers; owned license and injury relationships |
| [Progression Catalog](../app/lib/game/progression/catalog.rb) and [YAML](../config/gameplay/character_progression.yml) | Validated level rows, cumulative thresholds and rewards; cached definitions, no player mutation |
| [LevelUpService](../app/services/players/progression/level_up_service.rb) | XP amount → locked character/point/level updates and wallet credits |
| [StatAllocationService](../app/services/characters/stat_allocation_service.rb) | Character + allocations → allocated/remaining result; saves points, additions and base vitals |
| [CharactersController](../app/controllers/characters_controller.rb) / [PlayersController](../app/controllers/players_controller.rb) | Authorized development intent and public profile presentation; detailed routes in the handbook |
| [VitalsService](../app/services/characters/vitals_service.rb) | Elapsed regeneration and bounded resource restoration; preserves fractional carry |
| [CombatAttributes](../app/services/arena/combat_attributes.rb) | Current player numeric inputs or NPC participation snapshot → shared formula input hash |
| [CombatProfile](../app/services/arena/combat_profile.rb) | Preview or persisted per-participant AP/attack/block/magic budget used on submission |
| [Inventory handbook](features/player_inventory.md) | Owned items, equipment mutations, requirement checks, weight and slots |

**Timing matters:** an ordinary stored combat profile retains its budget, not
every character attribute. `no_weapons` explicitly rederives AP and physical
costs from the character and forces the normal block table, ignoring stale gear
profile overrides. CombatAttributes reads current player effective values;
NPC combat data is a participation snapshot.

Inventory guards normal gear mutation during fights. Progression endpoints
check ownership and outdoor movement/Look availability; they do not currently
add a general active-match allocation prohibition. Do not promise an immutable
whole-player build or a blanket combat edit lock. Changes to this boundary need
the Combat/Progression owners and source evidence, not only a profile UI change.

Reload reads saved development, licenses and effects. A browser preview,
broadcast or displayed percentage is never authority for allocation, grants or
combat. Existing guards and transactions stay in their owners rather than a
second character pipeline.

## 7. Editing and extension recipes

### Change a level or grant

1. Establish the source row or explicitly authorized fit. Edit the progression
   YAML; all required fields must be nonnegative integers, XP cost positive and
   levels contiguous. Adding level 28 requires its complete grant row; row 27's
   next-level cost alone is insufficient.
2. Recalculate cumulative thresholds and affected examples in FORMULAS. Rewards
   belong to the level reached, not the row whose XP cost was just paid.
3. Reload the Catalog with its `reload!` entry point in the affected process or
   restart the application/workers. Editing disk does not refresh every process.
4. Existing players are not automatically re-leveled, refunded or given revised
   historical grants. Future XP processing uses the then-current table. Any
   intended reconciliation needs a separately reviewed, exact-target operation.
5. Update progression design/handbook, this book, affected SKILLS/PERKS grants,
   ECONOMY rewards and NPC/COMBAT caps; run the catalog/progression specs below.

### Change a build input or consumer

Use the item/template/instance owner in ITEMS for equipment; use SKILLS/PERKS
for new selectable definitions and effects. Extend an existing accessor and
its actual consumers, not a second formula in the UI. Check ordinary and unarmed
combat, doctor/scroll requirements, capacity and recovery where affected.
Changes to a template may affect already-owned items; instance overrides can
mask them. Preserve existing participation profiles and historical results.

Primary-stat, profession and entitlement metadata are code/operator concerns;
there is no general player editor for arbitrary JSON. A source-only perk label
must not become selectable without its prerequisite/effect flow and tests.
Combat premium metadata changes reward limits, not a purchased subscription
workflow; [FORMULAS](FORMULAS.md#reward-02--premium-limits) owns expiry/tier rules.

## 8. Use cases and cross-feature effects

| Preconditions → action | Authoritative result and downstream effect |
|---|---|
| Level 4, XP 3,490, Extra AP 0 → receive 20 XP | XP becomes 3,510; level 5 threshold is 3,500. Gain 5 stat, 5 combat-skill, 5 peace-skill points, 0 perk points and 300 NV. Next threshold is 5,500, so 1,990 XP remains. AP changes 80→90 for a new profile; the level term adds 10 capacity. No automatic allocation or heal. |
| Base Health 20, saved max HP 100, current HP 40 → allocate 1 Health | Base Health 21, saved max HP 105, current HP remains 40; spend one stat point. With no other changes, effective Health adds 10 carrying capacity. Higher maximum changes subsequent regeneration, not immediate restoration. |
| Learned weapon mastery 100 → equip an allowed item with +10 applicable mastery | Effective 110 feeds the shared fight formula; learned value stays 100 and no points are refunded/consumed. The actual hit still depends on the opponent, actions and RNG. |
| A 15% active injury → restore HP with an elixir | HP rises only up to the maximum; primary-stat penalties and resulting combat/capacity effects remain. Medical cure or expiry removes that separate effect. |
| Equipment changes Wanderer or Extra AP outside combat | Next movement offer/new combat budget uses the new value. Accepted travel timing and ordinary stored combat AP do not change; unarmed profiles have the rederivation exception described above. |
| Healer perk owned, Doctor 99, beginner bag requires 100 → request treatment | The numeric requirement fails even with an active Doctor license; no quote, bag use, healing or fee. MEDICAL owns this failure. |
| Level 27 accumulates enough XP for the row-27 cost | No level 28 or invented grants without a complete supported row. Stored XP remains cumulative. |

## 9. Verification, gaps and maintenance

Protecting checks include the [catalog specs](../spec/lib/game/progression/catalog_spec.rb),
[level-up specs](../spec/services/players/progression/level_up_service_spec.rb),
[stat allocation specs](../spec/services/characters/stat_allocation_service_spec.rb),
[equipment/skill requests](../spec/requests/skill_allocation_equipment_spec.rb),
[combat profiles](../spec/services/arena/combat_profile_spec.rb),
[elapsed recovery](../spec/services/characters/vitals_elapsed_recovery_spec.rb)
and [Inventory/progression system flow](../spec/system/inventory_progression_spec.rb).
The owning handbooks retain historical manual acceptance. This documentation
review does not establish a new browser, runtime-suite or CI result.

- `[IMPL]`: source-only skills/perks, reset flows and automatic profession growth
  remain flagged in SKILLS/PERKS and the progression/profession handbooks.
- `[EVIDENCE]`: complete later-level rows and unobserved effect coefficients
  remain unknown. Existing authorized combat fits are implemented approximations.
- Full source magic development/combat and premium purchase flows are outside
  the implemented boundary; current metadata or catalog definitions do not
  establish those player flows.

Maintain this guide when primary inputs, progression tables, resource writers,
equipment composition, consumers or editing procedures change. Synchronize the
affected FORMULAS examples and SKILLS/PERKS/ITEMS/MEDICAL/ECONOMY/COMBAT/WORLD
handoffs through the [documentation context map](DOCUMENTATION.md#21-required-context-and-update-map).

## September 15 level and primary-stat evidence

The [source audit](design/reference/character/observations/2026-09-15_levels_stats_and_modifiers.md) records definitions, level
unlocks and remaining implementation boundaries. Progression now exposes
`max_npcs_in_group` to World: level3 admits singles,4 admits pairs,6 admits
triples,17 allows8 and18 allows10. Leveling changes the eligible complete samples,
not their individual stats/rewards or the habitat's distance rule.

Health also contributes hidden physical armor through the
[shared formula](FORMULAS.md#september-15-stat-and-modifier-interpretation).
For example, allocating Health29→30 with armor100 changes its combat contribution
100→105 while Profile still displays100. An injury crossing the same threshold
can remove that bonus even if HP was restored. Luck now improves hit chance as
well as critical comparisons. Edit the existing calibration config and shared
adapter, never add a separate player/PvP/NPC formula.

The wiki says gear cannot raise Health. The generic local stat-modifier adapter
still accepts Health/vitality keys; that capability is not evidence of a valid
Neverlands item. Author direct HP modifiers for source-backed HP equipment and
verify any proposed primary-Health item against evidence before adding it.
Combat HP restoration's Knowledge qualification is recorded in COMBAT/FORMULAS;
it does not implement healing or remove injury penalties.
