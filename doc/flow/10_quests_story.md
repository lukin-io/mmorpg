# 10. Quests, Narrative, and Events Flow

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **Quest Models** | ✅ Implemented | `QuestChain`, `QuestChapter`, `Quest`, `QuestStep`, `QuestAssignment` |
| **QuestsController** | ✅ Implemented | index, show, accept, complete, advance_story |
| **Quest Dialogue Views** | ✅ Implemented | `app/views/quests/_dialogue_frame.html.erb` — Turbo Frame quest log UI; `app/views/quests/_quest_dialog.html.erb` — optional legacy modal |
| **quest_dialog_controller.js** | ✅ Implemented | `app/javascript/controllers/quest_dialog_controller.js` — Legacy modal navigation, typewriter, choices |
| **Quest Dialog CSS** | ✅ Implemented | `app/assets/stylesheets/application.css` — Dark fantasy themed |
| **StaticQuestBuilder** | ✅ Implemented | Seeds quests from YAML |
| **StorylineProgression** | ✅ Implemented | Gate enforcement |
| **RewardService** | ✅ Implemented | XP, currency, item rewards |
| **EventInstance** | ✅ Implemented | Seasonal events |
| **DynamicQuestGenerator** | ✅ Implemented | Full procedural quest generation |

---

## Use Cases

### UC-1: Accept Quest from Quest Log (Turbo Frame)
**Actor:** Player viewing the quest log
**Flow:**
1. Player opens `/quests` and selects a quest (e.g., “View Details”)
2. Quest details render inside `turbo-frame#quest-dialogue` (`app/views/quests/_dialogue_frame.html.erb`)
3. Click **Accept Quest** → `POST /quests/:id/accept` (`QuestsController#accept`) with `data-turbo-frame="quest-dialogue"`
4. Server creates/updates the `QuestAssignment` and responds with Turbo Streams to refresh the dialogue frame and related quest list UI

### UC-2: Advance Story and Complete Quest (Turbo Streams)
**Actor:** Player progressing through a quest
**Flow:**
1. While in progress, dialogue choices render as buttons inside `turbo-frame#quest-dialogue`
2. Clicking a choice posts `POST /quests/:id/advance_story` (`QuestsController#advance_story`) with `choice_key`
3. Click **Mark Complete** → `POST /quests/:id/complete` (`QuestsController#complete`)
4. `Game::Quests::RewardService` grants rewards; the UI updates via Turbo Stream templates (`accept/advance_story/complete.turbo_stream.erb`)

### UC-3: Handle Requirements and Branch Errors
**Actor:** Player attempting an invalid action
**Flow:**
1. If gating fails (level/reputation/faction), `QuestsController#accept` keeps the assignment pending and renders an alert via Turbo
2. If a branching `choice_key` has no defined consequence, `QuestsController#advance_story` renders an alert (e.g., “Unknown choice”) without breaking the frame

---

## Key Behavior

### Quest Gating
- `level_gate`: Character must meet minimum level
- `reputation_gate`: Required reputation with faction
- `faction_alignment`: Must match Light/Dark/Neutral
- `prerequisite_quests`: Must complete prior quests

### Dialog Navigation
- **Quest log UI:** Quest dialogue renders server-side inside `turbo-frame#quest-dialogue` and updates through Turbo Stream templates for accept/advance/complete.
- **Optional modal UI:** A Neverlands-style step-by-step modal exists (`app/views/quests/_quest_dialog.html.erb` + `quest_dialog_controller.js`) for world/NPC presentation; if used, it should post to the same `QuestsController` endpoints so Turbo updates remain consistent.

### Reward Types
- Experience points (XP)
- Currency (gold, faction tokens)
- Items (equipment, consumables)
- Recipes (crafting unlocks)
- Alignment shifts
- Reputation gains

---

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

### DynamicQuestGenerator (✅ Implemented)
**Service:** `Game::Quests::DynamicQuestGenerator`
**File:** `app/services/game/quests/dynamic_quest_generator.rb`

**Capabilities:**
1. **Trigger-Based Generation** — Create quests from world state (resource shortage, territory conflict, events)
2. **Daily Quests** — Generate 3 rotating daily quests per character
3. **Zone Quests** — Auto-generate quests when entering new zones

**Quest Types Generated:**
| Type | Objective Template | Example |
|------|-------------------|---------|
| `kill` | Slay %{count} %{target} | "Eliminate 10 Forest Wolves" |
| `gather` | Gather %{count} %{target} | "Gather 15 Moonleaf Herbs" |
| `collect` | Collect %{count} drops | "Collect 5 Wolf Pelts" |
| `explore` | Discover %{count} locations | "Explore 3 areas in Whispering Woods" |
| `escort` | Escort NPC to destination | "Escort the Merchant to Town" |
| `deliver` | Deliver item to NPC | "Deliver Supplies to Captain Elara" |
| `defend` | Survive %{count} waves | "Defend the Outpost for 5 waves" |

**Reward Scaling:**
- XP: `(50 + level × 25) × difficulty_multiplier`
- Gold: `(10 + level × 5) × difficulty_multiplier`
- Difficulty multipliers: Easy (0.75), Normal (1.0), Hard (1.5), Elite (2.0)

**Usage Examples:**
```ruby
# From world triggers
generator = Game::Quests::DynamicQuestGenerator.new
generator.generate!(character: char, triggers: {
  resource_shortage: "iron_ore",
  territory_contested: "northern_pass"
})

# Daily quests
generator.generate_daily!(character, count: 3)

# Zone-specific quests
generator.generate_for_zone!(character, zone)
```

**Key Behaviors:**
- Quests stored with unique keys to prevent duplicates
- Trigger matching supports: level range, zone, faction, event
- Zone quests auto-generated for kill (if hostiles present), gather (if resources), explore (if first visit)
- `Game::Quests::RewardService` — grants XP (`Players::Progression::ExperiencePipeline`), currencies (`Economy::WalletService`), alignment, recipes, housing capacity (`Game::Inventory::ExpansionService`), or premium fragments; writes `last_reward` metadata.
- `Game::Events::Scheduler`, `Game::Events::QuestOrchestrator`, `Events::AnnouncementService` — tie seasonal events to quest arcs, broadcast world reskins, queue announcer NPCs.
- `Analytics::QuestSnapshotCalculator`, `Analytics::QuestTracker` — build GM dashboards and event telemetry.

---

## Controllers & Views
- `QuestsController#index/show/accept/complete/advance_story/daily` — Turbo-friendly quest log with filters, dialogue frames, repeatable slots.
- Partial set: `_quest_assignment.html.erb`, `_story_step.html.erb`, `_repeatable_assignments.html.erb`, `_map_overlay.html.erb`.
- `Admin::GmConsoleController` — GM overrides: spawn/disable quests, adjust timers, compensate players; hits `Game::Quests::GmConsoleService`.
- `Events::AnnouncementsController` (if present) or Turbo streams that surface scheduled events + quest tie-ins.

### Quest Dialogue UI (Turbo Frame + Optional Modal)

Elselands uses a Hotwire-first quest dialogue experience. The canonical surface is the quest log / quest show
Turbo Frame, while an optional Neverlands-style modal can be used for “world NPC” presentation.

#### Turbo Frame Flow (Quest Log / Quest Show)
The quest show page renders the dialogue inside `turbo-frame#quest-dialogue` (`app/views/quests/_dialogue_frame.html.erb`).

```
GET /quests
  ↓ (select quest)
GET /quests/:id
  ↓
<turbo-frame id="quest-dialogue"> … </turbo-frame>
  ↓ (Accept / choice / complete)
POST /quests/:id/accept | /advance_story | /complete  (targets quest-dialogue)
  ↓
Turbo Stream templates refresh the dialogue frame + quest list + flash
```

**Turbo Stream templates**
- `app/views/quests/accept.turbo_stream.erb`
- `app/views/quests/advance_story.turbo_stream.erb`
- `app/views/quests/complete.turbo_stream.erb`

#### Error Handling
- **Requirements not met:** Accept keeps the assignment pending and renders an alert without breaking the frame.
- **Invalid branching choice:** Advance story renders an alert (e.g., “Unknown choice”) and keeps the dialogue usable.

#### Optional Modal Flow (Legacy)
The `app/views/quests/_quest_dialog.html.erb` modal + `quest_dialog_controller.js` provide step-by-step narration
(avatars, typewriter, Prev/Next). If the modal is used, it should submit to the same `QuestsController` endpoints
so the server remains the single source of truth for assignment state and rewards.

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
- System spec: `spec/system/quests_ui_spec.rb` (accept/advance/complete via Turbo Frames/Streams).

---

## Responsible for Implementation Files
- **Models:** `app/models/quest_chain.rb`, `quest_chapter.rb`, `quest.rb`, `quest_step.rb`, `quest_assignment.rb`, `quest_analytics_snapshot.rb`, `event_instance.rb`, `community_objective.rb`, `arena_tournament.rb`, `competition_bracket.rb`.
- **Services:** `app/services/game/quests/*.rb`, `app/services/game/events/quest_orchestrator.rb`, `app/services/events/announcement_service.rb`, `app/services/analytics/quest_snapshot_calculator.rb`, `app/services/game/quests/gm_console_service.rb`.
- **Controllers & Views:** `app/controllers/quests_controller.rb`, `app/controllers/admin/gm_console_controller.rb`, `app/views/quests/**/*`, `app/views/admin/gm_console/show.html.erb`.
- **Jobs:** `app/jobs/quest_analytics_job.rb`, `app/jobs/scheduled_event_job.rb`, (any `LiveOps::QuestMonitorJob`).
- **Docs:** `doc/features/10_quests_story.md`, this flow doc.
