# Professions

Domain navigation: `doc/domains/professions.md`.

## Purpose

Professions turn eligible world cells and gathered resources into long-term
non-combat character development. They remain distinct from primary stats,
allocatable numeric `Умения`, and binary combat/stat perks.

## Neverlands Reference

Primary sources:

- [`Профессия`](http://wiki.neverlands.ru/wiki/Профессия)
- [`Охотник`](http://wiki.neverlands.ru/wiki/Охотник)
- `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`
- `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`
- `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`
- `doc/design/reference/world/observations/2026-09-09_wiki_skills_and_cell_actions.md`
- `doc/design/reference/world/observations/2026-09-09_mine_exchange_wiki.md`

The wiki distinguishes access perks from profession-specific counters that
improve through use. This must not become a universal gate: the September 8
user clarification explicitly requires no fishing or drinking skill gate;
successful fishing grows its separate proficiency counter. Digging remains
skill-dependent. The Fisher article's access wording differs and remains
recorded in `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`.
Live inventory observations also show separate production/resource
families. These facts do not establish exact tools, timers, success curves,
counter gains, yields, depletion, sale values, or interruption behavior.

The September 9 wiki record preserves dated published fishing examples and
waterbody-specific species/bait/proficiency rows. They guide future content
authoring and capture; they are not a completed local catch flow or complete
probability formula. Naturalist/Herbalist plant discovery and Alchemy potion
making are separate published capabilities. Keep allocated Observation,
native profession proficiency and equipment-added proficiency distinct.

## Player Experience

A future eligible player reaches a profession through a source-backed place or
cell action, sees the required tool/state and current profession counter,
performs one server-authored job, receives a clear success/failure result, and
then sees any counter, inventory, fatigue, or location change.

Successful professions remain deferred from the current starter-map scope;
`doc/design/launch_mvp_plan.md` owns the delivery decision. A future profession
task should complete one bounded, evidenced loop before expanding activity
families. Do not ship a generic framework with empty profession types.

## Rules

- A profession perk and a profession-use counter are separate values; a
  nonzero counter is not automatically an activity prerequisite.
- Profession counters grow through the matching activity, not through the
  normal combat/peace allocation form.
- World owns eligible cells and action offers.
- Inventory owns tools, capacity, and awarded material items.
- Character Progression owns profession perk/counter persistence once the
  source contract is complete.
- Professions owns activity eligibility, extraction/digging and mining-license
  use/effects. Economy owns license/item purchase/payment and resource exchange
  queries, listings, transactions and storage. Dungeons owns descent and
  underground cells/movement; those are separate from extraction.
- The browser submits a server-authored action; it does not choose yield,
  counter gain, cooldown, or success.

## Remaining profession work by activity

| Activity | Established constraint | Evidence/implementation still needed |
|---|---|---|
| Fishing | No initial skill/perk gate. Successful fishing grows a separate profession counter. Equipped rod and bait are distinct requirements. | Complete cast/outcome UI, exact equipment/bait checks, native versus equipment effects, timing, success/empty/failure/interruption, item/counter deltas and repeat/reload behavior. |
| Plant discovery and harvesting | Empty Look is supported; herb-group IDs describe cell content. Published Naturalist/Herbalist/Observation roles remain distinct from Alchemy. | Exercise exact discovery/harvest eligibility, tool, timing, plant identity/quantity, counter growth, failed/interrupted actions and depletion/repeatability. |
| Alchemy production | Potion making is a separate profession capability. | Capture recipe/ingredient/tool requirements, consumption, timer, production and failure/counter effects; do not derive recipes from map herb labels. |
| Digging and mining extraction | A skill is required per the user. Published mining/license information guides the next capture. | Identify exact activity/skill/license/tool, timing, fatigue/wear, yields, counter changes and failure/interruption. Do not apply extraction gates to lobby entry or assume outdoor `dig` equals underground extraction. |

For each activity, Inventory must supply authoritative equipped/owned item
state and accept only observed item/quantity outcomes. The implementation must
revalidate the cell, tool and bait/license as applicable at mutation time, and
settle proven consumption/wear/yield/counter effects atomically. A failed or
duplicate completion must not consume twice, grant twice or advance proficiency
twice. Observe capacity failure, cancellation and reconnect behavior before
choosing their game rules; infrastructure correctness does not establish
Neverlands outcomes.

## MVP Status

Not implemented. The current `look` cell action is an observation/search
handoff and may be interrupted by a hidden hostile encounter, but an
uninterrupted search shows the captured immediate empty result and keeps its
persisted 28-second lock even after dismissal. It awards no resource or
profession growth.

The September 7 user decision deferred successful gathering from the open-world
task. The initial discussion grouped it with alchemy, but later published
evidence separates discovery/harvesting from potion making. This deferral
does not block zone, movement, entrance or cell-chat work and supplies no new
yield, eligibility threshold or success formula. Track the remaining activity
categories in this domain and `doc/features/professions.md`; World section 19
links them as adjacent work.

The September 8 task keeps successful fishing and its proficiency growth
pending the user's demonstration. The supplied Fishing `[0272]` screenshot
establishes the separate displayed counter, not a gain rate or catch table.
World ships the captured two-point sip with a 60-second lock and the no-bait
fishing entry with a 30-second lock. Successful casts, catches, proficiency
growth and digging outcomes remain unavailable. Equipped rods and bait belong
to that future fishing flow; they are distinct from a skill requirement.
Published successful-cast examples must not replace the no-bait entry's timer.
No fishing/drinking skill gate should be added to
resolve the missing tool, timer, inventory or result contract.

Before implementing a complete profession loop, its controlled Neverlands
capture must record:

1. entry and eligibility, including a perk only when that activity requires it;
2. required tool/equipment and failure without it;
3. action timer and fatigue/resource costs;
4. success, failure, empty-result, and interruption responses;
5. material identity/quantity and inventory-capacity failure;
6. exact profession-counter gain and any threshold effect;
7. cooldown, depletion, repeatability, and logout/reload behavior.

## Interactions

- `features/progression_stats_skills.md`: keeps profession perks/counters
  separate from ordinary skills.
- `features/movement.md` and `areas/world_map.md`: own eligible cells, action
  offers, fatigue gating, and hostile interruption.
- `features/items_inventory_equipment.md`: owns tools, resources, and capacity.
- `features/economy_trading_shops.md`: owns later material settlement.
- `features/dungeons.md`: owns descent and underground travel, separate from
  extraction and mining-license use.

## Out Of Scope

- Guessing a gathering formula from profession names.
- Adding all known professions before one end-to-end loop is captured.
- Generic crafting queues, offline production, or profession classes.
- Treating inventory family tabs as proof that their production actions ship.
