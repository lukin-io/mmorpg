# Source Material Map

This file records the remaining Neverlands-based source material and where its
rules belong in the design hierarchy. Non-Neverlands source docs are legacy and
should be removed after any valid rule is promoted into `doc/design/`.

## Live Reference Material

| Source Area | Design Location |
| --- | --- |
| Wilderness movement capture | `features/movement.md`, `areas/world_map.md`, `reference/neverlands.md` |
| City movement capture | `areas/cities_and_buildings.md`, `features/economy_trading_shops.md` |
| Game shell/UI capture | `areas/game_client_layout.md`, `areas/cities_and_buildings.md`, `areas/arena.md`, `features/social_chat_presence.md`, `features/economy_trading_shops.md` |
| Chat and presence reference | `features/social_chat_presence.md`, `areas/game_client_layout.md` |
| Skill and perk reference | `features/progression_stats_skills.md`, `features/character_vitals.md` |
| Player profile capture | `features/progression_stats_skills.md`, `features/items_inventory_equipment.md`, `features/character_vitals.md` |
| Arena mannequin combat captures | `areas/arena.md`, `features/combat.md`, `features/items_inventory_equipment.md`, `features/npcs_quests.md` |
| Public fight log captures | `features/combat.md`, `areas/arena.md`, `reference/neverlands.md` |
| Outdoor NPC/resource capture | `areas/world_map.md`, `features/npcs_quests.md`, `features/combat.md` |
| Neverlands wiki world overview and geography | `areas/world_map.md`, `areas/cities_and_buildings.md` |
| Neverlands wiki profession-inventory tables | future resource/profession effects after successful live action capture |
| Neverlands wiki dungeon page | `features/dungeons.md`, `reference/neverlands.md` |
| Neverlands forum dungeon launch post | `features/dungeons.md`, `reference/neverlands.md` |

Current wiki references:

- [Neverlands Wiki main page](http://wiki.neverlands.ru/wiki/%D0%97%D0%B0%D0%B3%D0%BB%D0%B0%D0%B2%D0%BD%D0%B0%D1%8F_%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%86%D0%B0) is the general discovery entry point for historical source material.
- `http://wiki.neverlands.ru/wiki/Neverlands` confirms world geography includes
  cities, villages, castles, forts, unusual locations, and several transport
  forms.
- `http://wiki.neverlands.ru/wiki/Таблица_чертежей_проф.инвентаря` confirms
  fishing and herbalism use profession equipment and skill requirements. It
  does not define the live cell-action result protocol, so those outcome rules
  still require authenticated capture.

## Rule For Removed Ideas

Removed docs do not inspire new design. Add new design only from
Neverlands-based source material or from implementation facts that preserve the
Neverlands-style core loop.
