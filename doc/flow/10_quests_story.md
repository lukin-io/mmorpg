# 10. Quests, Narrative, and Events Flow

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **Quest Models** | ✅ Implemented | `QuestChain`, `QuestChapter`, `Quest`, `QuestStep`, `QuestAssignment` |
| **QuestsController** | ✅ Implemented | index, show, accept, complete, advance_story |
| **Quest Dialog Views** | ✅ Implemented | `app/views/quests/_quest_dialog.html.erb` — Full NPC dialog modal |
| **quest_dialog_controller.js** | ✅ Implemented | `app/javascript/controllers/quest_dialog_controller.js` — Navigation, typewriter, choices |
| **Quest Dialog CSS** | ✅ Implemented | `app/assets/stylesheets/application.css` — Dark fantasy themed |
| **StaticQuestBuilder** | ✅ Implemented | Seeds quests from YAML |
| **StorylineProgression** | ✅ Implemented | Gate enforcement |
| **RewardService** | ✅ Implemented | XP, currency, item rewards |
| **EventInstance** | ✅ Implemented | Seasonal events |
| **DynamicQuestGenerator** | ✅ Implemented | Full procedural quest generation |

---

## Use Cases

### UC-1: Accept Quest from NPC
**Actor:** Player interacting with NPC
**Flow:**
1. Player clicks NPC or quest marker in world
2. Quest dialog overlay appears with NPC avatar
3. Dialog text shows quest description (step 0)
4. Player navigates through dialog steps (← Prev / Next →)
5. At final step, "Accept Quest" button appears
6. Click triggers `QuestsController#accept`
7. `QuestAssignment` created with `status: :in_progress`

### UC-2: Complete Quest
**Actor:** Player with completed objectives
**Flow:**
1. Player returns to NPC after completing objectives
2. Quest dialog shows completion text
3. "Complete Quest" button appears at final step
4. Click triggers `QuestsController#complete`
5. `RewardService` grants XP, items, currencies
6. `QuestAssignment` updated to `status: :completed`

### UC-3: Navigate Branching Story
**Actor:** Player at decision point
**Flow:**
1. Quest step presents choice (e.g., "Help villagers" vs "Ignore")
2. Player clicks chosen option
3. `BranchingChoiceResolver` records decision in progress
4. Story progresses to appropriate branch
5. Future steps/rewards may differ based on choice

---

## Key Behavior

### Quest Gating
- `level_gate`: Character must meet minimum level
- `reputation_gate`: Required reputation with faction
- `faction_alignment`: Must match Light/Dark/Neutral
- `prerequisite_quests`: Must complete prior quests

### Dialog Navigation
- Multi-step dialogs with Prev/Next buttons
- Step indicator dots (• ◦ ◦ ◦)
- NPC avatar (130x130) on left side
- Action buttons only appear at final step

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

### Quest Dialog System (Neverlands-Inspired)

The quest dialog system presents NPC conversations as step-by-step modal dialogs with navigation.

#### Dialog Flow
```
Player clicks "Quests" button or NPC
        ↓
AJAX/Turbo fetches quest dialog data
        ↓
Modal overlay appears with:
  - NPC avatar (130x130 portrait)
  - Dialog text (step 0)
  - Navigation buttons
        ↓
Player navigates: ← Prev | Next →
        ↓
At final step, action buttons appear:
  - "Accept Quest" (type 1)
  - "Complete Quest" (type 2)
        ↓
Action triggers server call → rewards/progression
```

#### Stimulus Controller: `quest_dialog_controller.js`
```javascript
export default class extends Controller {
  static targets = ["dialog", "avatar", "navigation", "overlay"]
  static values = {
    steps: Array,      // Dialog text steps
    npcAvatar: String, // NPC portrait URL
    questId: Number,
    actionType: Number, // 1=accept, 2=complete
    actionCode: String
  }

  currentStep = 0

  connect() {
    this.showOverlay()
    this.renderStep()
  }

  nextStep() {
    if (this.currentStep < this.stepsValue.length - 1) {
      this.currentStep++
      this.renderStep()
    }
  }

  prevStep() {
    if (this.currentStep > 0) {
      this.currentStep--
      this.renderStep()
    }
  }

  renderStep() {
    this.dialogTarget.innerHTML = this.stepsValue[this.currentStep]
    this.renderNavigation()
  }

  renderNavigation() {
    let nav = ""
    if (this.currentStep > 0) {
      nav += `<button class="quest-nav-btn quest-nav-prev" data-action="click->quest-dialog#prevStep">← Back</button>`
    }
    if (this.currentStep < this.stepsValue.length - 1) {
      nav += `<button class="quest-nav-btn quest-nav-next" data-action="click->quest-dialog#nextStep">Continue →</button>`
    } else if (this.actionTypeValue) {
      // Final step - show action button
      const label = this.actionTypeValue === 1 ? "Accept Quest" : "Complete Quest"
      const cssClass = this.actionTypeValue === 1 ? "quest-accept-btn" : "quest-complete-btn"
      nav += `<button class="${cssClass}" data-action="click->quest-dialog#submitAction">${label}</button>`
    }
    this.navigationTarget.innerHTML = nav
  }

  submitAction() {
    const url = `/quests/${this.questIdValue}/${this.actionTypeValue === 1 ? 'accept' : 'complete'}`
    fetch(url, {
      method: 'POST',
      headers: { 'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content }
    }).then(response => response.json())
      .then(data => {
        this.close()
        // Show reward notification if applicable
      })
  }

  close() {
    this.overlayTarget.remove()
  }
}
```

#### CSS for Quest Dialog
```css
/* Quest dialog modal */
.quest-dialog-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.quest-dialog-box {
  background: url('/assets/quest_dialog_bg.png') no-repeat center;
  width: 750px;
  min-height: 350px;
  padding: 40px 80px;
  position: relative;
}

.quest-dialog-close {
  position: absolute;
  top: 20px;
  right: 20px;
  cursor: pointer;
}

.quest-dialog-content {
  display: flex;
  gap: 20px;
}

.quest-dialog-text {
  flex: 1;
  font-size: 1rem;
  line-height: 1.6;
  color: #222;
}

.quest-dialog-avatar {
  width: 130px;
  height: 130px;
  border: 3px solid var(--nl-gold);
  border-radius: var(--nl-radius-sm);
  overflow: hidden;
}

.quest-dialog-nav {
  margin-top: 20px;
  display: flex;
  justify-content: center;
  gap: 10px;
}

.quest-nav-btn {
  padding: 8px 20px;
  background: var(--nl-bg-secondary);
  border: 2px solid var(--nl-border-medium);
  cursor: pointer;
  font-weight: bold;
}

.quest-accept-btn {
  background: linear-gradient(180deg, #4CAF50 0%, #2E7D32 100%);
  color: white;
  padding: 10px 30px;
  border: 2px solid #1B5E20;
  font-weight: bold;
}

.quest-complete-btn {
  background: linear-gradient(180deg, #FFD700 0%, #FFA000 100%);
  color: #333;
  padding: 10px 30px;
  border: 2px solid #FF8F00;
  font-weight: bold;
}
```

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

