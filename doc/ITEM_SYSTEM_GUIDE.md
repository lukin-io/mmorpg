# ITEM_SYSTEM_GUIDE.md — Items, Inventory & Loot Architecture

This guide defines the item, inventory, equipment, and loot design
for the Neverlands Rails MMORPG.

---

# 1. Item Model

```
Item
  id
  name
  item_type (weapon, armor, potion, etc)
  slot (weapon, head, chest, ring1, ring2, etc)
  rarity (common, rare, epic, legendary)
  stats (JSON)
  value
```

Example stats:
```json
{ "attack": 5, "defense": 2, "crit_chance": 1 }
```

---

# 2. Inventory

```
Inventory
  belongs_to :character
  items (serialized array of item IDs or embedded JSON)
  capacity: Integer
```

Inventory operations:
- add item
- remove item
- stack items
- sort items
- capacity check

Logic lives in:

```
app/services/game/inventory/**
```

---

# 3. Equipment

Equipment slots are limited:
- weapon (1)
- armor (1)
- helmet
- boots
- rings (2)
- amulet

Equipping rules:
- slot must match item type
- cannot equip two 2-handed weapons
- cannot equip incompatible item types

---

# 4. Loot Tables

Loot table example:

```ruby
{
  "Wolf Fang" => 60,
  "Torn Pelt" => 30,
  "Rare Pelt" => 5,
  nil => 5              # no drop
}
```

Implemented in:

```
Game::Economy::LootGenerator
```

---

# 5. Crafting System

Professions:
- Fishing
- Herbalism
- Hunting
- Doctor/Healer

Recipes:

```
Recipe
  name
  inputs (item IDs)
  outputs (item IDs)
  skill_required
```

---

# 6. Consumables

Example:
- potions (hp, mana)
- scrolls (one-time spell)
- bombs (AoE damage)

Stored as:
```
item_type: "consumable"
stats: { heal_hp: 10 }
```

---

# 7. Item Rarity & Colors

| rarity    | color    |
|-----------|----------|
| common    | gray     |
| uncommon  | green    |
| rare      | blue     |
| epic      | purple   |
| legendary | orange   |

Use Tailwind or CSS classes:
```
.rare { color: blue }
```

---

# 8. Summary

Use this guide when implementing:
- items & stats
- inventory rules
- equipment
- loot tables
- crafting
- consumables

This keeps the MMORPG’s item system consistent and extensible.
