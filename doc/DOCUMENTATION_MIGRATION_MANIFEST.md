# Documentation Architecture Migration Manifest

- Baseline: 43 Markdown documents present under `doc/` before the 2026-07-29
  architecture migration
- Status: Current and fully accounted for
- Updated: 2026-07-29

This manifest proves that the migration did not silently drop an existing
document. It records the canonical owner or compatibility disposition for each
baseline path. New domain indexes, templates, evidence-gap records, and
`NOT_IMPLEMENTED` handbooks are additions and therefore are listed separately.

## Baseline inventory and disposition

### Repository documentation and guidance: 4

| Baseline path | Disposition |
|---|---|
| `doc/DOCUMENTATION.md` | Updated in place as the canonical architecture contract. |
| `doc/README.md` | Updated in place as the concise documentation portal. |
| `doc/RUBY_ON_RAILS_GUIDE.md` | Retained as the Rails/Hotwire engineering guide and aligned with the architecture. |
| `doc/UI.md` | Retained as a compatibility/historical UI entry; canonical routing points to Shell design, evidence, and implementation. |

### Design governance: 3

| Baseline path | Disposition |
|---|---|
| `doc/design/README.md` | Updated in place as design-layer policy and routing. |
| `doc/design/gdd.md` | Retained as consolidated product design. |
| `doc/design/launch_mvp_plan.md` | Retained as delivery/parity owner and given stable domain-flow identifiers. |

### Area design: 4

| Baseline path | Disposition |
|---|---|
| `doc/design/areas/arena.md` | Retained; indexed by `doc/domains/combat.md`. |
| `doc/design/areas/cities_and_buildings.md` | Retained; indexed by `doc/domains/city.md`. |
| `doc/design/areas/game_client_layout.md` | Retained; indexed by `doc/domains/shell.md`. |
| `doc/design/areas/world_map.md` | Retained; indexed by `doc/domains/world.md`. |

### Mechanic design: 10

| Baseline path | Disposition |
|---|---|
| `doc/design/features/character_vitals.md` | Retained; indexed by Character and Shell. |
| `doc/design/features/combat.md` | Retained; indexed by Combat. |
| `doc/design/features/dungeons.md` | Retained; indexed by Dungeons and paired with an evidence gap and `NOT_IMPLEMENTED` handbook. |
| `doc/design/features/economy_trading_shops.md` | Retained; indexed by Economy. |
| `doc/design/features/items_inventory_equipment.md` | Retained; indexed by Inventory. |
| `doc/design/features/movement.md` | Retained; indexed by World. |
| `doc/design/features/npcs_quests.md` | Retained; indexed by NPCs and Quests. |
| `doc/design/features/professions.md` | Retained; indexed by Professions and paired with an evidence gap and `NOT_IMPLEMENTED` handbook. |
| `doc/design/features/progression_stats_skills.md` | Retained; indexed by Character. |
| `doc/design/features/social_chat_presence.md` | Retained; indexed by Social and Shell. |

### Neverlands reference and observations: 12

| Baseline path | Canonical disposition |
|---|---|
| `doc/design/reference/neverlands.md` | Retained as a compatibility/source overview; domain summaries under `doc/design/reference/` are canonical. |
| `doc/design/reference/neverlands_chat.md` | Compatibility alias to `doc/design/reference/social/observations/legacy_chat_system_analysis.md`. |
| `doc/design/reference/neverlands_live_city_movement.md` | Compatibility alias to `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`. |
| `doc/design/reference/neverlands_live_game_shell_ui.md` | Compatibility alias to `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`. |
| `doc/design/reference/neverlands_live_inventory_items.md` | Compatibility alias to `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`. |
| `doc/design/reference/neverlands_live_lavka_shop.md` | Compatibility alias to `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`. |
| `doc/design/reference/neverlands_live_movement.md` | Compatibility alias to `doc/design/reference/world/observations/2026-05-09_overworld_movement.md`. |
| `doc/design/reference/neverlands_live_outdoor_npc_resource.md` | Compatibility alias to `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`. |
| `doc/design/reference/neverlands_live_player.md` | Compatibility alias to `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md`. |
| `doc/design/reference/neverlands_live_style_system.md` | Compatibility alias to `doc/design/reference/shell/observations/2026-07-29_style_system.md`. |
| `doc/design/reference/neverlands_skills.md` | Compatibility alias to `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`. |
| `doc/design/reference/source_material.md` | Retained as a compatibility/source-material overview; domain summaries are canonical for new observations. |

### Implementation handbooks and feature policy: 9

| Baseline path | Disposition |
|---|---|
| `doc/features/FEATURE_TEMPLATE.md` | Retained as the shipped-feature template. |
| `doc/features/README.md` | Updated in place as implementation-handbook policy. |
| `doc/features/arena_combat.md` | Retained; indexed by Combat. |
| `doc/features/character_progression.md` | Retained; indexed by Character. |
| `doc/features/city.md` | Retained; indexed by City. |
| `doc/features/game_shell.md` | Retained; indexed by Shell and Social. |
| `doc/features/player_inventory.md` | Retained; indexed by Inventory. |
| `doc/features/shop_economy.md` | Retained; indexed by Economy. |
| `doc/features/world.md` | Retained; indexed by World and NPCs. |

### Operational guides: 1

| Baseline path | Disposition |
|---|---|
| `doc/guides/managing_game_content.md` | Retained as the operator/developer guide for persisted game content and linked from World and City. |

Baseline accounting: **43 of 43 documents have an explicit disposition**.

## Additions made by the migration

- `doc/domains/README.md` and eleven domain indexes.
- `doc/design/reference/README.md` and eleven domain source summaries.
- Domain-scoped observation directories and compatibility aliases for moved
  flat observations.
- Evidence-gap records for Quests, Professions, and Dungeons.
- `doc/features/quests.md`, `doc/features/professions.md`, and
  `doc/features/dungeons.md` with exact `NOT_IMPLEMENTED` status.
- `doc/features/NOT_IMPLEMENTED_TEMPLATE.md`.
- `doc/templates/README.md` plus source-summary, observation, domain-index,
  and design-placeholder templates.
- A read-only documentation architecture audit integrated with `bin/verify`.

## Migration compatibility rule

Compatibility aliases may remain while historical links exist. New or
materially updated active documents must link to canonical domain-scoped paths.
Aliases contain no independent evidence or implementation claim and must not
become a second truth owner.
