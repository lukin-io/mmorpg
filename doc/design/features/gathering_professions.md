# Gathering And Professions

## Purpose

Gathering and professions make outdoor tiles and city buildings economically
useful. They give non-combat characters meaningful actions and feed shops,
crafting, trade, quests, and recovery.

## Source Material

Inputs:

- Neverlands-derived world action and profession notes folded into this file.
- live outdoor `Оглядеться` capture from
  `reference/neverlands_live_outdoor_npc_resource.md`.

## Player Experience

The player reaches a tile that offers a local action such as `Оглядеться`,
fish, dig, drink, or harvest. `Оглядеться` means looking for herbs or local
resources. Starting the action may lock movement for a short time, return a
resource result, or be interrupted by a hostile NPC handoff. Completion adds
resources, skill progress, or quest progress.

In cities, profession buildings or NPCs allow crafting, training, repair, and
special services.

## Gathering Rules

- Gathering actions are offered by the current tile.
- A tile can expose one or more resource actions.
- Actions can require tools, skill level, terrain, time, or quest state.
- Resource availability is server-authored.
- `Оглядеться` is the source-backed outdoor herb/resource search action.
- Gathering can have a timer similar to movement lock, but it is not movement.
- Completion grants items and profession progress.
- Depleted resources can respawn deterministically.
- A resource action can return a forced refresh or combat handoff instead of a
  resource payload; the server response decides the next state.

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
- resource search action;
- resource action token;
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
- `features/combat.md`: hostile outdoor interrupts enter the same fight loop.
- `features/economy_trading_shops.md`: crafted resources enter markets.
- `features/npcs_quests.md`: quests can require gathering or crafting.
- `areas/cities_and_buildings.md`: workshops and trainers live in cities.
