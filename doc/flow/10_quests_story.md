# 10. Quests, Narrative, and Events Flow

## Overview
- Complements `doc/features/10_quests_story.md` by detailing how quest data moves through services, controllers, jobs, and analytics.
- Covers authored quests, dynamic/daily/event quests, branching narrative, rewards, and GM tooling.

---

## Data Model & Seeds
- `QuestChain`, `QuestChapter`, `Quest`, `QuestStep`, `QuestAssignment` — authored arcs, gating (`level_gate`, `reputation_gate`, `faction_alignment`), branching outcomes, per-character progress.
- `QuestAnalyticsSnapshot`, `QuestAnalyticsJob` — aggregate completion/failure metrics.
- `EventInstance`, `CommunityObjective`, `ArenaTournament`, `CompetitionBracket` — integrate events/festivals with quest hooks.
- Config files: `config/gameplay/quests/static.yml`, `config/gameplay/events/*.yml`, `config/gameplay/daily_rotation.yml`.

---

## Services & Orchestration
- `Game::Quests::StaticQuestBuilder` — seeds authored quests/chapters/steps from YAML and keeps them idempotent.
- `Game::Quests::StorylineProgression` + `QuestGateEvaluator` — enforce level/reputation/faction gates before creating `QuestAssignment` rows.
- `Game::Quests::StoryStepRunner`, `BranchingChoiceResolver`, `FailureConsequenceHandler` — run narrative steps, record choices, spawn rival arcs, handle fail states.
- `Game::Quests::DynamicQuestGenerator`, `DynamicQuestRefresher`, `RepeatableQuestScheduler`, `DailyRotation` — create emergent missions and deterministic daily/weekly lineups.
- `Game::Quests::RewardService` — grants XP (`Players::Progression::ExperiencePipeline`), currencies (`Economy::WalletService`), alignment, recipes, housing capacity (`Game::Inventory::ExpansionService`), or premium fragments; writes `last_reward` metadata.
- `Game::Events::Scheduler`, `Game::Events::QuestOrchestrator`, `Events::AnnouncementService` — tie seasonal events to quest arcs, broadcast world reskins, queue announcer NPCs.
- `Analytics::QuestSnapshotCalculator`, `Analytics::QuestTracker` — build GM dashboards and event telemetry.

---

## Controllers & Views
- `QuestsController#index/show/accept/complete/advance_story/daily` — Turbo-friendly quest log with filters, dialogue frames, repeatable slots.
- Partial set: `_quest_assignment.html.erb`, `_story_step.html.erb`, `_repeatable_assignments.html.erb`, `_map_overlay.html.erb`.
- `Admin::GmConsoleController` — GM overrides: spawn/disable quests, adjust timers, compensate players; hits `Game::Quests::GmConsoleService`.
- `Events::AnnouncementsController` (if present) or Turbo streams that surface scheduled events + quest tie-ins.

---

## Jobs & Background Processing
- `QuestAnalyticsJob` — nightly analytics snapshots and trend detection.
- `ScheduledEventJob` — kicks off festivals, world reskins, and seasonal questlines.
- `LiveOps::QuestMonitorJob` (if configured) — watches quest failure spikes and alerts moderation.

---

## Policies & Security
- `QuestPolicy`, `QuestAssignmentPolicy` — ensure users only mutate their own quest assignments; staff overrides limited to GM roles.
- GM console actions log via `AuditLogger` for traceability.
- `Events::AnnouncementService` ensures only whitelisted NPCs/keys broadcast to the live world.

---

## Testing & Verification
- Specs: `spec/services/game/quests/storyline_progression_spec.rb`, `story_step_runner_spec.rb`, `dynamic_quest_generator_spec.rb`, `reward_service_spec.rb`, `spec/requests/quests_controller_spec.rb`, `spec/services/game/events/quest_orchestrator_spec.rb`, `spec/services/analytics/quest_snapshot_calculator_spec.rb`.
- Factory coverage: `quest`, `quest_assignment`, `quest_step`, `event_instance`, `community_objective`.

---

## Responsible for Implementation Files
- **Models:** `app/models/quest_chain.rb`, `quest_chapter.rb`, `quest.rb`, `quest_step.rb`, `quest_assignment.rb`, `quest_analytics_snapshot.rb`, `event_instance.rb`, `community_objective.rb`, `arena_tournament.rb`, `competition_bracket.rb`.
- **Services:** `app/services/game/quests/*.rb`, `app/services/game/events/quest_orchestrator.rb`, `app/services/events/announcement_service.rb`, `app/services/analytics/quest_snapshot_calculator.rb`, `app/services/game/quests/gm_console_service.rb`.
- **Controllers & Views:** `app/controllers/quests_controller.rb`, `app/controllers/admin/gm_console_controller.rb`, `app/views/quests/**/*`, `app/views/admin/gm_console/show.html.erb`.
- **Jobs:** `app/jobs/quest_analytics_job.rb`, `app/jobs/scheduled_event_job.rb`, (any `LiveOps::QuestMonitorJob`).
- **Docs:** `doc/features/10_quests_story.md`, this flow doc.

