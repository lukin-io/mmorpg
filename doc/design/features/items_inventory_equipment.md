# Items, Inventory, And Equipment

## Purpose

Items make character progression concrete. Inventory limits, equipment
requirements, weight, durability, shops, and loot give the world economy and
combat systems practical constraints.

## Source Material

Inputs:

- `doc/flow/neverlands_live_player.md`
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
- The player profile should show an equipment doll/slot summary even when the
  full inventory action is separate or contextually disabled.

Baseline visible slots from the Neverlands player capture:

- helmet;
- necklace;
- weapon;
- belt;
- belt contents;
- boots;
- pocket;
- pocket contents;
- bracers;
- gloves;
- weapon/shield;
- rings;
- armor;
- pants;
- relic.

The live inventory capture adds these launch requirements:

- inventory opens from the same player shell as the character profile;
- the current page's context button is disabled, while `Ваш персонаж` and
  `Вернуться` remain active;
- inventory shows an equipment doll plus carried item rows;
- carried item rows show icon, durability bar, compact action buttons,
  properties, and requirements;
- item properties can include price, durability, damage range, armor class,
  HP, primary stat modifiers, accuracy/dodge/fortitude/crushing percentages,
  armor pierce, elemental resistances, expiry time, engraving, and free-text
  descriptions;
- item requirements can include mass, level, primary stats, action-point cost,
  and numeric skill requirements;
- stable item requirements, base price, and max durability belong on the item
  template; current durability and per-instance overrides belong on the
  inventory item;
- transfer, gift, sale, and delete are tokenized/server-authorized actions;
  launch MVP needs equip/use/delete first, with transfer/gift/sale deferred
  unless the economy loop explicitly needs them.

## Inventory Rules

- Characters have finite carry capacity.
- Capacity can be weight-based, slot-based, or both.
- Stackable items stack only with matching item identity and state.
- Quest items can be protected from normal sale/discard.
- Inventory actions are server-authoritative.

## Current Implementation Status

Last updated: 2026-05-11.

Implemented:

- inventory page inside the player shell with equipment panel, stats panel,
  category filters, sort actions, inventory mass, item rows, and empty slots;
- item template support for equipment, consumable, material, resource, quest,
  and misc item types;
- item instance support for quantity, equipped slot, current durability,
  requirement overrides, effect overrides, expiry metadata, bound/protected
  state, and per-item properties;
- equip, unequip, use, sort, and discard actions through Rails controllers and
  inventory services;
- requirement validation for level, AP/action points, primary stats, and mapped
  numeric skills before equip/use;
- equipment effects feeding character stats, effective max HP, attack, defense,
  accuracy, dodge, armor pierce, fortitude, elemental resistances, and skill
  bonuses;
- combat durability degradation for PvE and PvP equipment;
- consumable durability charges before quantity consumption;
- discard protection for equipped, bound, protected, locked, and quest items;
- Brakeman, RuboCop, and Zeitwerk checks pass for the current implementation.

Missing before launch MVP is complete:

- canonical item seeds/templates matching the captured Neverlands inventory;
- full label normalization for all captured effects and requirements;
- complete slot rules for two-handed weapons, layered armor, rings, belt
  contents, pocket contents, and relics;
- repair and breakage UX, including player-visible messages when gear breaks;
- capacity enforcement across loot, pickup, trade, shop purchase, and quest
  reward flows;
- server-issued inventory action keys if Rails CSRF forms are not enough for
  the final gameplay action model;
- transfer, gift, sale, dealer, and equipment-set saving flows;
- system/browser coverage for the inventory page after local PostgreSQL test
  setup is fixed.

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

## Related Implementation Files

Models:

- `app/models/item_template.rb`
- `app/models/inventory.rb`
- `app/models/inventory_item.rb`
- `app/models/trade_item.rb`

Controllers and helpers:

- `app/controllers/inventories_controller.rb`
- `app/controllers/inventory_items_controller.rb`
- `app/controllers/equipment_enhancements_controller.rb`
- `app/helpers/inventories_helper.rb`
- `app/helpers/equipment_enhancements_helper.rb`

Services:

- `app/services/game/inventory/manager.rb`
- `app/services/game/inventory/equipment_service.rb`
- `app/services/game/inventory/requirement_checker.rb`
- `app/services/game/inventory/enhancement_service.rb`
- `app/services/game/inventory/expansion_service.rb`
- `app/services/game/economy/loot_generator.rb`

Views and JavaScript:

- `app/views/inventories/show.html.erb`
- `app/views/inventories/_equipment.html.erb`
- `app/views/inventories/_equipment_slot.html.erb`
- `app/views/inventories/_stats.html.erb`
- `app/views/equipment_enhancements/index.html.erb`
- `app/views/equipment_enhancements/show.html.erb`
- `app/views/equipment_enhancements/_preview.html.erb`
- `app/javascript/controllers/inventory_controller.js`

Specs:

- `spec/models/inventory_spec.rb`
- `spec/models/item_template_spec.rb`
- `spec/requests/inventories_spec.rb`
- `spec/services/game/inventory/manager_spec.rb`
- `spec/services/game/inventory/enhancement_service_spec.rb`
- `spec/services/game/inventory/expansion_service_spec.rb`
- `spec/system/inventory_progression_spec.rb`
