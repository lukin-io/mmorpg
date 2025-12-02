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
- `Inventory`, `InventoryItem`, and `Game::Inventory::Manager/EquipmentService/EnhancementService` manage slots, weight, stacking, premium fairness, and crafting-based enhancement risks.
- Item templates carry weight, stack limits, premium caps, and enhancement rules to keep pay-to-win in check.

## Crafting & Professions
- Gathering nodes connect professions to zones; `Professions::GatheringResolver` awards resources with seeded RNG.
- The Doctor profession shortens trauma timers post-battle via `Professions::Doctor::TraumaResponse`.

## Responsible for Implementation Files
- models:
  - `app/models/zone.rb`, `app/models/spawn_point.rb`, `app/models/character_position.rb`, `app/models/gathering_node.rb`
  - `app/models/battle.rb`, `app/models/battle_participant.rb`, `app/models/combat_log_entry.rb`, `app/models/arena_ranking.rb`
  - `app/models/class_specialization.rb`, `app/models/skill_tree.rb`, `app/models/skill_node.rb`, `app/models/character_skill.rb`, `app/models/ability.rb`
  - `app/models/inventory.rb`, `app/models/inventory_item.rb`
  - `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier calculation methods, `max_action_points`
- services:
  - `app/services/game/movement/turn_processor.rb`, `respawn_service.rb`, `tile_provider.rb`
  - `app/services/game/exploration/encounter_resolver.rb`
  - `app/services/game/combat/encounter_builder.rb`, `turn_resolver.rb`, `attack_service.rb`, `skill_executor.rb`, `log_writer.rb`, `arena_ladder.rb`, `post_battle_processor.rb`, `app/services/game/combat/analytics/report_builder.rb`
  - `app/services/game/inventory/manager.rb`, `equipment_service.rb`, `enhancement_service.rb`
  - `app/services/players/progression/level_up_service.rb`, `stat_allocation_service.rb`, `app/services/players/alignment/access_gate.rb`
  - `app/services/professions/gathering_resolver.rb`, `app/services/professions/doctor/trauma_response.rb`
- helpers:
  - `app/helpers/alignment_helper.rb` — alignment badges, faction icons, trauma/timeout badges
  - `app/helpers/arena_helper.rb` — fight type/kind icons, room badges, match status
- configuration/data:
  - `config/gameplay/biomes.yml`, `db/seeds.rb`
  - `db/migrate/20251127140000_add_chaos_score_to_characters.rb`
- docs/tests:
  - `doc/features/3_player.md`, `doc/flow/3_player_character_systems.md`, `doc/features/neverlands_inspired.md`
  - specs under `spec/services/game/**`, `spec/services/players/**`, `spec/services/professions/**`
  - `spec/models/character_spec.rb`, `spec/helpers/alignment_helper_spec.rb`, `spec/helpers/arena_helper_spec.rb`

## Testing & Verification
- Movement + encounter determinism: `spec/services/game/movement/turn_processor_spec.rb`, `spec/services/game/exploration/encounter_resolver_spec.rb`.
- Combat + arena ladders: `spec/services/game/combat/*`.
- Inventory/enhancements: `spec/services/game/inventory/enhancement_service_spec.rb`.
- Progression/stat allocation + doctor recovery: `spec/services/players/**`, `spec/services/professions/**`.
- Follow `MMO_TESTING_GUIDE.md` for RNG seeding and deterministic expectations.
