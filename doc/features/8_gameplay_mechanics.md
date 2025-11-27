# 8. Core Gameplay Mechanics

## Player Movement
- Tile-based actions are validated server-side using `Game::Movement::MovementValidator`, `Game::Movement::Pathfinder`, and `Game::Movement::TurnProcessor`. Each turn allows a movement, action, or interaction.
- Environmental modifiers come from `MapTileTemplate` + zone metadata (swamps, roads, contested nodes) and feed into movement cooldowns/initiative.
- Respawns and teleports pass through `Game::Movement::RespawnService` and `Game::Movement::TeleportService`; spawn tables (`SpawnPoint`, `SpawnSchedule`) keep faction flows balanced.

## Combat System
- Turn resolution stack: `Game::Combat::TurnResolver`, `Game::Combat::AttackService`, `Game::Formulas::*` (damage, crit, defense), `Game::Systems::StatBlock`, and `Game::Systems::EffectStack`. All RNG is seeded for determinism and testability.
- PvE/PvP share infrastructure: `Battle`, `BattleParticipant`, `ArenaRanking`, `ArenaTournament`, `CompetitionBracket`, and Turbo-driven combat logs.
- Logs stream via `CombatLogEntry` + `CombatLogsController`, enabling replays, moderation, and analytics.

### Combat Skill System (✅ Implemented)
- **Service**: `Game::Combat::SkillExecutor` executes skills with 9 types: damage, heal, buff, debuff, dot, hot, aoe, drain, shield
- **Integration**: Works in both `PveEncounterService` and Arena `CombatProcessor`
- **Sources**: Skills come from class abilities (`Ability`) and unlocked skill nodes (`CharacterSkill`)
- **Features**: MP cost validation, cooldown tracking, stat scaling, critical hits (1.5x)

### Neverlands-Inspired Turn-Based Combat (✅ Implemented)
- **Service**: `Game::Combat::TurnBasedCombatService` — full turn-based combat with body-part targeting
- **Config**: `config/gameplay/combat_actions.yml` — action costs, body parts, magic definitions
- **UI**: Neverlands-style combat interface with participant panels, action selection, and combat log
- **Features**:
  - Body-part targeting (head/torso/stomach/legs) with damage multipliers
  - Action point system with attack penalties for multiple strikes
  - Block allocation across body parts
  - Magic slot system for skill activation
  - Real-time combat log with timestamps and event details
  - Turn-based resolution with skill → attack → end-of-round phases
- **Stimulus**: `turn_combat_controller.js` for interactive combat UI
- **Views**: `_battle.html.erb`, `_nl_participant.html.erb`, `_nl_action_selection.html.erb`, `_nl_magic_slots.html.erb`, `_nl_combat_log.html.erb`

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

### Inventory Management UI (✅ Implemented)
- **Controller**: `InventoriesController` — show, equip, unequip, use, sort, destroy
- **Views**: Full equipment display, 8-column grid, tooltips, context menus
- **Features**:
  - Character model with equipment slots (head, chest, legs, feet, hands, weapons, accessories)
  - Drag-drop ready grid with rarity colors
  - Item context menu (equip, use, enhance, split, discard)
  - Stats panel showing derived combat values
  - Sort by type or rarity

### Equipment Enhancement UI (✅ Implemented)
- **Controller**: `EquipmentEnhancementsController` — index, show, enhance, preview
- **Service**: `Game::Inventory::EnhancementService`
- **Features**:
  - Enhancement levels +1 to +15 based on rarity
  - Success rate decreases with each level (100% → 5%)
  - Material consumption (weapon_stone, armor_stone, enhancement_stone)
  - Gold cost scaling with level and rarity
  - Live preview of stat changes
  - No item destruction on failure

## Dungeon Instances (✅ Implemented)
- **Models**: `DungeonInstance`, `DungeonProgressCheckpoint`, `DungeonEncounter`
- **Controller**: `DungeonsController` — index, show, create_instance, enter/complete encounters
- **Features**:
  - Party-based instanced content with 2-hour duration
  - Four difficulty levels (Easy → Nightmare) with stat multipliers
  - Checkpoint system (respawn at last cleared encounter)
  - 3 attempts per run before failure
  - XP/Gold rewards scaling with difficulty
  - Loot table rolls on completion

## Supporting Systems
- Post-battle trauma mitigation flows through `Professions::Doctor::TraumaResponse` and `Game::Recovery::InfirmaryService`, consuming crafted supplies via `Economy::MedicalSupplySink`.
- Player profile stats (`Users::ProfileStats`) aggregate combat, quest, and arena metrics for UI panels and leaderboards.
- Tutorial quests (`Game::Quests::TutorialBootstrapper`) introduce movement, combat, stat allocation, and crafting right after character creation.

## Responsible for Implementation Files
- **Movement:** `app/services/game/movement/*.rb`, `app/models/character_position.rb`, `app/models/map_tile_template.rb`, `app/models/spawn_point.rb`.
- **Combat:** `app/services/game/combat/*.rb` (incl. `skill_executor.rb`, `pve_encounter_service.rb`, `turn_based_combat_service.rb`), `app/services/arena/combat_processor.rb`, `app/lib/game/formulas/*.rb`, `app/lib/game/systems/*.rb`, `app/models/battle*.rb`, `app/models/combat_log_entry.rb`, `app/helpers/combat_helper.rb`, `app/views/combat/_skills.html.erb`, `app/views/combat/_battle.html.erb`, `app/views/combat/_nl_*.html.erb`, `app/javascript/controllers/turn_combat_controller.js`, `config/gameplay/combat_actions.yml`.
- **Progression:** `app/services/players/progression/*.rb`, `app/models/character.rb`, `app/models/skill_tree.rb`, `app/models/skill_node.rb`, `app/models/class_specialization.rb`.
- **Items & Inventory:** `app/models/item_template.rb`, `app/models/inventory*.rb`, `app/services/game/inventory/*.rb`, `app/services/premium/artifact_store.rb`.
- **Supporting Services:** `app/services/game/recovery/infirmary_service.rb`, `app/services/professions/doctor/trauma_response.rb`, `app/services/users/profile_stats.rb`.
