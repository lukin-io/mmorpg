# 10. Quests, Narrative, and Events

## Story Structure
- **Data Model:** `QuestChain`, `QuestChapter`, `Quest`, `QuestStep`, and `QuestAssignment` capture authored story beats plus per-character state. Chapters define `level_gate`, `reputation_gate`, and `faction_alignment` so the main storyline mirrors Neverlands canon while unlocking sequentially through `sequence` ordering.
- **Access Control:** `Game::Quests::StorylineProgression` walks chapters in order, relies on `Game::Quests::QuestGateEvaluator`, and creates/updates `QuestAssignment` rows only when level/reputation/faction requirements are satisfied. Side quests reuse the same schema through the `quest_type` enum (`:main_story`, `:side`, `:dynamic`, etc.).
- **Branching Narrative:** Each `QuestStep` may include `branching_outcomes`. `Game::Quests::StoryStepRunner` and `Game::Quests::BranchingChoiceResolver` track dialogue decisions, award or revoke reputation/faction alignment, and unlock/lock follow-up quests by touching additional `QuestAssignment` records. Failure routes feed `Game::Quests::FailureConsequenceHandler`, which can spawn rival arcs.

## Quest Types
- **Static Content:** Designers author arcs in `config/gameplay/quests/static.yml`, then `Game::Quests::StaticQuestBuilder` seeds/updates `Quest`/`QuestChapter`/`QuestStep` rows. These cover key cities, factions, and dungeons.
- **Dynamic Missions:** `Game::Quests::DynamicQuestGenerator` pairs quest metadata (`dynamic_triggers`) with live world triggers (resource shortages, clan control, seasonal event keys). `Game::Quests::DynamicQuestRefresher` invokes the generator whenever a character opens the quest log, ensuring emergent hooks react to current state.
- **Repeatables:** `Game::Quests::DailyRotation` deterministically assigns daily quests across morning/afternoon/evening slots, while `Game::Quests::RepeatableQuestScheduler` refreshes weekly/event quests with predictable cooldowns.
- **Event Quests:** `Game::Events::Scheduler` + `ScheduledEventJob` instantiate seasonal festivals/tournaments. `Game::Events::QuestOrchestrator` wires those instances to dynamic quests, announcer NPCs, and world reskins so events feel bespoke.

## Rewards & Progression
- **Reward Pipeline:** `Game::Quests::RewardService` grants XP (`Players::Progression::ExperiencePipeline`), wallet currencies (`Economy::WalletService`), reputation, recipes/cosmetics, premium token fragments, class abilities (`SkillNode`/`CharacterSkill`), profession unlocks, and housing capacity boosts (`Game::Inventory::ExpansionService`). Each payout is stored on the `QuestAssignment` metadata (`last_reward`) for auditing.
- **Difficulty & Guidance:** `Quest#difficulty_tier` + `recommended_party_size` surface in the Hotwire UI, while `Quest#failure_consequence` plus `Game::Quests::FailureConsequenceHandler` apply rival buffs, reputation hits, or follow-up quests whenever a run fails or is abandoned.
- **Progress Tracking:** `QuestAssignment#progress` keeps `current_step_position`, decision logs, reward timestamps, and cooldowns such as `next_available_at`, enabling fail states to feed back into narrative/stateful gating.

## Quest Delivery & UX
- **Hotwire Controllers/Views:** `QuestsController` responds with HTML + Turbo Stream variants for index/show/accept/complete/advance_story/daily. `app/views/quests/**/*` (filters, assignment list, dialogue, map overlay, Turbo partials) render the quest log with Active/Completed/Repeatable filters and inline cutscenes/dialogues.
- **Story Rendering:** `Game::Quests::StoryStepRunner` supplies the current/next steps so `_story_step.html.erb` can show NPC portraits, dialogues, and branching buttons without full page reloads. Turbo responses keep the dialogue frame, quest list, and repeatable panes in sync.
- **Map Overlay:** `Game::Quests::MapOverlayPresenter` merges authored map pins, NPC data from `Game::World::PopulationDirectory`, and resource nodes from `Game::World::RegionCatalog`, feeding `_map_overlay.html.erb` to highlight objectives, NPCs, and gathering hotspots.

## Events & Special Activities
- **Festivals & World Reskins:** `EventInstance` records carry `world_reskin` and `temporary_npc_keys` metadata. `Game::Events::QuestOrchestrator` merges that metadata back into the instance and broadcasts summaries via `Events::AnnouncementService`, ensuring the world visually reflects the active festival.
- **Arena Tournaments:** `ArenaTournament`, `CompetitionBracket`, and `LeaderboardsController` keep scheduled brackets, announcer NPCs, and spectator ladders in sync. Spectator toggles live on `Battle#allow_spectators`, while announcer NPCs surface through the world population directory.
- **Community Competitions:** `CommunityObjective` tracks resource drives (fishing derby, gathering campaigns). `ScheduledEventJob` + `Game::Events::Scheduler` seed objectives, and `Events::QuestOrchestrator` broadcasts progress to keep the community informed.

## Moderation & Tooling
- **GM Console:** `Admin::GmConsoleController` + `app/views/admin/gm_console/show.html.erb` expose spawn/disable/timer/compensation actions. All actions flow through `Game::Quests::GmConsoleService`, which enforces gating, touches assignments, and emits `AuditLogger` entries.
- **Analytics & Instrumentation:** `Analytics::QuestSnapshotCalculator`, `QuestAnalyticsJob`, and `QuestAnalyticsSnapshot` generate completion/abandon/bottleneck metrics. Results render in the GM console so moderators can spot bottlenecks. `Analytics::QuestTracker` captures completion/failure events for downstream consumers.
- **Recovery & Compensation:** `Game::Quests::FailureConsequenceHandler` and `GmConsoleService#compensate_players!` ensure bug fallout can be mitigated quickly while preserving audit trails and economy integrity.

## Responsible for Implementation Files
- **Models:** `app/models/quest*.rb`, `app/models/quest_chapter.rb`, `app/models/quest_step.rb`, `app/models/quest_analytics_snapshot.rb`, `app/models/event_instance.rb`, `app/models/arena_tournament.rb`, `app/models/community_objective.rb`.
- **Services:** `app/services/game/quests/*.rb`, `app/services/game/events/quest_orchestrator.rb`, `app/services/analytics/quest_snapshot_calculator.rb`, `app/services/events/announcement_service.rb`.
- **Controllers & Views:** `app/controllers/quests_controller.rb`, `app/controllers/admin/gm_console_controller.rb`, `app/views/quests/**`, `app/views/admin/gm_console/show.html.erb`.
- **Jobs & Schedulers:** `app/jobs/quest_analytics_job.rb`, `app/jobs/scheduled_event_job.rb`, plus supporting scheduler services noted above.
- **Config & Data:** `config/gameplay/quests/static.yml`, `db/migrate/20251122130500_create_questing_system.rb`, `db/migrate/20251124090000_expand_quest_story_structure.rb`, `db/migrate/20251124150000_create_quest_analytics_snapshots.rb`.

