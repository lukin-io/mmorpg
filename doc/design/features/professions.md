# Professions

## Purpose

Professions turn eligible world cells and gathered resources into long-term
non-combat character development. They remain distinct from primary stats,
allocatable numeric `Умения`, and binary combat/stat perks.

## Neverlands Reference

Primary sources:

- [`Профессия`](http://wiki.neverlands.ru/wiki/Профессия)
- [`Охотник`](http://wiki.neverlands.ru/wiki/Охотник)
- `doc/design/reference/neverlands_skills.md`
- `doc/design/reference/neverlands_live_inventory_items.md`
- `doc/design/reference/neverlands_live_outdoor_npc_resource.md`

The wiki establishes the direction: a matching binary profession perk grants
access to the activity, and a profession-specific counter improves through
use. Live inventory observations also show separate production/resource
families. These facts do not establish exact tools, timers, success curves,
counter gains, yields, depletion, sale values, or interruption behavior.

## Player Experience

A future eligible player reaches a profession through a source-backed place or
cell action, sees the required tool/state and current profession counter,
performs one server-authored job, receives a clear success/failure result, and
then sees any counter, inventory, fatigue, or location change.

For MVP, only one fully captured gathering loop should be considered. Do not
ship a generic profession framework with many empty activity types.

## Rules

- A profession perk and a profession-use counter are separate values.
- Profession counters grow through the matching activity, not through the
  normal combat/peace allocation form.
- World owns eligible cells and action offers.
- Inventory owns tools, capacity, and awarded material items.
- Character Progression owns profession perk/counter persistence once the
  source contract is complete.
- Economy owns later sale/processing settlement, not gathering eligibility.
- The browser submits a server-authored action; it does not choose yield,
  counter gain, cooldown, or success.

## MVP Status

Not implemented. The current `look` cell action is an observation/search
handoff and may be interrupted by a hidden hostile encounter, but an
uninterrupted search deliberately awards no invented resource or profession
growth.

One profession is a justified MVP candidate only after a controlled Neverlands
capture records:

1. entry and eligibility, including the exact perk;
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

## Out Of Scope

- Guessing a gathering formula from profession names.
- Adding all known professions before one end-to-end loop is captured.
- Generic crafting queues, offline production, or profession classes.
- Treating inventory family tabs as proof that their production actions ship.
