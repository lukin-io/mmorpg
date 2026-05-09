# Gathering And Professions

## Purpose

Gathering and professions make outdoor tiles and city buildings economically
useful. They give non-combat characters meaningful actions and feed shops,
crafting, trade, quests, and recovery.

## Source Material

Inputs:

- `doc/flow/14_tile_resource_gathering.md`
- deleted `doc/features/6_crafting_professions.md`
- deleted `doc/TODO.md`

## Player Experience

The player reaches a tile that offers a local action such as gather, fish, dig,
or harvest. Starting the action may lock movement for a short time. Completion
adds resources, skill progress, or quest progress.

In cities, profession buildings or NPCs allow crafting, training, repair, and
special services.

## Gathering Rules

- Gathering actions are offered by the current tile.
- A tile can expose one or more resource actions.
- Actions can require tools, skill level, terrain, time, or quest state.
- Resource availability is server-authored.
- Gathering can have a timer similar to movement lock, but it is not movement.
- Completion grants items and profession progress.
- Depleted resources can respawn deterministically.

## Profession Rules

Core profession families:

- fishing;
- herbalism;
- mining/digging;
- hunting;
- blacksmithing/weapon craft;
- alchemy;
- doctor/healer support.

Profession actions should connect to visible world places:

- resource tiles;
- city workshops;
- shops;
- trainers;
- quest NPCs.

## Crafting Rules

- Recipes define inputs, output, skill requirement, station requirement, and
  duration.
- Crafting consumes inputs on accepted start or completion, depending on final
  implementation choice.
- Crafting can produce quality tiers later, but core recipes should first be
  deterministic.
- Failed crafts, if allowed, should still be explainable and not feel random
  without feedback.

## State Concepts

- resource node;
- resource stock/depletion;
- tool;
- profession;
- profession level/progress;
- recipe;
- craft job;
- station;
- output item.

## Interactions

- `features/movement.md`: gathering timers lock movement.
- `features/items_inventory_equipment.md`: resources, tools, and outputs are
  inventory items.
- `features/economy_trading_shops.md`: crafted resources enter markets.
- `features/npcs_quests.md`: quests can require gathering or crafting.
- `areas/cities_and_buildings.md`: workshops and trainers live in cities.

## Out Of Scope

- Housing-based crafting as a core dependency.
- Complex quality RNG before basic resources, tools, recipes, and timers work.
