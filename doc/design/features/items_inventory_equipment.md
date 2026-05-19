# Items, Inventory, And Equipment

## Purpose

Items make character progression concrete. Inventory limits, equipment
requirements, weight, durability, shops, and loot give the world economy and
combat systems practical constraints.

## Source Material

Inputs:

- `doc/design/reference/neverlands.md`
- `doc/design/features/combat.md`

## Player Experience

The player opens inventory, sees equipped gear and carried items, compares item
requirements, equips usable gear, sells or buys goods in shops, and feels weight
or capacity as a real travel/economy constraint.

Inventory is player-related functionality. It belongs beside the character
profile, stats, skills, perks, vitals, and equipment formula, not in a separate
account dashboard.

## Item Categories

Core:

- weapons;
- armor;
- jewelry/accessories;
- consumables;
- quest items;
- crafting resources;
- tools.

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

## Wear And Remove Flow

Neverlands-style wearing is an inventory action, not drag-and-drop.

Design rules:

- opening inventory shows the equipment doll and carried item list in the same
  player shell;
- empty slots are visible even when no item is equipped;
- carried wearable items expose a compact `Wear` action in their item row;
- clicking `Wear` submits a server-authorized item action with the item id,
  target wear direction, and action token;
- the server chooses or validates the destination slot from the item template;
- requirements are validated before the item is worn;
- if wearing succeeds, the item becomes equipped and its effects immediately
  feed the profile, vitals, combat profile, movement/capacity calculations, and
  visible equipment doll;
- if wearing fails, the item remains carried and the player sees the reason;
- clicking an occupied equipment slot removes that item through the same
  server-authorized equipment action family;
- removing an item returns it to carried inventory if capacity and state allow;
- equipped, broken, protected, locked, or quest-bound items can have restricted
  actions and must be handled server-side.

Observed Neverlands action semantics:

```text
wear item from bag:      main.php?get_id=57&uid=<item-id>&s=1&vcode=<token>
remove item from slot:   main.php?get_id=57&uid=<item-id>&s=0&vcode=<token>
```

The exact URL shape does not need to be copied, but the game must preserve the
semantic contract: the server offers the action, the browser submits it, and the
server validates item ownership, item state, slot compatibility, requirements,
and action token before mutating equipment state.

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

The 2026-05-19 starter arena fight confirmed that equipped items are also
embedded in the active fight payload. The starter character rendered
`Перочинный Нож` in the weapon slot and in the weapon/shield slot, and those
equipped items coincided with the captured starter combat profile of 114 AP and
45/65 physical attack costs. Do not treat equipment as profile-only decoration:
the same equipment state must feed profile, inventory, and combat formula
surfaces.

The live inventory capture adds these launch requirements:

- inventory opens from the same player shell as the character profile;
- the current page's context button is disabled, while `Ваш персонаж` and
  `Вернуться` remain active;
- inventory shows an equipment doll plus carried item rows;
- an empty inventory still shows the equipment doll, money/stat/experience
  side panel, category filters, and an explicit empty-state message;
- category filters are visible above the item list, including top-level item
  families, equipment subcategories, a full/short information toggle, and a
  reset-filter action;
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
- wearing and removing are tokenized/server-authorized equipment actions;
- transfer, gift, sale, and delete are tokenized/server-authorized actions;
  launch MVP needs equip/use/delete first, with transfer/gift/sale deferred
  unless the economy loop explicitly needs them.

## Inventory Rules

- Characters have finite carry capacity.
- Capacity can be weight-based, slot-based, or both.
- Stackable items stack only with matching item identity and state.
- Quest items can be protected from normal sale/discard.
- Inventory actions are server-authoritative.
- Wearing, removing, using, deleting, selling, transferring, and gifting are
  separate actions and should not share client-invented state.

## Launch Design Target

The launch inventory should support:

- inventory page inside the game shell with equipment panel, stats panel,
  category filters, sort actions, inventory mass, item rows, and empty slots;
- item templates for equipment, consumables, materials, resources, quest items,
  and miscellaneous items;
- item instances with quantity, equipped slot, current durability, requirement
  overrides, effect overrides, expiry metadata, bound/protected state, and
  per-item properties;
- equip, unequip, use, sort, and discard as server-authorized actions;
- requirement validation for level, AP/action points, primary stats, and mapped
  numeric skills before equip/use;
- equipment effects feeding character stats, effective max HP, attack, defense,
  accuracy, dodge, armor pierce, fortitude, elemental resistances, and skill
  bonuses;
- combat durability degradation for PvE and PvP equipment;
- consumable durability charges before quantity consumption;
- discard protection for equipped, bound, protected, locked, and quest items.

Remaining design detail before launch:

- canonical item seeds/templates matching the captured Neverlands inventory;
- full label normalization for all captured effects and requirements;
- complete slot rules for two-handed weapons, layered armor, rings, belt
  contents, pocket contents, and relics;
- repair and breakage UX, including player-visible messages when gear breaks;
- capacity enforcement across loot, pickup, trade, shop purchase, and quest
  reward flows;
- server-issued inventory action keys when normal Rails form protection is not
  enough for the final gameplay action model;
- transfer, gift, sale, dealer, and equipment-set saving flows.

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
