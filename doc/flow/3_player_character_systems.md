# 3. Player & Character Systems Flow

## Overview
- Implements `doc/features/3_player.md`: movement/exploration, combat, progression, class kits, inventory, and profession-driven recovery.
- Server-authoritative turn processing lives in `Game::Movement`/`Game::Combat`; ActiveRecord models keep persistence + visibility for moderation.

## Movement & Exploration
- `Zone`, `SpawnPoint`, and `CharacterPosition` store deterministic location data; `Game::Movement::TurnProcessor` enforces one action per server tick and now factors in active mount travel multipliers.
- `config/gameplay/biomes.yml` + `Game::Exploration::EncounterResolver` control biome-aware encounters layered onto `MapTileTemplate` tiles.
- Respawns use `Game::Movement::RespawnService` with faction-aware spawn points and downtime windows.

## Combat Flow
- `Battle` + `BattleParticipant` persist PvE/PvP participants, initiative, and spectator flags (with share tokens/exportable logs).
- `Game::Combat::EncounterBuilder` provisions duels, skirmishes, and arena matches; `TurnResolver` writes enriched `CombatLogEntry` analytics rows for moderators/spectators.
- `Game::Combat::ArenaLadder` + `PostBattleProcessor` update ladder ratings, doctor recovery, respawn scheduling, and enqueue `Combat::AggregateStatsJob` → `Game::Combat::Analytics::ReportBuilder`.

## Progression & Stats
- `Players::Progression::LevelUpService` awards XP, stat, and skill points using quadratic thresholds.
- `Players::Progression::StatAllocationService` writes to `characters.allocated_stats` while preserving available pools.
- `Players::Alignment::AccessGate` gates quests, gear, and services using reputation/alignment requirements.

### Combat Action Points
- `Character#max_action_points` calculates AP budget per combat turn
- **Formula:** `50 (base) + (Level × 3) + (Agility × 2)`
- Higher level = more actions per turn; agility builds gain additional AP
- `Battle.action_points_per_turn` stores character's AP at battle creation

## Alignment & Faction System
- **Faction Alignments:** Characters choose `neutral`, `alliance`, or `rebellion` base factions with emoji icons (🛡️⚔️🏳️).
- **Alignment Tiers:** `alignment_score` (-1000 to +1000) determines 9 progression tiers from Absolute Darkness (🖤) to Celestial (👼).
- **Chaos Tiers:** `chaos_score` (0 to 1000) determines 4 tiers from Lawful (⚖️) to Absolute Chaos (💥).
- **Character methods:** `alignment_tier`, `alignment_emoji`, `faction_emoji`, `alignment_display`, `adjust_alignment!`, `adjust_chaos!`.
- **Helpers:** `AlignmentHelper` provides `alignment_badge`, `character_nameplate`, `faction_icon`, `trauma_badge`, `timeout_badge` for UI display.

## Classes & Abilities
- `CharacterClass` defines resource pools, allowed equipment, and combo metadata.
- `ClassSpecialization`, `SkillTree`, `SkillNode`, and `CharacterSkill` capture advanced unlocks + audit trails.
- `Ability` definitions feed `Game::Combat::SkillExecutor`, which enforces resource costs before handing execution to `TurnResolver`.

## Items & Inventory

### Version History
- **v1.0** (2025-12-15): Initial inventory implementation with full equipment system, enhancement, and Hotwire UI.

### Overview
The inventory system manages character item storage, equipment slots, item stacking, weight limits, and item enhancements. It follows the Hotwire-first principle with Turbo Streams for real-time updates and Stimulus controllers for client-side interactions.

### Core Models
- **`Inventory`**: Belongs to a character, enforces `slot_capacity` and `weight_capacity` limits. Provides `max_slots` and `max_weight` aliases for UI compatibility, plus `material_count`, `materials_available?`, `consume_materials!`, and `add_item_by_name!` helpers.
- **`InventoryItem`**: Tracks individual item stacks with `quantity`, `weight`, `equipped`, `enhancement_level`, `premium`, `equipment_slot`, and `slot_index`. The `equipment_slot` column stores which slot an equipped item occupies.
- **`ItemTemplate`**: Defines base attributes for all game items including `name`, `item_type` (equipment/material/consumable), `slot`, `rarity`, `stat_modifiers` (JSON), `weight`, `stack_limit`, `premium`, and `enhancement_rules`. Provides `equippable?` and `equipment_slot` methods for equipment validation.

### Equipment Slots
The system supports 10 equipment slots defined in `ItemTemplate::EQUIPMENT_SLOTS`:
- Head, Chest, Legs, Feet, Hands (armor)
- Main Hand, Off Hand (weapons)
- Ring 1, Ring 2 (accessories)
- Amulet (accessory)

### Item Rarities
Items have rarity tiers: `common`, `uncommon`, `rare`, `epic`, `legendary`. Rarity affects enhancement max levels and costs.

### Game Engine Services
- **`Game::Inventory::Manager`**: Enforces slot/weight limits and handles item stacking. Provides `add_item!`, `remove_item!`, and `sort_inventory!` methods.
- **`Game::Inventory::EquipmentService`**: Handles equipping and unequipping items with proper validation and equipment slot management.
- **`Game::Inventory::EnhancementService`**: Manages item enhancement/upgrades with gold costs, material consumption, and success rate calculations based on rarity and luck stats.
- **`Game::Inventory::ExpansionService`**: Handles inventory capacity upgrades (slot and weight expansions).

### Hotwire Integration
- **Turbo Frames**: `inventory_grid`, `equipment_panel`, `stats_panel` for partial updates.
- **Turbo Streams**: Real-time updates on equip/unequip/use/discard actions via `turbo_stream.replace`.
- **Stimulus Controller**: `inventory_controller.js` handles item selection, context menus, and action dispatching (equip, use, enhance, split, discard).

### Controllers
- **`InventoriesController`**: Main controller for `show`, `equip`, `unequip`, `use`, `destroy`, and `sort` actions.
- **`InventoryItemsController`**: Handles individual item actions like `destroy` (discard).

### Stats Integration
`Characters::VitalsService#stats_summary` provides a comprehensive hash of character stats including:
- Current/max HP and MP
- Base stats (strength, dexterity, intelligence, vitality, spirit)
- Derived combat stats (attack_power, defense, crit_rate) with equipment bonuses calculated from equipped items' `stat_modifiers`.

## Crafting & Professions
- Gathering nodes connect professions to zones; `Professions::GatheringResolver` awards resources with seeded RNG.
- The Doctor profession shortens trauma timers post-battle via `Professions::Doctor::TraumaResponse`.

## Responsible for Implementation Files

### Models
  - `app/models/zone.rb`, `app/models/spawn_point.rb`, `app/models/character_position.rb`, `app/models/gathering_node.rb`
  - `app/models/battle.rb`, `app/models/battle_participant.rb`, `app/models/combat_log_entry.rb`, `app/models/arena_ranking.rb`
  - `app/models/class_specialization.rb`, `app/models/skill_tree.rb`, `app/models/skill_node.rb`, `app/models/character_skill.rb`, `app/models/ability.rb`
- `app/models/inventory.rb` — `max_slots`, `max_weight` aliases, `material_count`, `materials_available?`, `consume_materials!`, `add_item_by_name!`
- `app/models/inventory_item.rb` — `quantity`, `weight`, `equipped`, `enhancement_level`, `premium`, `equipment_slot`, `slot_index`
- `app/models/item_template.rb` — `ITEM_TYPES`, `EQUIPMENT_SLOTS`, `equippable?`, `equipment_slot`, rarity/type validations
  - `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier calculation methods, `max_action_points`

### Controllers
- `app/controllers/inventories_controller.rb` — `show`, `equip`, `unequip`, `use`, `destroy`, `sort` actions
- `app/controllers/inventory_items_controller.rb` — `destroy` action for individual items

### Views
- `app/views/inventories/show.html.erb` — main inventory view
- `app/views/inventories/_grid.html.erb` — inventory grid partial
- `app/views/inventories/_equipment.html.erb` — equipment panel partial
- `app/views/inventories/_equipment_slot.html.erb` — individual equipment slot partial
- `app/views/inventories/_stats.html.erb` — stats panel partial

### Services (Game Engine)
  - `app/services/game/movement/turn_processor.rb`, `respawn_service.rb`, `tile_provider.rb`
  - `app/services/game/exploration/encounter_resolver.rb`
- `app/services/game/combat/encounter_builder.rb`, `turn_resolver.rb`, `attack_service.rb`, `skill_executor.rb`, `log_writer.rb`, `arena_ladder.rb`, `post_battle_processor.rb`
- `app/services/game/combat/analytics/report_builder.rb`
- `app/services/game/inventory/manager.rb` — slot/weight limits, stacking, `add_item!`, `remove_item!`, `sort_inventory!`
- `app/services/game/inventory/equipment_service.rb` — `equip!`, `unequip!` with slot validation
- `app/services/game/inventory/enhancement_service.rb` — `enhance!` with gold/material costs, success rates
- `app/services/game/inventory/expansion_service.rb` — inventory capacity upgrades
- `app/services/players/progression/level_up_service.rb`, `stat_allocation_service.rb`
- `app/services/players/alignment/access_gate.rb`
  - `app/services/professions/gathering_resolver.rb`, `app/services/professions/doctor/trauma_response.rb`
- `app/services/characters/vitals_service.rb` — `stats_summary` method for equipment-aware stat calculations

### JavaScript (Stimulus)
- `app/javascript/controllers/inventory_controller.js` — item selection, context menus, equip/use/enhance/split/discard actions

### Helpers
  - `app/helpers/alignment_helper.rb` — alignment badges, faction icons, trauma/timeout badges
  - `app/helpers/arena_helper.rb` — fight type/kind icons, room badges, match status

### Configuration/Data
  - `config/gameplay/biomes.yml`, `db/seeds.rb`
  - `db/migrate/20251127140000_add_chaos_score_to_characters.rb`
- `db/migrate/20251215100000_add_equipment_slot_to_inventory_items.rb` — `equipment_slot`, `slot_index` columns

### Specs
- `spec/models/inventory_spec.rb` — inventory model validations and methods
- `spec/models/inventory_item_spec.rb` — inventory item model specs
- `spec/models/item_template_spec.rb` — item template validations, `equippable?`, `equipment_slot`
- `spec/services/game/inventory/manager_spec.rb` — manager service specs
- `spec/services/game/inventory/enhancement_service_spec.rb` — enhancement service specs
- `spec/services/characters/vitals_service_spec.rb` — vitals service with `stats_summary`
- `spec/requests/inventories_spec.rb` — request specs for inventory controller
- `spec/models/character_spec.rb`, `spec/helpers/alignment_helper_spec.rb`, `spec/helpers/arena_helper_spec.rb`
- specs under `spec/services/game/**`, `spec/services/players/**`, `spec/services/professions/**`

### Documentation
  - `doc/features/3_player.md`, `doc/flow/3_player_character_systems.md`, `doc/features/neverlands_inspired.md`
- `doc/ITEM_SYSTEM_GUIDE.md` — item, inventory & loot architecture guide

## Testing & Verification
- Movement + encounter determinism: `spec/services/game/movement/turn_processor_spec.rb`, `spec/services/game/exploration/encounter_resolver_spec.rb`.
- Combat + arena ladders: `spec/services/game/combat/*`.
- Inventory/enhancements: `spec/services/game/inventory/enhancement_service_spec.rb`.
- Progression/stat allocation + doctor recovery: `spec/services/players/**`, `spec/services/professions/**`.
- Follow `MMO_TESTING_GUIDE.md` for RNG seeding and deterministic expectations.
