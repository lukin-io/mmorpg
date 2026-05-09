# Items, Inventory, And Equipment

## Purpose

Items make character progression concrete. Inventory limits, equipment
requirements, weight, durability, shops, and loot give the world economy and
combat systems practical constraints.

## Source Material

Inputs:

- `doc/ITEM_SYSTEM_GUIDE.md`
- `doc/flow/18_inventory_system.md`
- deleted `doc/features/8_gameplay_mechanics.md`
- deleted `doc/features/9_economy.md`

## Player Experience

The player opens inventory, sees equipped gear and carried items, compares item
requirements, equips usable gear, sells or buys goods in shops, and feels weight
or capacity as a real travel/economy constraint.

## Item Categories

Core:

- weapons;
- armor;
- jewelry/accessories;
- consumables;
- quest items;
- crafting resources;
- tools.

Later:

- cosmetics;
- mounts;
- housing decor.

## Equipment Rules

- Items define allowed slot.
- A character can equip only one item per slot unless a slot supports pairs.
- Two-handed weapons occupy both hand capacity.
- Items can require level, stats, skills, or reputation.
- Equipment affects combat formulas, vitals, carrying capacity, and possibly
  movement cost.
- Durability can degrade through combat or use.

## Inventory Rules

- Characters have finite carry capacity.
- Capacity can be weight-based, slot-based, or both.
- Stackable items stack only with matching item identity and state.
- Quest items can be protected from normal sale/discard.
- Inventory actions are server-authoritative.

## State Concepts

- item template;
- item instance;
- stack quantity;
- durability;
- ownership;
- equipped slot;
- carried weight;
- maximum weight;
- bound/unbound state;
- sale value.

## Interactions

- `features/combat.md`: weapons and armor affect turns.
- `features/movement.md`: carried weight can modify travel time.
- `features/economy_trading_shops.md`: shops and market trade items.
- `features/gathering_professions.md`: resources and tools live in inventory.
- `features/npcs_quests.md`: quests can grant or require items.

## Out Of Scope

- Premium inventory boosts as a core design dependency.
- Item enhancement beyond simple durability and requirements before base
  inventory/equipment is stable.
