# Items, Inventory, And Equipment

## Purpose

Items make character progression concrete. Inventory limits, equipment
requirements, weight, durability, shops, and loot give the world economy and
combat systems practical constraints.

## Source Material

Inputs:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_game_shell_ui.md`
- `doc/design/reference/neverlands_live_inventory_items.md`
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
- materials.

## Equipment Rules

- Items define allowed slot.
- A character can equip only one item per slot unless a slot supports pairs.
- Two-handed weapons occupy both hand capacity.
- Items can require level, stats, skills, or other source-backed gates.
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
- equipped, broken, protected, or locked items can have restricted
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

## Weapon Effects On Combat

Weapons change the combat profile, not only the damage number shown in an item
row.

Design rules:

- equipped weapons can change AP budget, physical attack cost seed, simple
  attack cost, aimed attack cost, hit range, accuracy, dodge, armor pierce,
  critical chance, skill requirements, and durability loss;
- not every equipment change must alter every combat-profile field; AP, attack
  cost, damage, accuracy, and armor pierce are separate outputs of the formula;
- dual-wield or weapon-plus-shield states must be explicit slot states, not
  inferred from item names;
- removing an equipped weapon through the inventory equipment doll must affect
  the next generated combat profile;
- fighting with no equipped weapon should fall back to the unarmed profile:
  no weapon-family modifiers, no weapon durability loss, and damage/stat output
  based on unarmed rules;
- weapon-family skills, such as knife mastery, should affect only matching
  weapon families unless a source capture proves a broader rule;
- the combat screen should display the resulting AP and attack costs from the
  generated profile so the player can see that equipment changed the fight.

The live starter account wearing two knives is the verification case for this
rule. The May 19 capture compared:

1. regular mannequin fight with both knives equipped;
2. mannequin fight using `Spirit Arrow` while both knives remained equipped;
3. mannequin fight after both knives were removed from the inventory equipment
   doll.

Observed equipment deltas:

| State | Equipped Weapon Slots | Visible Armor Pierce | Starter Fight AP/Costs |
| --- | ---: | ---: | --- |
| Two starter knives | 2 | 2 | 114 AP, 45/65 physical |
| No equipped weapon | 0 | 0 | 114 AP, 45/65 physical |

The two starter knives therefore affected visible armor pierce and observed
damage output in this capture, while the AP budget and physical attack costs
stayed stable. Treat `114` AP and `45/65` attack costs as captured starter
profile values, not universal knife constants.

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

The 2026-05-25 live shell pass also confirms that inventory actions remain
inside the persistent game shell. The current page action is disabled,
profile/return/city actions remain available, inventory mass is shown above the
item list, and use/delete actions ask for confirmation before submitting
item-specific tokens.

The 2026-06-01 inventory/items capture confirms the launch item-row contract in
full-information mode:

- inventory rows have short and full display modes;
- full mode renders `свойства` and `требования` columns for each item;
- properties include price, current/max durability, damage, armor class,
  pockets, HP, mana, primary stat modifiers, combat modifiers, weapon-skill
  modifiers, elemental resistances, expiry, and descriptions;
- requirements include mass, level, primary stats, AP/action points, numeric
  weapon skills, and non-combat skills such as stealth or linguistics;
- unmet requirements are visible in red and should be shown, not hidden;
- inventory equip/use availability is separate from item visibility: rows with
  unmet requirements stay visible but may not expose `Wear` or `Use`;
- wearing `Кольцо Знаний` moved the item instance into a ring slot and changed
  visible `Знания` from `14` to `17`, with the breakdown displayed as
  `(14+3)`;
- removing the same ring moved it back to carried inventory, restored
  `Знания` to `14`, and issued fresh action keys;
- inventory mass stayed `57.00/155` before, during, and after wearing the
  ring, so equipped items still counted toward carried mass in this capture;
- the `Снять все вещи` utility appears after gear is equipped and should be a
  deferred but source-backed bulk unequip action.
- `Вещи` is the equipment/item-row family. Other inventory families can replace
  the equipment doll and stat/mass side layout with family-specific panels:
  elixir empty state, alchemy/fishing/cooking/carpentry inventory sections,
  resource sections, discard actions, and quest-journal empty state.
- equipment sets are source-backed: `Запомнить комплект` saves a named current
  equipment set, existing sets can be worn through a multi-item equipment
  action, and set deletion is confirmable. This is a deferred loadout feature,
  not required for first equip/unequip.
- transfer, gift, player-targeted sale, and currency transfer open tokenized
  inline forms in the same inventory surface. They are separate from shop sell
  and stay deferred until a dedicated direct-trade capture defines them.
- item use can be immediate, targeted by nickname, combat-contextual,
  doctor/healing priced, teleport/destination-based, or attack/protection
  scroll based. Only captured simple use behavior belongs in the launch scope.
- fight slot rendering can make selected slotted items clickable combat
  actions, so the equipment model must be able to feed both passive stats and
  future active item actions.

Launch implementation must support visible base-plus-equipment stat deltas on
the profile/inventory stat panel. The same effective stat result must later be
used by combat profile generation, vitals, skill gates, item gates, and
movement/carry calculations.

## Inventory Rules

- Characters have finite carry capacity.
- Capacity can be weight-based, slot-based, or both.
- Stackable items stack only with matching item identity and state.
- Inventory actions are server-authoritative.
- Wearing, removing, using, deleting, selling, transferring, and gifting are
  separate actions and should not share client-invented state.

## Launch Design Target

The launch inventory should support:

- inventory page inside the game shell with equipment panel, stats panel,
  category filters, sort actions, inventory mass, item rows, and empty slots;
- item templates for equipment, consumables, materials, and miscellaneous items;
- item instances with quantity, equipped slot, current durability, requirement
  overrides, effect overrides, expiry metadata, bound/protected state, and
  per-item properties;
- equip, unequip, use, sort, and discard as server-authorized actions;
- requirement validation for level, AP/action points, primary stats, and mapped
  numeric skills before equip/use;
- visible unmet requirements and availability reasons without hiding the item
  row;
- visible base-plus-equipment stat deltas after any equipment change;
- equipped item instances shown in the equipment doll and removed from carried
  item rows while still counting toward carried mass;
- equipment effects feeding character stats, effective max HP/MP, attack,
  defense, accuracy, dodge, armor pierce, fortitude, elemental resistances, and
  skill bonuses;
- family-aware inventory renderers so non-equipment families can show explicit
  empty states and later production/resource actions without being forced into
  equipment rows;
- aliased Neverlands slot handling for rings, weapon/shield, jewelry, and
  explicit two-handed weapons occupying both hand capacity;
- canonical captured item seeds/templates for the observed ring, jewelry,
  armor, belt, boots, gloves, bracers, weapon, staff, and scroll examples;
- combat durability degradation for player, team, and NPC fight equipment;
- consumable durability charges before quantity consumption;
- discard protection for equipped, bound, protected, and locked items.

Remaining design detail before launch:

- exact slot rules for layered armor, belt contents, pocket contents, relic
  activation, and combat-clickable slotted items;
- exact MVP boundary for non-equipment families: empty states are captured, but
  crafting/production/resource behavior needs separate source capture before
  implementation;
- repair and breakage UX, including player-visible messages when gear breaks;
- capacity enforcement across loot, pickup, and shop purchase flows;
- server-issued inventory action keys when normal Rails form protection is not
  enough for the final gameplay action model;
- direct trade settlement edge cases, dealer transfers, targeted scroll/doctor
  effects, and combat item-use slots need dedicated source capture before they
  go beyond the basic inventory forms.

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
- `features/economy_trading_shops.md`: shops buy and sell inventory items;
  future player trade needs source capture first.
- `features/npcs_quests.md`: future quest-item behavior needs source capture
  before implementation.
