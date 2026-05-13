# Source Material Map

This file records how the existing and removed docs were folded into the new
design hierarchy.

## Live Reference Material

| Source | New Location |
| --- | --- |
| `doc/flow/neverlands_live_movement.md` | `features/movement.md`, `areas/world_map.md`, `reference/neverlands.md` |
| `doc/flow/neverlands_live_city_movement.md` | `areas/cities_and_buildings.md`, `features/economy_trading_shops.md` |
| `doc/design/reference/neverlands_arena_combat.md` | `areas/arena.md`, `features/combat.md`, `reference/neverlands.md` |
| `doc/features/neverlands_inspired_chat.md` | `features/social_chat_presence.md` |
| `doc/features/neverlands_inspired_combat.md` | `features/combat.md`, `areas/arena.md` |
| `doc/features/neverlands_inspired_skills.md` | `features/progression_stats_skills.md`, `features/character_vitals.md` |
| Neverlands wiki dungeon page | `features/dungeons.md`, `reference/neverlands.md` |
| Neverlands forum dungeon launch post | `features/dungeons.md`, `reference/neverlands.md` |

## Current Implementation Notes Used As Input

| Source | New Design File |
| --- | --- |
| `doc/flow/15_neverlands_map_ui.md` | `areas/world_map.md`, `features/movement.md` |
| `doc/flow/13_game_layout.md` | `areas/game_client_layout.md`, `features/social_chat_presence.md` |
| `doc/flow/20_city_hotspots.md` | `areas/cities_and_buildings.md` |
| `doc/flow/24_unified_turn_combat.md` | `features/combat.md` |
| `doc/flow/16_passive_skills.md` | `features/progression_stats_skills.md` |
| `doc/flow/18_inventory_system.md` | `features/items_inventory_equipment.md` |
| `doc/flow/14_tile_resource_gathering.md` | `features/gathering_professions.md` |
| `doc/flow/4_world_npc_systems.md` | `features/npcs_quests.md` |
| `doc/flow/11_arena_pvp.md` | `areas/arena.md` |

## Deleted Broad Docs Distilled

| Deleted Source | Kept Design Content | Not Carried Forward |
| --- | --- | --- |
| `doc/features/3_player.md` | movement, combat, progression, inventory | framework class names |
| `doc/features/4_npc.md` | world structure, NPC roles, quests | moderation/admin tooling details |
| `doc/features/6_crafting_professions.md` | gathering/profession loops | housing-dependent assumptions |
| `doc/features/8_gameplay_mechanics.md` | core mechanics split into feature docs | dungeon and analytics extras |
| `doc/features/9_economy.md` | currency, shops, direct trade, marketplace | premium-store expansion details |
| `doc/features/10_quests_story.md` | quest chains, repeatables, rewards | live-ops tooling |
| `doc/features/11_social_features.md` | chat, presence, parties, arena social surface | webhook/community integrations |
| `doc/features/12_clan_system.md` | clans as later social extension | territory-control complexity for now |
| `doc/features/13_additional_features.md` | none for core GDD | housing, pets, achievements, analytics |
| `doc/analyze.md` | high-level loop and design principles | app architecture sections |
| `doc/TODO.md` | inventory/economy/quest reminders | implementation checklist format |

## Rule For Removed Ideas

Removed docs can inspire new design only when they support the Neverlands-style
core loop. Otherwise they stay out of the canonical GDD until a concrete feature
needs them.
