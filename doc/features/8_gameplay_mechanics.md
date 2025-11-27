# 8. Core Gameplay Mechanics

## Player Movement
- Tile-based actions are validated server-side using `Game::Movement::MovementValidator`, `Game::Movement::Pathfinder`, and `Game::Movement::TurnProcessor`. Each turn allows a movement, action, or interaction.
- Environmental modifiers come from `MapTileTemplate` + zone metadata (swamps, roads, contested nodes) and feed into movement cooldowns/initiative.
- Respawns and teleports pass through `Game::Movement::RespawnService` and `Game::Movement::TeleportService`; spawn tables (`SpawnPoint`, `SpawnSchedule`) keep faction flows balanced.

## Combat System
- Turn resolution stack: `Game::Combat::TurnResolver`, `Game::Combat::AttackService`, `Game::Formulas::*` (damage, crit, defense), `Game::Systems::StatBlock`, and `Game::Systems::EffectStack`. All RNG is seeded for determinism and testability.
- PvE/PvP share infrastructure: `Battle`, `BattleParticipant`, `ArenaRanking`, `ArenaTournament`, `CompetitionBracket`, and Turbo-driven combat logs.
- Logs stream via `CombatLogEntry` + `CombatLogsController`, enabling replays, moderation, and analytics.

## Character Progression
- XP flows through `Players::Progression::ExperiencePipeline`, which aggregates quest/combat/gathering/premium sources before invoking `Players::Progression::LevelUpService`.
- Reputation/faction alignment on `Character` gates quests, vendors, and clan roles. Stat points are stored in JSON columns and surfaced in profile sheets.
- Skill trees and specializations are represented by `SkillTree`, `SkillNode`, `CharacterSkill`, and `ClassSpecialization`; unlock services run in `Players::Progression::*`.

### Skill Trees UI (✅ Implemented)
- **Controller**: `SkillTreesController` — index, show, unlock, respec actions
- **Views**: Tree browser, node visualization, unlock buttons, skill points display
- **Services**: `SkillUnlockService` (validates level/quest/prerequisites), `RespecService` (gold/premium/quest refund)
- **Stimulus**: `skill_tree_controller.js` — node selection, tooltips, unlock animations
- **Features**:
  - Visual skill tree with tier-based layout
  - Prerequisite validation and quest gating
  - Skill point cost from `resource_cost` JSONB
  - Respec with cooldown and payment options

## Classes, Skills, Abilities
- Launch classes (Warrior, Mage, Hunter, Priest, Thief) live in `CharacterClass`. Each provides base stats, allowed weapons, and ability kits.
- Secondary specializations unlock via quest chains and `ClassSpecialization` associations; combos/resources (rage/mana/etc.) are tracked in `character.resource_pools`.
- Future ability metadata will attach to `Ability` models and `Game::Combat::SkillExecutor`.

## Items, Inventory & Equipment
- Items fall under `ItemTemplate`, `Inventory`, `InventoryItem`, `TradeItem`, and `Premium::ArtifactStore`. Inventory services (`Game::Inventory::Manager`, `Game::Inventory::EquipmentService`, `Game::Inventory::EnhancementService`, `Game::Inventory::ExpansionService`) enforce slots, weight, equipping, enhancements, and premium storage boosts.
- Crafting outputs feed directly into inventory and the auction house via `CraftingJobCompletionJob` + `Professions::CraftingOutcomeResolver`.
- Premium artifacts provide convenience boosts (teleports, storage, XP) but remain power-neutral per `doc/features/9_economy.md`.

## Supporting Systems
- Post-battle trauma mitigation flows through `Professions::Doctor::TraumaResponse` and `Game::Recovery::InfirmaryService`, consuming crafted supplies via `Economy::MedicalSupplySink`.
- Player profile stats (`Users::ProfileStats`) aggregate combat, quest, and arena metrics for UI panels and leaderboards.
- Tutorial quests (`Game::Quests::TutorialBootstrapper`) introduce movement, combat, stat allocation, and crafting right after character creation.

## Responsible for Implementation Files
- **Movement:** `app/services/game/movement/*.rb`, `app/models/character_position.rb`, `app/models/map_tile_template.rb`, `app/models/spawn_point.rb`.
- **Combat:** `app/services/game/combat/*.rb`, `app/lib/game/formulas/*.rb`, `app/lib/game/systems/*.rb`, `app/models/battle*.rb`, `app/models/combat_log_entry.rb`.
- **Progression:** `app/services/players/progression/*.rb`, `app/models/character.rb`, `app/models/skill_tree.rb`, `app/models/skill_node.rb`, `app/models/class_specialization.rb`.
- **Items & Inventory:** `app/models/item_template.rb`, `app/models/inventory*.rb`, `app/services/game/inventory/*.rb`, `app/services/premium/artifact_store.rb`.
- **Supporting Services:** `app/services/game/recovery/infirmary_service.rb`, `app/services/professions/doctor/trauma_response.rb`, `app/services/users/profile_stats.rb`.
