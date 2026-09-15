# Item Book

Reviewed against repository content and runtime owners on **2026-09-14**.
This is the general catalog and editing guide for item definitions, owned
equipment, consumables, materials and licenses. It identifies what exists,
where it can come from, which properties do something, and how changes affect
players. Baseline definitions are not a live database/stock report.

Related books: [NPC](NPC.md), [WORLD](WORLD.md), [FORMULAS](FORMULAS.md) and
[ARTWORK](ARTWORK.md). [SCROLLS](SCROLLS.md) is the full guide to carried scrolls,
targeted activation and typed licenses; [COMBAT](COMBAT.md) explains how equipped
items affect fights and aftermath. Detailed behavior remains in
[Inventory](features/player_inventory.md), [Shop](features/shop_economy.md),
[Medical Care](features/medical_care.md) and [Combat](features/arena_combat.md).
Source provenance starts with the [Inventory evidence index](design/reference/inventory/README.md)
and [item design](design/features/items_inventory_equipment.md). The
[MVP plan](design/launch_mvp_plan.md) owns delivery status.

[CHARACTER](CHARACTER.md) explains equipment composition and capacity;
[MEDICAL](MEDICAL.md) explains bag requirements and cure/use behavior;
[ECONOMY](ECONOMY.md) explains prices, stock, licenses and payment/receipt flows.

Before editing existing items or adding new definitions/effects, follow the
[context/update map](DOCUMENTATION.md#21-required-context-and-update-map).
Check the consuming Inventory/Shop/Medical/Combat contract and related NPC
pools, formulas and location stock; update the owners whose behavior or
reference content changes, including [events](features/game_shell.md#gameplay-event-catalog)
when a reward notice changes.

## Contents

- [1. Definition, ownership and availability](#1-definition-ownership-and-availability)
- [2. Current item catalog](#2-current-item-catalog)
- [3. Fields, slots and effective properties](#3-fields-slots-and-effective-properties)
- [4. Acquisition and item lifecycle](#4-acquisition-and-item-lifecycle)
- [5. Artwork and presentation](#5-artwork-and-presentation)
- [6. Editing recipes](#6-editing-recipes)
- [7. Current limitations](#7-current-limitations)
- [8. Verification and maintenance](#8-verification-and-maintenance)
- [Use cases and cross-feature effects](#use-cases-and-cross-feature-effects)

## 1. Definition, ownership and availability

| Layer | Owner | Meaning |
|---|---|---|
| Reusable item definition | [ItemTemplate](../app/models/item_template.rb) | Stable key/name, type, slot, weight, base price, durability, stack size, requirements and effects |
| Owned item/stack | [InventoryItem](../app/models/inventory_item.rb) | Inventory ownership, quantity, equipped slot, current durability, expiry/binding and instance overrides |
| Inventory | [Inventory](../app/models/inventory.rb) | Stack storage, weight and saved equipment-set references |
| Availability in one shop | [ShopStock](../app/models/shop_stock.rb), [ShopAccount](../app/models/shop_account.rb) | Actual local quantity/capacity and merchant funds; a template price is not available stock |
| Purchased permission | [CharacterLicense](../app/models/character_license.rb) | Timed trading/Doctor permission; a typed license purchase creates this record instead of a carried item |
| NPC worn image/property | [NpcTemplate](../app/models/npc_template.rb) equipment metadata | Descriptive paper doll, independent of player item ownership and drops |

Use stable `ItemTemplate.key` when authoring rewards, art and content references.
Use an owned `InventoryItem.id` only for a particular character's action. A key,
image, price or source name never grants an item to a player.

The baseline definitions come from three sources:

- [starter_shop.json](../db/seeds/data/starter_shop.json): 80 Shop definitions.
- [shop_inventory.rb](../db/seeds/shop_inventory.rb): ten supplemental inventory
  definitions, six licenses and two loot materials; it also supports bounded
  development fixture grants.
- [combat_care.rb](../db/seeds/combat_care.rb): four healer bags/kits and the
  small health elixir.

That is **103 distinct baseline keys**. This inventory excludes arbitrary
development fixtures, NPC decorative gear and read-only Mine merchandise text.
The main Forpost Shop stock baseline references the 80 JSON keys, three
supplemental jewelry keys and six licenses. Some historical jewelry definitions
lack the `shop.sold` eligibility flag: a stock row alone does not make them
buyable. Hospital stock is its own four-item assortment. See
[shop_accounts.rb](../db/seeds/shop_accounts.rb) and the Shop handbook.

## 2. Current item catalog

### Shop assortment definitions

The following tables mirror the 80 JSON definitions. Prices are **base NV**,
not resale payouts; durability is the template maximum. Requirements/effects
use actual stored keys so an editor can find them directly. All entries link
to their original runtime artwork. The JSON also contains exact source names,
stock baselines and any display-only properties. Stock changes through gameplay
and is deliberately not maintained as a live count in this book.

#### Knives

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `penknife` — Penknife (`equipment`, `main_hand`) | level: 1; ap: 40 | weapon_family: "knife"; damage_min: 1; damage_max: 2; armor_pierce: 1 | 7 | 5 / 10 / 1 | [image](../app/assets/images/items/penknife.png) |
| `assassin_dagger` — Assassin Dagger (`equipment`, `main_hand`) | level: 3; luck: 7; dexterity: 10; ap: 41; knife_mastery: 10 | weapon_family: "knife"; damage_min: 3; damage_max: 5; evasion: 5; accuracy: 5; armor_pierce: 3; luck: 1 | 19 | 6 / 20 / 1 | [image](../app/assets/images/items/assassin_dagger.png) |
| `butcher_cleaver` — Butcher Cleaver (`equipment`, `main_hand`) | level: 3; luck: 9; ap: 51; knife_mastery: 10 | weapon_family: "knife"; damage_min: 3; damage_max: 5; crushing: 10; armor_pierce: 4; strength: 1 | 20 | 6 / 20 / 1 | [image](../app/assets/images/items/butcher_cleaver.png) |
| `hunter_knife` — Hunter Knife (`equipment`, `main_hand`) | level: 3; dexterity: 16; ap: 26; knife_mastery: 10; dual_wielding: 10 | weapon_family: "knife"; damage_min: 4; damage_max: 6; evasion: 10; armor_pierce: 5; dexterity: 1; skill_bonuses: {"knife_mastery":5} | 19 | 6 / 20 / 1 | [image](../app/assets/images/items/hunter_knife.png) |
| `mage_dagger` — Mage Dagger (`equipment`, `main_hand`) | level: 5; luck: 5; knowledge: 15; ap: 55; knife_mastery: 10 | weapon_family: "knife"; damage_min: 4; damage_max: 9; crushing: 25; fortitude: 5; armor_pierce: 10; hp: 15; mana: 15; luck: 2 | 75 | 5 / 50 / 1 | [image](../app/assets/images/items/mage_dagger.png) |

#### Swords

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `action_blade` — Action Blade (`equipment`, `main_hand`) | level: 2; strength: 5; luck: 6; dexterity: 8; ap: 53; sword_mastery: 4 | weapon_family: "sword"; damage_min: 2; damage_max: 5; accuracy: 5; armor_pierce: 6 | 14 | 4 / 15 / 1 | [image](../app/assets/images/items/action_blade.png) |
| `sensation_sword` — Sensation Sword (`equipment`, `main_hand`) | level: 2; strength: 5; health: 8; ap: 68; sword_mastery: 4 | weapon_family: "sword"; damage_min: 2; damage_max: 5; fortitude: 5; armor_pierce: 5 | 14 | 5 / 15 / 1 | [image](../app/assets/images/items/sensation_sword.png) |
| `double_blade` — Double Blade (`equipment`, `main_hand`) | level: 4; strength: 6; luck: 8; health: 6; ap: 58; sword_mastery: 10; two_handed_mastery: 10 | weapon_family: "sword"; damage_min: 10; damage_max: 18; crushing: 15; fortitude: 5; armor_pierce: 15; strength: 1 | 60 | 9 / 25 / 1 | [image](../app/assets/images/items/double_blade.png) |
| `curved_blade` — Curved Blade (`equipment`, `main_hand`) | level: 4; strength: 7; health: 10; ap: 72; sword_mastery: 10 | weapon_family: "sword"; damage_min: 4; damage_max: 7; fortitude: 15; accuracy: 5; armor_pierce: 7 | 60 | 7 / 20 / 1 | [image](../app/assets/images/items/curved_blade.png) |
| `smile_sword` — Smile Sword (`equipment`, `main_hand`) | level: 4; strength: 6; luck: 9; dexterity: 11; ap: 55; sword_mastery: 10 | weapon_family: "sword"; damage_min: 6; damage_max: 12; evasion: 10; accuracy: 10; armor_pierce: 8 | 60 | 6 / 20 / 1 | [image](../app/assets/images/items/smile_sword.png) |

#### Axes

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `woodcutter_axe` — Woodcutter Axe (`equipment`, `main_hand`) | level: 2; strength: 6; luck: 8; dexterity: 7; ap: 56; axe_mastery: 5 | weapon_family: "axe"; damage_min: 3; damage_max: 6; crushing: 4; armor_pierce: 6 | 17 | 7 / 15 / 1 | [image](../app/assets/images/items/woodcutter_axe.png) |
| `search_axe` — Search Axe (`equipment`, `main_hand`) | level: 2; strength: 5; luck: 8; health: 6; ap: 56; axe_mastery: 5 | weapon_family: "axe"; damage_min: 2; damage_max: 6; crushing: 5; armor_pierce: 4 | 15 | 6 / 15 / 1 | [image](../app/assets/images/items/search_axe.png) |
| `cleaving_axe` — Cleaving Axe (`equipment`, `main_hand`) | level: 4; strength: 13; luck: 9; ap: 62; axe_mastery: 16; two_handed_mastery: 16 | weapon_family: "axe"; damage_min: 12; damage_max: 19; crushing: 25; fortitude: 10; evasion: -5; armor_pierce: 16 | 65 | 10 / 30 / 1 | [image](../app/assets/images/items/cleaving_axe.png) |
| `prosperity_axe` — Prosperity Axe (`equipment`, `main_hand`) | level: 4; strength: 8; luck: 12; dexterity: 10; ap: 60; axe_mastery: 15 | weapon_family: "axe"; damage_min: 7; damage_max: 12; crushing: 15; fortitude: 5; armor_pierce: 12 | 65 | 9 / 30 / 1 | [image](../app/assets/images/items/prosperity_axe.png) |
| `distortion_axe` — Distortion Axe (`equipment`, `main_hand`) | level: 4; strength: 5; luck: 12; health: 6; ap: 60; axe_mastery: 16 | weapon_family: "axe"; damage_min: 9; damage_max: 11; crushing: 10; fortitude: 10; armor_pierce: 8 | 65 | 9 / 25 / 1 | [image](../app/assets/images/items/distortion_axe.png) |

#### Blunt weapons

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `townsman_club` — Townsman Club (`equipment`, `main_hand`) | level: 2; strength: 8; health: 8; ap: 67; bludgeoning_mastery: 4 | weapon_family: "blunt"; damage_min: 2; damage_max: 3; fortitude: 7; armor_pierce: 2 | 13 | 6 / 15 / 1 | [image](../app/assets/images/items/townsman_club.png) |
| `apprentice_hammer` — Apprentice Hammer (`equipment`, `main_hand`) | level: 4; strength: 10; luck: 8; ap: 60; bludgeoning_mastery: 16; two_handed_mastery: 16 | weapon_family: "blunt"; damage_min: 8; damage_max: 19; crushing: 10; fortitude: 30; evasion: -10; armor_pierce: 8 | 58 | 9 / 20 / 1 | [image](../app/assets/images/items/apprentice_hammer.png) |
| `steel_club` — Steel Club (`equipment`, `main_hand`) | level: 4; strength: 10; health: 10; ap: 69; bludgeoning_mastery: 8 | weapon_family: "blunt"; damage_min: 5; damage_max: 9; crushing: 5; fortitude: 5; armor_pierce: 6 | 58 | 10 / 25 / 1 | [image](../app/assets/images/items/steel_club.png) |
| `steppe_sword` — Steppe Sword (`equipment`, `main_hand`) | level: 4; strength: 8; health: 8; ap: 69; bludgeoning_mastery: 8 | weapon_family: "blunt"; damage_min: 6; damage_max: 8; fortitude: 5; armor_pierce: 6; strength: 1 | 40 | 7 / 15 / 1 | [image](../app/assets/images/items/steppe_sword.png) |
| `war_pick` — War Pick (`equipment`, `main_hand`) | level: 5; strength: 10; health: 12; ap: 80; bludgeoning_mastery: 20 | weapon_family: "blunt"; damage_min: 6; damage_max: 8; fortitude: 25; armor_pierce: 12; hp: 15; strength: 1 | 85 | 9 / 25 / 1 | [image](../app/assets/images/items/war_pick.png) |

#### Halberds and spears

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `primitive_spear` — Primitive Spear (`equipment`, `main_hand`) | level: 2; dexterity: 5; ap: 45; polearm_mastery: 5 | weapon_family: "polearm"; damage_min: 1; damage_max: 7; evasion: 5; armor_pierce: 10; skill_bonuses: {"polearm_mastery":5} | 15 | 5 / 15 / 1 | [image](../app/assets/images/items/primitive_spear.png) |
| `parrying_spear` — Parrying Spear (`equipment`, `main_hand`) | level: 4; strength: 8; dexterity: 6; ap: 52; polearm_mastery: 17; dual_wielding: 17 | weapon_family: "polearm"; damage_min: 4; damage_max: 17; crushing: 15; fortitude: 5; armor_pierce: 18; strength: 1; skill_bonuses: {"polearm_mastery":10} | 60 | 12 / 27 / 1 | [image](../app/assets/images/items/parrying_spear.png) |
| `pilum` — Pilum (`equipment`, `main_hand`) | level: 4; strength: 5; dexterity: 9; ap: 47; polearm_mastery: 10 | weapon_family: "polearm"; damage_min: 3; damage_max: 13; fortitude: 5; evasion: 15; armor_pierce: 12; skill_bonuses: {"polearm_mastery":5} | 60 | 8 / 20 / 1 | [image](../app/assets/images/items/pilum.png) |
| `adventurer_spear` — Adventurer Spear (`equipment`, `main_hand`) | level: 5; strength: 10; dexterity: 10; health: 8; ap: 47; polearm_mastery: 20 | weapon_family: "polearm"; damage_min: 5; damage_max: 13; fortitude: 10; evasion: 15; armor_pierce: 11; strength: -1; dexterity: 2 | 90 | 16 / 25 / 1 | [image](../app/assets/images/items/adventurer_spear.png) |
| `trident` — Trident (`equipment`, `main_hand`) | level: 5; strength: 12; dexterity: 10; ap: 55; polearm_mastery: 9; two_handed_mastery: 9 | weapon_family: "polearm"; damage_min: 5; damage_max: 20; crushing: 20; fortitude: 5; armor_pierce: 21; strength: 2; luck: 1; dexterity: -1 | 90 | 20 / 25 / 1 | [image](../app/assets/images/items/trident.png) |

#### Staves

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `small_earthly_blessings_staff` — Small Earthly Blessings Staff (`equipment`, `main_hand`) | level: 6; luck: 9; dexterity: 8; knowledge: 15; ap: 63; staff_mastery: 20 | weapon_family: "staff"; damage_min: 8; damage_max: 14; crushing: 15; accuracy: 15; armor_pierce: 15; mana: 25; luck: 2; dexterity: 1 | 165 | 12 / 30 / 1 | [image](../app/assets/images/items/small_earthly_blessings_staff.png) |
| `small_crescent_staff` — Small Crescent Staff (`equipment`, `main_hand`) | level: 6; luck: 6; dexterity: 10; knowledge: 15; ap: 63; staff_mastery: 20 | weapon_family: "staff"; damage_min: 6; damage_max: 11; evasion: 15; accuracy: 10; armor_pierce: 14; mana: 30; dexterity: 1; knowledge: 2 | 150 | 11 / 30 / 1 | [image](../app/assets/images/items/small_crescent_staff.png) |
| `small_aspiration_staff` — Small Aspiration Staff (`equipment`, `main_hand`) | level: 6; luck: 10; dexterity: 7; knowledge: 15; ap: 63; staff_mastery: 20 | weapon_family: "staff"; damage_min: 6; damage_max: 13; fortitude: 15; accuracy: 10; armor_pierce: 17; mana: 40; luck: 1; dexterity: -1; knowledge: 2 | 150 | 13 / 30 / 1 | [image](../app/assets/images/items/small_aspiration_staff.png) |
| `small_power_staff` — Small Power Staff (`equipment`, `main_hand`) | level: 6; luck: 7; dexterity: 9; knowledge: 15; ap: 63; staff_mastery: 20 | weapon_family: "staff"; damage_min: 7; damage_max: 12; crushing: 15; fortitude: 15; armor_pierce: 16; mana: 40; strength: 2 | 160 | 12 / 30 / 1 | [image](../app/assets/images/items/small_power_staff.png) |
| `earthly_blessings_staff` — Earthly Blessings Staff (`equipment`, `main_hand`) | level: 8; luck: 14; dexterity: 11; knowledge: 16; ap: 67; staff_mastery: 40 | weapon_family: "staff"; damage_min: 14; damage_max: 21; crushing: 25; accuracy: 20; armor_pierce: 21; mana: 40; luck: 3; dexterity: 2 | 290 | 13 / 60 / 1 | [image](../app/assets/images/items/earthly_blessings_staff.png) |

#### Shields

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `advantage_shield` — Advantage Shield (`equipment`, `off_hand`) | level: 3; strength: 9; health: 9; ap: 40 | weapon_family: "shield"; damage_min: 1; damage_max: 2; accuracy: 5; armor_class: 4 | 33 | 6 / 25 / 1 | [image](../app/assets/images/items/advantage_shield.png) |
| `stubborn_shield` — Stubborn Shield (`equipment`, `off_hand`) | level: 3; strength: 10; health: 9; ap: 40 | weapon_family: "shield"; fortitude: 10; armor_class: 6 | 30 | 9 / 30 / 1 | [image](../app/assets/images/items/stubborn_shield.png) |
| `grim_shield` — Grim Shield (`equipment`, `off_hand`) | level: 5; strength: 10; health: 12; ap: 40 | weapon_family: "shield"; fortitude: 10; accuracy: 10; armor_class: 10; strength: 1 | 80 | 10 / 50 / 1 | [image](../app/assets/images/items/grim_shield.png) |
| `dew_shield` — Dew Shield (`equipment`, `off_hand`) | level: 5; strength: 10; health: 15; ap: 70 | weapon_family: "shield"; fortitude: 20; armor_class: 12; hp: 10 | 80 | 12 / 60 / 1 | [image](../app/assets/images/items/dew_shield.png) |
| `possibility_shield` — Possibility Shield (`equipment`, `off_hand`) | level: 7; strength: 18; health: 15; ap: 70 | weapon_family: "shield"; fortitude: 20; accuracy: 20; armor_class: 12; hp: 30; strength: 2 | 130 | 15 / 60 / 1 | [image](../app/assets/images/items/possibility_shield.png) |

#### Armor

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `caution_armor` — Caution Armor (`equipment`, `chest`) | level: 2; strength: 8; health: 8 | fortitude: 10; armor_class: 6 | 20 | 9 / 10 / 1 | [image](../app/assets/images/items/caution_armor.png) |
| `assassin_suit` — Assassin Suit (`equipment`, `chest`) | level: 2; dexterity: 12; health: 5 | evasion: 10; armor_class: 1 | 20 | 1 / 10 / 1 | [image](../app/assets/images/items/assassin_suit.png) |
| `salvation_jacket` — Salvation Jacket (`equipment`, `chest`) | level: 2; luck: 12; health: 5 | crushing: 10; armor_class: 3 | 20 | 8 / 10 / 1 | [image](../app/assets/images/items/salvation_jacket.png) |
| `life_shirt` — Life Shirt (`equipment`, `chest`) | level: 2 | hp: 10 | 10 | 1 / 20 / 1 | [image](../app/assets/images/items/life_shirt.png) |
| `knowledge_shirt` — Knowledge Shirt (`equipment`, `chest`) | level: 2 | knowledge: 1 | 10 | 1 / 20 / 1 | [image](../app/assets/images/items/knowledge_shirt.png) |

#### Helmets

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `leather_cap` — Leather Cap (`equipment`, `head`) | level: 2; dexterity: 5 | evasion: 5; armor_class: 2; hp: 5 | 20 | 2 / 10 / 1 | [image](../app/assets/images/items/leather_cap.png) |
| `earflap_hat` — Earflap Hat (`equipment`, `head`) | level: 2 | armor_class: 1; hp: 15 | 20 | 2 / 10 / 1 | [image](../app/assets/images/items/earflap_hat.png) |
| `hunter_helmet` — Hunter Helmet (`equipment`, `head`) | level: 2; luck: 5 | armor_class: 2; luck: 1 | 20 | 2 / 20 / 1 | [image](../app/assets/images/items/hunter_helmet.png) |
| `bandit_helmet` — Bandit Helmet (`equipment`, `head`) | level: 2; strength: 4; health: 6 | fortitude: 5; armor_class: 5; hp: 10 | 20 | 2 / 10 / 1 | [image](../app/assets/images/items/bandit_helmet.png) |
| `spellcaster_cap` — Spellcaster Cap (`equipment`, `head`) | level: 3; knowledge: 10 | armor_class: 1; hp: 15; mana: 20; skill_bonuses: {"fast_mana_regeneration":5} | 40 | 2 / 15 / 1 | [image](../app/assets/images/items/spellcaster_cap.png) |

#### Boots

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `peasant_boots` — Peasant Boots (`equipment`, `feet`) | level: 1; health: 5 | armor_class: 2; hp: 5 | 15 | 3 / 10 / 1 | [image](../app/assets/images/items/peasant_boots.png) |
| `military_boots` — Military Boots (`equipment`, `feet`) | level: 3; strength: 8; health: 8 | fortitude: 5; armor_class: 5; hp: 10; strength: 1 | 30 | 5 / 20 / 1 | [image](../app/assets/images/items/military_boots.png) |
| `hunter_boots` — Hunter Boots (`equipment`, `feet`) | level: 3; luck: 7; health: 7 | crushing: 5; armor_class: 3; luck: 1 | 30 | 3 / 10 / 1 | [image](../app/assets/images/items/hunter_boots.png) |
| `petty_thief_sandals` — Petty Thief Sandals (`equipment`, `feet`) | level: 3; dexterity: 7; health: 7 | evasion: 5; armor_class: 1; dexterity: 1 | 30 | 2 / 10 / 1 | [image](../app/assets/images/items/petty_thief_sandals.png) |
| `mage_apprentice_shoes` — Mage Apprentice Shoes (`equipment`, `feet`) | level: 3; knowledge: 12 | hp: 5; mana: 10; strength: -2; knowledge: 1; skill_bonuses: {"staff_mastery":5,"fire_magic":3,"water_magic":3,"air_magic":3,"earth_magic":3,"fire_magic_resistance":4,"water_magic_resistance":4,"air_magic_resistance":4,"earth_magic_resistance":4} | 35 | 3 / 25 / 1 | [image](../app/assets/images/items/mage_apprentice_shoes.png) |

#### Pants

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `worn_pants` — Worn Pants (`equipment`, `legs`) | level: 2 | fortitude: 10; armor_class: 2; hp: 10 | 20 | 4 / 5 / 1 | [image](../app/assets/images/items/worn_pants.png) |
| `peasant_trousers` — Peasant Trousers (`equipment`, `legs`) | level: 5; luck: 19; health: 10 | accuracy: 15; armor_class: 5; hp: 15; luck: 1 | 80 | 8 / 40 / 1 | [image](../app/assets/images/items/peasant_trousers.png) |
| `hunter_trousers` — Hunter Trousers (`equipment`, `legs`) | level: 5; dexterity: 19; health: 10 | evasion: 15; armor_class: 5; hp: 15; dexterity: 1 | 80 | 8 / 40 / 1 | [image](../app/assets/images/items/hunter_trousers.png) |
| `recruit_chainmail_pants` — Recruit Chainmail Pants (`equipment`, `legs`) | level: 7; strength: 18; health: 15 | fortitude: 15; accuracy: 15; armor_class: 12; hp: 25; strength: 2 | 140 | 11 / 60 / 1 | [image](../app/assets/images/items/recruit_chainmail_pants.png) |
| `leather_breeches` — Leather Breeches (`equipment`, `legs`) | level: 8; dexterity: 27; health: 16 | evasion: 35; accuracy: 15; armor_class: 10; hp: 20; dexterity: 3 | 180 | 12 / 60 / 1 | [image](../app/assets/images/items/leather_breeches.png) |

#### Belts

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `advantage_belt` — Advantage Belt (`equipment`, `belt`) | level: 3; dexterity: 8; health: 7 | evasion: 10; armor_class: 1; dexterity: 1 | 25 | 4 / 20 / 1 | [image](../app/assets/images/items/advantage_belt.png) |
| `thick_leather_belt` — Thick Leather Belt (`equipment`, `belt`) | level: 3; strength: 10; health: 8 | fortitude: 10; armor_class: 3; strength: 1 | 25 | 5 / 20 / 1 | [image](../app/assets/images/items/thick_leather_belt.png) |
| `thin_leather_belt` — Thin Leather Belt (`equipment`, `belt`) | level: 3; luck: 8; health: 7 | crushing: 10; armor_class: 2; strength: 1 | 25 | 4 / 20 / 1 | [image](../app/assets/images/items/thin_leather_belt.png) |
| `diamond_sash` — Diamond Sash (`equipment`, `belt`) | level: 5; knowledge: 8; health: 6 | accuracy: 20; armor_class: 3; mana: 20; luck: 1; dexterity: 1; skill_bonuses: {"knife_mastery":5,"staff_mastery":5,"air_magic_resistance":7} | 100 | 4 / 30 / 1 | [image](../app/assets/images/items/diamond_sash.png) |
| `emerald_sash` — Emerald Sash (`equipment`, `belt`) | level: 5; knowledge: 8; health: 7 | fortitude: 20; armor_class: 2; hp: 40; mana: 20; knowledge: 1; skill_bonuses: {"knife_mastery":5,"staff_mastery":5,"earth_magic_resistance":7} | 100 | 4 / 30 / 1 | [image](../app/assets/images/items/emerald_sash.png) |

#### Gloves

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `dexterity_gloves` — Dexterity Gloves (`equipment`, `hands`) | level: 2; dexterity: 5 | dexterity: 1 | 18 | 2 / 10 / 1 | [image](../app/assets/images/items/dexterity_gloves.png) |
| `strength_gloves` — Strength Gloves (`equipment`, `hands`) | level: 2; strength: 5 | strength: 1 | 18 | 2 / 10 / 1 | [image](../app/assets/images/items/strength_gloves.png) |
| `luck_gloves` — Luck Gloves (`equipment`, `hands`) | level: 2; luck: 5 | luck: 1 | 18 | 2 / 10 / 1 | [image](../app/assets/images/items/luck_gloves.png) |
| `spellcaster_gloves` — Spellcaster Gloves (`equipment`, `hands`) | level: 3; knowledge: 10 | mana: 10; knowledge: 1 | 40 | 4 / 10 / 1 | [image](../app/assets/images/items/spellcaster_gloves.png) |
| `quick_strike_gloves` — Quick Strike Gloves (`equipment`, `hands`) | level: 4; luck: 12 | crushing: 5; armor_class: 1; luck: 1; skill_bonuses: {"axe_mastery":5,"two_handed_mastery":5} | 50 | 4 / 20 / 1 | [image](../app/assets/images/items/quick_strike_gloves.png) |

#### Bracers

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `leather_bracers` — Leather Bracers (`equipment`, `bracers`) | level: 1; health: 5 | armor_class: 1; hp: 10 | 10 | 3 / 10 / 1 | [image](../app/assets/images/items/leather_bracers.png) |
| `congealed_blood_bracers` — Congealed Blood Bracers (`equipment`, `bracers`) | level: 3; luck: 10 | crushing: 5; accuracy: 5; armor_class: 2; luck: 1; skill_bonuses: {"two_handed_mastery":5} | 25 | 4 / 20 / 1 | [image](../app/assets/images/items/congealed_blood_bracers.png) |
| `development_bracers` — Development Bracers (`equipment`, `bracers`) | level: 3; dexterity: 10 | evasion: 5; accuracy: 5; armor_class: 1; dexterity: 1; skill_bonuses: {"knife_mastery":5} | 25 | 5 / 20 / 1 | [image](../app/assets/images/items/development_bracers.png) |
| `stability_bracers` — Stability Bracers (`equipment`, `bracers`) | level: 3; strength: 6; health: 7 | fortitude: 5; accuracy: 5; armor_class: 3; hp: 10; skill_bonuses: {"bludgeoning_mastery":5} | 25 | 5 / 20 / 1 | [image](../app/assets/images/items/stability_bracers.png) |
| `truth_bracers` — Truth Bracers (`equipment`, `bracers`) | level: 4; knowledge: 10 | accuracy: 5; armor_class: 1; mana: 10; knowledge: 1 | 45 | 6 / 30 / 1 | [image](../app/assets/images/items/truth_bracers.png) |

#### Jewelry

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `salvation_pendant` — Salvation Pendant (`equipment`, `amulet`) | level: 2; health: 5 | hp: 10 | 6 | 2 / 10 / 1 | [image](../app/assets/images/items/salvation_pendant.png) |
| `small_life_ring` — Small Life Ring (`equipment`, `ring`) | level: 2 | hp: 10 | 6 | 1 / 10 / 1 | [image](../app/assets/images/items/small_life_ring.png) |
| `small_protection_ring` — Small Protection Ring (`equipment`, `ring`) | level: 2; health: 7 | armor_class: 5 | 15 | 2 / 15 / 1 | [image](../app/assets/images/items/small_protection_ring.png) |
| `small_knowledge_ring` — Small Knowledge Ring (`equipment`, `ring`) | level: 2 | knowledge: 1 | 6 | 1 / 10 / 1 | [image](../app/assets/images/items/small_knowledge_ring.png) |
| `subtlety_ring` — Subtlety Ring (`equipment`, `ring`) | level: 3; dexterity: 9 | crushing: -5; evasion: 5; accuracy: 5 | 10 | 1 / 20 / 1 | [image](../app/assets/images/items/subtlety_ring.png) |

#### Attack scrolls and remaining Duel permits

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `duel_permit_i` — Duel Permit I (`consumable`, `none`) | level: 5; stealth: 20 | Targeted low-trauma fight | 16 | 1 / 1 / 10 | [image](../app/assets/images/items/duel_permit_i.png) |
| `duel_permit_ii` — Duel Permit II (`consumable`, `none`) | level: 5; stealth: 30 | — | 30 | 1 / 2 / 10 | [image](../app/assets/images/items/duel_permit_ii.png) |
| `duel_permit_iii` — Duel Permit III (`consumable`, `none`) | level: 5; stealth: 40 | — | 54 | 1 / 4 / 10 | [image](../app/assets/images/items/duel_permit_iii.png) |
| `duel_permit_iv` — Duel Permit IV (`consumable`, `none`) | level: 5; stealth: 60 | — | 84 | 1 / 7 / 10 | [image](../app/assets/images/items/duel_permit_iv.png) |
| `fist_attack` — Fist Attack (`consumable`, `none`) | level: 10; no skill gate | Both players unequipped; physical unarmed fight; personal use/delete only | 250 | 1 / 1 / 1 | [image](../app/assets/images/items/fist_attack.png) |

### Attack scroll use

[SCROLLS](SCROLLS.md) collects the catalog, forms, eligibility, formulas,
transactions, peace/license paths and editing procedure in one general guide.
[Scroll design](design/features/scrolls.md) owns the two enabled variants;
[live inventory/wiki evidence](design/reference/inventory/observations/2026-09-14_attack_scrolls.md)
distinguishes the observed 250 NV single-use Fist Attack from premium bundles.
[Inventory](features/player_inventory.md#september-14-attack-scrolls) owns the
Use form and [shared combat](features/arena_combat.md#september-14-scroll-entry)
owns resolution. Same-location includes outdoor cells and valid city/village
rooms; Inventory preserves that room. See [WORLD](WORLD.md) for context ownership.

Edit level/skill requirements, price, mass, durability and `personal_only` in
`starter_shop.json`; use the existing catalog updater and preserve owned
instances/stock. `AttackScroll::RULES` explicitly enables stable item keys and
selects entry trauma/equipment rules; an arbitrary description or effect cannot
start PvP. `LEVEL_DIFFERENCE` controls the inclusive target window. The
[formula entry](FORMULAS.md#scroll-01--attack-entry) explains effects and boundaries.
`InventoryItem#tradable?` enforces personal use in both UI and transfer/Shop
settlement, while Delete remains allowed. Opening/cancelling Use spends nothing;
one successful action key spends one charge and repeated submission returns
its original match. Rejections leave the item unchanged.

The existing Duel Permit I art is reused. Fist Attack has a new original
384 × 384 PNG under the [artwork production record](ARTWORK.md#september-14-attack-scroll-artwork).
Other permit tiers remain catalog-only. Both live 17-to-5 attempts returned
the same generic failure without consumption; the local level-window error
now uses its translated wording. Successful source entry, precise rejection
causes and post-fight equipment persistence still await a suitable target.

### Supplemental inventory definitions

These ten definitions come from `shop_inventory.rb`, not the 80-row Shop
assortment. Some exist for preserved inventory/fixture behavior without an
ordinary current acquisition route. “No mapped image” means the runtime
inventory helper supplies its existing text/type fallback; it does not license
copying a Neverlands bitmap.

| Key / name (type, slot) | Requirements | Effects | Base NV | Weight / max durability / stack | Art |
|---|---|---|---:|---|---|
| `knowledge_ring` — Knowledge Ring (`equipment`, `ring`) | level: 5 | knowledge: 3 | 18 | 1 / 30 / 1 | No mapped image |
| `dexterity_ring` — Dexterity Ring (`equipment`, `ring`) | level: 5; health: 7 | dexterity: 3 | 18 | 1 / 30 / 1 | No mapped image |
| `soul_hunter_pendant` — Soul Hunter Pendant (`equipment`, `amulet`) | level: 5; knowledge: 15 | hp: 5; mana: 20; strength: -1; knowledge: 1 | 30 | 2 / 30 / 1 | No mapped image |
| `student_boots` — Apprentice Boots (`equipment`, `feet`) | level: 5; luck: 12; knowledge: 13 | crushing: 10; fortitude: 10; armor_class: 3; mana: 20; luck: 2; knowledge: 2; skill_bonuses: {"staff_mastery":5}; all_resistances: 8 | 200 | 8 / 20 / 1 | No mapped image |
| `cowardly_gloves` — Cowardly Gloves (`equipment`, `hands`) | level: 5; dexterity: 16 | evasion: 10; armor_class: 1; strength: -1; dexterity: 2; knife_skill: 5 | 75 | 6 / 30 / 1 | No mapped image |
| `north_wind_bracers` — North Wind Bracers (`equipment`, `bracers`) | level: 5; knowledge: 17 | accuracy: 10; armor_class: 2; hp: 10; mana: 10; knowledge: 1 | 60 | 8 / 40 / 1 | No mapped image |
| `damage_armor` — Damage Armor (`equipment`, `chest`) | level: 4; luck: 15; health: 7 | crushing: 20; armor_class: 6; hp: 7; luck: 1 | 60 | 11 / 45 / 1 | No mapped image |
| `starwatcher_cap` — Starwatcher Cap (`equipment`, `head`) | level: 5; knowledge: 10 | armor_class: 1; hp: 10; mana: 30; knowledge: 3; fire_resistance: 5; water_resistance: 5; air_resistance: 5; earth_resistance: 5 | 90 | 2 / 40 / 1 | No mapped image |
| `reset_scroll` — Reset Scroll (`consumable`, `none`) | level: 5; health: 10 | reset_allocation: true | 1000 | 1 / 1 / 1 | No mapped image |
| `imp_helper_summon` — Imp Helper Summon (`consumable`, `none`) | level: 8; linguistics: 60 | production_speed_percent: 10 | 1000 | 1 / 1 / 1 | No mapped image |

### Licenses

All are `misc`, slot `none`, weight 1, maximum durability 1 and stack limit 1.
They use the Shop's **Licenses**
mode and the original corresponding image. The prices/durations below are
authored values; permission rules are in
[LicenseRules](../app/services/game/shop/license_rules.rb).

| Key / name | Base NV | Duration | Prerequisite / artwork |
|---|---:|---|---|
| `trading_license_i` — Trading License I | 300 | 3 days | Merchant + qualification; [image](../app/assets/images/items/trading_license_i.png) |
| `trading_license_ii` — Trading License II | 800 | 10 days | Merchant + qualification; [image](../app/assets/images/items/trading_license_ii.png) |
| `trading_license_iii` — Trading License III | 2000 | 30 days | Merchant + qualification; [image](../app/assets/images/items/trading_license_iii.png) |
| `doctor_license_i` — Doctor License I | 300 | 5 days | Healer; [image](../app/assets/images/items/doctor_license_i.png) |
| `doctor_license_ii` — Doctor License II | 550 | 10 days | Healer + Traumatologist unlock; [image](../app/assets/images/items/doctor_license_ii.png) |
| `doctor_license_iii` — Doctor License III | 800 | 15 days | Healer + Traumatologist unlock; [image](../app/assets/images/items/doctor_license_iii.png) |

An active duplicate is rejected. Tier changes duration, not the injury severity
the doctor may treat. A bought license appears under Character abilities;
putting a similarly named object into Inventory grants no permission. General
Traumatologist quest completion remains outside the current implementation.

### Medicine and materials

| Stable key / name | Definition and source | Artwork |
|---|---|---|
| `beginner_healer_bag` — Beginner healer bag | Hospital, 300 NV, 10 uses, light injury; Knowledge 20 / authored Doctor 100 | [Shared healer bag](../app/assets/images/items/healer_bag.png) |
| `skilled_healer_bag` — Skilled healer bag | Hospital, 750 NV, 10 uses, medium injury; Knowledge 45 / authored Doctor 300 | [Shared healer bag](../app/assets/images/items/healer_bag.png) |
| `experienced_healer_bag` — Experienced healer bag | Hospital, 1500 NV, 10 uses, heavy injury; Knowledge 90 / authored Doctor 400 | [Shared healer bag](../app/assets/images/items/healer_bag.png) |
| `combat_first_aid_kit` — Combat first-aid kit | Hospital, 7000 NV, 1 use, combat injury; Knowledge 160 / authored Doctor 600 | [Shared healer bag](../app/assets/images/items/healer_bag.png) |
| `minor_health_potion` — Small health elixir | NPC calibrated loot; consumable, stack 10, weight 1, flat `heal_hp: 50`; no seeded normal Shop sale | [Elixir](../app/assets/images/items/minor_health_potion.png) |
| `rat_tail` — Rat Tail | Plague Rat loot; material, weight 1; no current turn-in/crafting consumer | No mapped inventory image |
| `wood_chips` — Wood Chips | Training Dummy loot; material, weight 1; no current crafting consumer | No mapped inventory image |

The four medical tools are `misc`, slot `none`, with weight 1, stack 1 and
`heals_injury` matching their
severity. They are used through Medical care rather than ordinary potion use.
`RequirementChecker` enforces effective Doctor proficiency as well as Knowledge;
Medical Care also checks the license and perk. Doctor is the saved profession
counter plus usable equipment bonuses, separate from allocatable Skills.
See [Medical Care](features/medical_care.md) for atomic request/acceptance checks.
Treatment fee limits and recovery calculations remain in
[FORMULAS](FORMULAS.md#7-recovery-wear-and-injuries).

## 3. Fields, slots and effective properties

| Field | How to edit / what it affects |
|---|---|
| `key`, `name` | Preserve a used stable key; the name is display text. Audit loot, art, stock and fixture references before changing identity |
| `item_type` | Use the supported equipment/material/consumable/misc types; controls behavior/fallback presentation |
| `slot` | Use a supported slot or alias for equipment; `none` for non-equipment. Category labels do not determine equip eligibility |
| `weight`, `stack_limit` | Positive values; determine capacity and stack allocation. Owned rows store their own unit weight/quantity |
| `base_price` | Nonnegative decimal NV; affects new Shop quotes and resale. A positive price does not add local stock |
| `durability_max` | Nonnegative template maximum; existing owned overrides can retain their old maximum |
| `requirements` | Supported level, AP, primary stats, registered skills and aliases; checked at equip/use. Unknown keys currently have no enforcement |
| `stat_modifiers` | Explicit effective numeric bonuses, weapon identity, damage range and recognized consumable effects |
| `enhancement_rules` | Inventory family/subcategory, display properties/source name, two-handed flag, typed license and Shop eligibility/baseline stock |
| Owned `properties` | Requirements/effect overrides, current/max durability, expiry and protection; alter one owned instance rather than its whole template |

Equipment uses **20 stable slots**, with sizes owned by
[EquipmentSlots](../app/models/equipment_slots.rb). The left rail is head,
amulet, main hand, legs and feet; the right includes pocket/pocket content,
bracers, hands, off hand, chest, belt and relic; the center has four rings and
three belt-content slots. `ring` selects an available ring slot, `weapon`
maps to main hand, `shield` to off hand; the full alias map is in ItemTemplate.
Two-handed items occupy the main-hand role and conflict with the off hand;
the [EquipmentService](../app/services/game/inventory/equipment_service.rb)
owns replacement/conflict handling.

Owned effect precedence is template `stat_modifiers`, then owned
`properties.stat_modifiers`, then owned `properties.effects`. Matching keys
override; separate bonuses from equipped items add through Character. Broken
items stop contributing. Item requirements similarly merge template and owned
overrides. See [FORMULAS](FORMULAS.md#3-character-stats-and-equipment) for
effective stats, weapon mastery, damage, AP and capacity rather than copying
those equations into a content row.

`weapon_family` must match the implemented family keys. Explicit shield
`block_table` values select captured block options; a shield name does not.
Displayed text such as “can be worn over chainmail” does not add a second
chest slot. The supported data reader must consume a property before the
property becomes gameplay.

## 4. Acquisition and item lifecycle

[Economy design](design/features/economy_trading_shops.md) owns Shop and
license acquisition rules; [item design](design/features/items_inventory_equipment.md)
owns carried/equipped behavior. Their handbooks above record current delivery.

| Entry/action | Current ownership and outcome |
|---|---|
| Shop/Hospital purchase | A valid current offer exchanges one unit of stock for NV; Inventory receives goods, CharacterLicense receives typed permission |
| NPC drop | Combat rolls the typed table and uses Inventory Manager or the NV wallet; a successful item/NV event follows committed ownership |
| Development fixture grant | Explicit seed fixture behavior, not automatic new-player entitlement or evidence of a source starting kit |
| Equip / unequip | Rechecks owned item, supported slot, requirements and state; updates the existing paper doll/effective inputs |
| Named equipment set | Saves owned item IDs per slot, then validates and wears that owned set; it is not a grant or a species loadout |
| Consume | Recognized flat heal/MP restore or legacy reset branch; successful use spends one unit/use |
| Medical treatment | Valid matching bag, same-cell treatment prerequisites and accepted/free fee; heals one injury and spends one bag use |
| Discard / transfer / gift | Checks ownership and protections, changes quantity/weight; worn/bound/protected items are restricted |
| Shop sale | Active trading license and eligible stock/owned item; one unit sold at current durability-adjusted resale price |
| Player paid sale | Disabled pending buyer acceptance; the presence of a sale form or trading license is insufficient |

NPC worn gear is separate from this lifecycle. Killing an Ogre does not grant
its illustrated club unless a real ItemTemplate loot entry says so. The
current calibrated NPC equipment drop is Penknife below NPC level 13 or
Assassin Dagger at/above 13; potion/currency rolls and eligibility live in
[NPC](NPC.md#6-loot-and-experience) and FORMULAS.

Instance expiry/breakage affects usability. Sale/discard protection and source
requirements remain separate. No general repair, enhancement, crafting,
production-speed or item-level scaling workflow becomes active merely by
adding corresponding JSON or showing a category tab.

## 5. Artwork and presentation

[InventoriesHelper::ITEM_ARTWORK_PATHS](../app/helpers/inventories_helper.rb)
maps stable item keys to project-owned asset paths. The helper reads this map;
an arbitrary `enhancement_rules.image` alone does not install new inventory
art. NPC decorative equipment has a separate allowlist described in NPC.md.

Read [ARTWORK](ARTWORK.md) before generating or editing. Preserve its category
framing, native dimensions, backgrounds, padding and equipment aspect ratios;
slot dimensions are presentation, not game rules. Record exact prompts and
packaging there. Reuse images only when appropriate: the four healer tools
currently share the bag image while keeping distinct effects/requirements.
The item catalog explicitly marks unmapped art rather than promising a finished
illustration for every retained definition.

For integration, add a justified allowlisted mapping, inspect the image at its
actual Inventory/Shop/paper-doll size, and verify clipped edges and responsive
controls through the local UI after automated checks. This documentation task
references existing art; it generates or replaces no assets.

## 6. Editing recipes

### Change an existing item

1. Find the stable key in this catalog and its baseline file. Read the source
   observation linked by its domain/ARTWORK record and the current item data.
2. Decide whether the change is template-wide, one owned instance or one
   merchant's stock. Those require different records/owners.
3. Change the existing declaration and its supported reader if behavior changes.
   Recheck equipment, mastery/AP, capacity, loot, sale quotes, license eligibility
   and artwork references that depend on the changed field.
4. Plan any required database sync explicitly. The current `/manage` surface
   does **not** implement ItemTemplate CRUD or arbitrary item/player grants;
   the [content guide](guides/managing_game_content.md#12-worked-future-example-armor-axes-and-other-item-definitions)
   distinguishes its future example from shipped controls.
5. Update this book and the relevant formula/NPC/artwork/handbook owner; verify
   new and already-owned instances, not only a fresh template.

### Add a source-backed item

Use an existing supported category and identity. The Penknife row illustrates
the actual content shape: `key: penknife`, `item_type: equipment`,
`slot: main_hand`, requirements `{level: 1, ap: 40}`, and modifiers
`{weapon_family: knife, damage_min: 1, damage_max: 2, armor_pierce: 1}`.
Changing the example's name/key is not enough to justify a new weapon's stats.
Author the observed/calibrated requirements and modifiers, then deliberately
choose its acquisition path. For Shop goods this means eligibility plus a
location's stock; for loot it means an existing NPC's typed item-key entry.
For a new effect, implement the specific consuming owner; unrecognized JSON
currently cannot promise that effect.

### Understand seed and live-change consequences

Shop content seeding updates templates, while preserving owned durability
overrides when correcting a template maximum. Shop account seeds create missing
stock/funds but do not refill traded stock or reset merchant balances. Supplemental
development grants are separately gated; `SHOP_CATALOG_ONLY=1` suppresses that
grant block, not every side effect of a full database seed. Medical seeds update
bag definitions; the elixir/material creation paths preserve existing rows.

Do not run the full seed to edit one price or give one item. A template update
can affect existing effective modifiers and future resale quotes, while owned
weight/durability overrides and saved equipment-set item IDs remain separate.
An in-flight quote is revalidated against current authoritative trade state.
Retiring an item needs an explicit stock/acquisition policy and treatment of
already-owned items/history; deleting its template is not a safe substitute.

## 7. Current limitations

- **Doctor progression:** bag proficiency is enforced; automatic use-growth,
  crafting and complete Doctor qualification quests remain separate work.
- **Reset Scroll:** current reset refunds stat allocations but only one point
  per positive skill, and does not clear/refund perks despite its text. See
  the compatibility section in FORMULAS; do not describe it as a complete reset.
- **Imp Helper Summon:** `production_speed_percent` is retained content without
  a production/summon consumer. General use returns no usable effect.
- **Duel Permit II–IV:** catalogued but no activation handler. Duel Permit I
  and Fist Attack use the explicit targeted adapter above; they do not rely
  on generic consumable effects. Fist intervention into an existing fight is
  rejected without consumption pending source evidence.
- Empty resource/crafting families, workshop repair, Mine merchandise and
  market stall rows remain bounded/absent features under their own handbooks.

These are current implementation/evidence boundaries, not permission to replace
them with generic RPG behavior. This book is a documentation delivery; it does
not silently repair gameplay while cataloging it.

## Use cases and cross-feature effects

These examples apply current rules; [the catalog](#2-current-item-catalog)
and [FORMULAS](FORMULAS.md) own exact properties and equations.

| Preconditions / use case | Action and authoritative result | Related effects and boundaries |
|---|---|---|
| Owned usable item grants Knife Mastery+10; learned skill 100 | Equip →effective 110 | [SKILLS](SKILLS.md) uses learned 100 for allocation, effective 110 for the matching physical consumer. The bonus does not create 10 spendable points |
| Replace shield with a second usable weapon | Equipment service validates ownership, slots and requirements | Shared [COMBAT](COMBAT.md#4-levels-skills-equipment-and-combat-inputs) derives weapon-family mastery/AP and block options; an image or item name cannot confer shield blocking |
| Level 17 owns More Strength, no injury | Perk contributes 8 Strength before equipment/injury composition | [PERKS](PERKS.md) can change recognized requirements and capacity. Inventory still revalidates item ownership, weight and availability |
| One-point Permit I item in Inventory | Valid targeted use consumes a charge and starts/joins combat | [SCROLLS](SCROLLS.md) owns target/range/skill/replay validation. Failed admission leaves the charge intact |
| Healer has an active license and matching bag | Treatment enters the medical transaction | Bag uses and injury changes belong to [Medical Care](features/medical_care.md); effective Doctor thresholds recheck at request and paid acceptance |
| Careful Fighter owned at fight finalization | Applicable wear probability is halved per item | Changes future durability risk, not the item's damage or required repair amount; broken gear stops contributing through Character |
| Edit only weapon artwork | Presentation changes after integration | Stats, loot, walking duration and availability do not change; [ARTWORK](ARTWORK.md) owns dimensions/prompts, item data owns gameplay |

## 8. Verification and maintenance

For changes use the relevant existing tests: [ItemTemplate](../spec/models/item_template_spec.rb),
[InventoryItem](../spec/models/inventory_item_spec.rb),
[Shop seed](../spec/models/shop_inventory_seed_spec.rb),
[item artwork](../spec/assets/item_artwork_assets_spec.rb), inventory/equipment
service/request coverage, Shop trades and Medical care. Runtime changes follow
[AGENTS](../AGENTS.md), including final local UI acceptance for visible flows.

**Update this book in the same task** when definitions, supported effects,
requirements, sources, slots, lifecycle, asset mappings or editing procedures
change. Keep stable keys in every catalog row. Reconcile catalog counts/tables
against the source declarations; label retained/unavailable content honestly.
Detailed equations stay in FORMULAS, NPC pools in NPC, location stock ownership
in WORLD/Shop, and exact art prompts in ARTWORK. The shared maintenance rule is
in [DOCUMENTATION](DOCUMENTATION.md#410-game-reference-books).

## Arena equipment admission

The [ARENA guide](ARENA.md#3-applications-and-admission-rules) explains how
these item restrictions combine with hall/side gates and application reservation.

[EquipmentRule](../app/services/arena/equipment_rule.rb) reads all equipped items and authoritative character/item `artifact_grade`. Unarmed means no equipment, including clothing; no-artifacts requires `none`; limited-artifacts permits calibrated multiplier≤1.1. Unknown grades reject restricted entry. Item effective modifiers override template data through the existing merge; no price/name/rarity heuristic determines grade. The [formula book](FORMULAS.md#arena-01--admission-and-deadlines) owns the editable threshold; [Arena](design/areas/arena.md) rechecks it on creation, joining and group start. Waiting membership locks equipment navigation/mutations until withdrawal or completion.
