# 4. World, NPC, and Quest Systems

## World Structure
- The overworld is modeled through `Zone`, `MapTileTemplate`, `Game::World::RegionCatalog`, and `SpawnPoint`. Each tile stores biome, passability, and metadata so services like `Game::Movement::TileProvider` can resolve encounters deterministically.
- Territory buffs/taxes hook into `ClanTerritory` and `Economy::TaxCalculator`, letting clan ownership affect regions/cities referenced in `12_clan_system.md`.
- Resource nodes (`GatheringNode`, `Professions::GatheringResolver`) and spawn schedules (`SpawnSchedule`) keep the world active even when no events are running.

## NPCs & Monsters
- NPC templates live in `app/models/npc_template.rb` with roles (vendors, trainers, announcers) and metadata driving dialogues and shops. Monster data ties into `Game::Economy::LootGenerator` and combat services.
- Reputation/faction checks use `Character#alignment_score` + `QuestAssignment` state to gate dialogue options and vendor pricing.
- Guard/magistrate behavior surfaces moderation/reporting actions (see `Moderation::ReportIntake` and `doc/features/5_moderation.md`).

### NPC Dialogue System (✅ Implemented)
- **Service**: `Game::Npc::DialogueService` orchestrates all NPC interactions
- **Roles Supported**: quest_giver, vendor, trainer, innkeeper, banker, guard, auctioneer, crafter, hostile
- **Features**:
  - Quest giver: View/accept/complete quests
  - Vendor: Buy/sell items with metadata-driven pricing
  - Trainer: Learn skills with gold cost and prerequisites
  - Innkeeper: Rest to heal HP (Common/Private/Suite rooms)
  - Banker: Deposit/withdraw gold between wallet and bank
  - Guard: Zone info and directions
  - Hostile: Combat prompt with threat level indicator
- **Zone Scoping**: `NpcTemplate.in_zone(zone_name)` + `#can_spawn_at?` for position-based NPC queries

## Quests & Narrative
- Quests are stored in `Quest`, `QuestObjective`, `QuestAssignment`, and `QuestChain`. Controllers (`QuestsController`) and services `Game::Quests::TutorialBootstrapper` drive onboarding, repeatables, and chapter unlocks.
- Hotwire quest log: filters for active/completed/daily states update via Turbo Streams (views under `app/views/quests`), and map overlays highlight objectives via Stimulus controllers.
- Rewards integrate with XP (`Players::Progression`), currency (`Economy::WalletService`), recipes (`Recipe`), and cosmetics/achievements.

## Events & Special Activities
- Seasonal/holiday hooks rely on `EventInstance`, `EventSchedule`, `GameEventsController`, `LiveOps::Event`, and `AnnouncementsController` to spawn NPCs, quests, and themed rewards.
- Arena tournaments (`ArenaTournament`, `CompetitionBracket`) and community drives (guild missions, gathering contests) broadcast through Action Cable + Turbo.
- GM tooling under `app/services/live_ops` and `app/controllers/admin/live_ops/events_controller.rb` lets staff toggle quests, adjust timers, or compensate players.

## Moderation & Reporting
- NPC magistrates/officers surface inline report entry points that call `Moderation::ReportIntake` with location metadata (`zone_key`), screenshot URLs, or combat replay IDs.
- Quest/NPC changes are tracked via `AuditLog` entries when GMs spawn/disable content, ensuring disputes can be resolved quickly.

## Mobile & Accessibility
- The quest log, map overlay, and NPC dialogue screens use Hotwire responsive patterns outlined in `GUIDE.md`. Stimulus controllers keep interactions one-handed on phones/tablets.
- Inline cutscenes (ViewComponents/partials) avoid autoplay audio and include subtitles for accessibility.

## Responsible for Implementation Files
- **World Data:** `app/models/zone.rb`, `app/models/map_tile_template.rb`, `app/models/spawn_point.rb`, `app/models/spawn_schedule.rb`, `app/lib/game/world/region_catalog.rb`.
- **NPC & Questing:** `app/models/npc_template.rb`, `app/models/quest*.rb`, `app/controllers/quests_controller.rb`, `app/services/game/quests/tutorial_bootstrapper.rb`.
- **NPC Dialogue:** `app/services/game/npc/dialogue_service.rb`, `app/controllers/world_controller.rb` (`interact`, `dialogue_action`), `app/views/world/dialogue.html.erb`, `app/views/world/_dialogue_*.html.erb`.
- **Events:** `app/models/event_instance.rb`, `app/models/event_schedule.rb`, `app/controllers/game_events_controller.rb`, `app/controllers/admin/live_ops/events_controller.rb`, `app/services/live_ops/*`.
- **Moderation Hooks:** `app/services/moderation/report_intake.rb`, `app/models/audit_log.rb`, `app/services/audit_logger.rb`.
