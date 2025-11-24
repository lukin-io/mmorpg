# 3. Player & Character Systems

## Movement & Exploration
- Tile-based exploration is modeled by `CharacterPosition`, `MapTileTemplate`, and services under `app/services/game/movement/*` (validator, pathfinder, turn processor, respawn service, teleport service). Movement/interaction happens server-side to prevent cheating.
- Regions/biomes come from `Zone`, `Game::World::RegionCatalog`, and `MapTileTemplate`, feeding encounter tables and tax modifiers. Spawn points (`SpawnPoint`, `SpawnSchedule`) enforce faction-specific respawn locations and cooldowns.
- Respawns/teleports: `Game::Movement::RespawnService` and `Game::Movement::TeleportService` reset positions, while infirmary support shortens downtime via `Game::Recovery::InfirmaryService`.

## Combat
- Core combat stack: `Battle`, `BattleParticipant`, `Game::Combat::TurnResolver`, `Game::Combat::AttackService`, `Game::Combat::PostBattleProcessor`, and deterministic formulas under `app/lib/game/**`. Logs stream through `CombatLogEntry` and Turbo updates.
- PvP ladders and arenas rely on `ArenaRanking`, `ArenaTournament`, `CompetitionBracket`, and `LeaderboardsController`; moderation hooks can pause battles (`Moderation::PenaltyService` + Pundit policies).
- Loot and post-battle outcomes route into `Game::Economy::LootGenerator`, achievements (`Achievements::GrantService`), and trauma recovery (Doctor profession + infirmary sink).

## Progression & Stats
- Characters gain XP via `Players::Progression::ExperiencePipeline`, level up through `Players::Progression::LevelUpService`, and assign stat points tracked on the `Character` JSON columns.
- Reputation/faction alignment is stored on the `characters` table and affects access to quests, zones, and clan politics. Progression sources (quest/combat/gathering/premium) are aggregated for analytics.
- Skill trees & specializations use `SkillTree`, `SkillNode`, `CharacterSkill`, `ClassSpecialization`, and `CharacterClass`. Unlockers and respec services live under `app/services/players/progression/*`.

## Classes, Items & Inventory
- Base data: `CharacterClass`, `ClassSpecialization`, and `Ability` records (future) drive stats and ability kits. Resource pools are stored in `character.resource_pools`.
- Inventory/equipment: `Inventory`, `InventoryItem`, `InventoryItem` scopes, and services in `app/services/game/inventory/*` (manager, equipment, enhancement, expansion) enforce slot/weight limits, stacking, and premium storage upgrades.
- Items are defined via `ItemTemplate`, `TradeItem`, `InventoryItem`, and `Premium::ArtifactStore` for monetized artifacts. Enhancements, crafting rewards, and drops integrate with the crafting/profession doc.

## Responsible for Implementation Files
- **Models:** `app/models/character*.rb`, `app/models/character_position.rb`, `app/models/battle*.rb`, `app/models/arena_ranking.rb`, `app/models/skill_tree.rb`, `app/models/class_specialization.rb`, `app/models/item_template.rb`, `app/models/inventory*.rb`.
- **Game Engine:** `app/lib/game/**` (systems, formulas, maps) and `app/services/game/combat/**`, `app/services/game/movement/**`, `app/services/game/recovery/infirmary_service.rb`.
- **Progression Services:** `app/services/players/progression/*.rb`, `app/services/users/profile_stats.rb`.
- **Controllers:** `app/controllers/characters_controller.rb` (future), `app/controllers/combat_logs_controller.rb`, `app/controllers/leaderboards_controller.rb`, `app/controllers/arena_rankings_controller.rb`.
