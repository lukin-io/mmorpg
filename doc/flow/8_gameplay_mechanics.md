# 8. Gameplay Mechanics Flow

## Overview
- Implements `doc/features/8_gameplay_mechanics.md` across movement, combat, progression, classes, inventory, and supporting tutorial/analytics systems.
- Extends the deterministic engine established in `doc/flow/3_player_character_systems.md` with new queues, ladders, respec pipelines, and onboarding quests.

## Player Movement
- Movement intents now persist via `MovementCommand` rows, queued through `Game::Movement::CommandQueue` and drained by `Game::MovementCommandProcessorJob` to keep the server authoritative and audit-friendly.
- `Game::Movement::TurnProcessor` consults `Game::Movement::TerrainModifier` (driven by `config/gameplay/terrain_modifiers.yml` + `Zone#metadata`) to scale cooldowns for roads/swamps/etc., aligning with the “environmental modifiers” requirement.
- Tile metadata/biome lookups still flow through `Game::Movement::TileProvider`; encounters resolve with the same deterministic RNG path.

## Combat System
- Battles record their PvP sub-mode (`battles.pvp_mode`); `Game::Combat::ArenaLadder` now updates duel/skirmish/clan/arena ladders per `battle.ladder_type`.
- `Game::Combat::TurnResolver` applies buff/debuff definitions via `Game::Combat::EffectBookkeeper`, logs attacker/defender IDs, and ticks status effects each turn.
- `CombatLogEntry` payloads now include IDs/damage totals used for moderation, replays, and analytics.

## Character Progression
- `Players::Progression::ExperiencePipeline` tracks XP by source (quest/combat/gathering) and feeds `LevelUpService`.
- `Players::Progression::SkillUnlockService`, `RespecService`, and `SpecializationUnlocker` enforce quest/level requirements and respec payment paths (quest token or premium ledger).
- `Players::Alignment::AccessGate#evaluate` exposes detailed gating reasons for cities, vendors, and storylines.

## Classes, Skills, Abilities
- Ability seeds now include structured buffs/debuffs; `TurnResolver` consumes them to apply stat changes and status messaging.
- Skill tree unlocks are enforced through the new services above, ensuring hybrid builds and epic specialization questlines remain deterministic.

## Items, Inventory, Equipment
- `Game::Inventory::ExpansionService` increases slot/weight caps either via housing storage or a premium-token debit, satisfying the storage expander requirement.
- Existing enhancement/enhancement services continue to integrate with crafting professions; premium artifacts remain stat-capped via `ItemTemplate#premium_stat_cap`.

## Supporting Systems
- `Game::Recovery::InfirmaryService` reads zone infirmary metadata to reduce trauma downtime post-battle, complementing the Doctor profession.
- `Game::Quests::TutorialBootstrapper` auto-enrolls new characters into movement/combat/stat/gear tutorial quests defined in seeds.
- `Users::ProfileStats` feeds `Users::PublicProfile` with damage/quest/arena metrics aggregated from combat logs and quest assignments.

## Responsible for Implementation Files
- models:
  - `app/models/movement_command.rb`, `app/models/battle.rb`, `app/models/arena_ranking.rb`, `app/models/character.rb`
- services/jobs:
  - `app/services/game/movement/command_queue.rb`, `turn_processor.rb`, `terrain_modifier.rb`
  - `app/jobs/game/movement_command_processor_job.rb`
  - `app/services/game/combat/turn_resolver.rb`, `effect_bookkeeper.rb`, `arena_ladder.rb`, `post_battle_processor.rb`
  - `app/services/players/progression/experience_pipeline.rb`, `skill_unlock_service.rb`, `respec_service.rb`, `specialization_unlocker.rb`
  - `app/services/players/alignment/access_gate.rb`
  - `app/services/game/inventory/expansion_service.rb`
  - `app/services/game/recovery/infirmary_service.rb`
  - `app/services/game/quests/tutorial_bootstrapper.rb`
  - `app/services/users/profile_stats.rb`, `users/public_profile.rb`
- migrations/config/seeds:
  - `db/migrate/20251124130000_create_movement_commands.rb`
  - `db/migrate/20251124131000_expand_battle_ladders.rb`
  - `db/migrate/20251124132000_add_progression_sources_to_characters.rb`
  - `config/gameplay/terrain_modifiers.yml`
  - `db/seeds.rb` (tutorial quests, ability effects, zone metadata)

## Testing & Verification
- Movement queue/modifier coverage: `spec/services/game/movement/command_queue_spec.rb`, `spec/services/game/movement/turn_processor_spec.rb`.
- Combat ladders/effects/logs: `spec/services/game/combat/arena_ladder_spec.rb`, `spec/services/game/combat/turn_resolver_spec.rb`, `spec/jobs/live_ops/arena_monitor_job_spec.rb`.
- Progression/respec/specializations/alignment: specs under `spec/services/players/**`.
- Inventory expansion, infirmary recovery, tutorial bootstrapper, and profile stats: dedicated specs under `spec/services/game/**` and `spec/services/users/**`.

