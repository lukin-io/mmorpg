# 11. Arena & PvP Combat Flow

## Overview
This document describes the Arena PvP system, inspired by Neverlands' classic arena mechanics. The system supports multiple fight types, room-based matchmaking, real-time combat updates, and comprehensive fight logging.

## Arena Concepts (Neverlands-Inspired)

### Arena Rooms
Each arena has multiple rooms with level restrictions and special rules:

| Room Type | Level Range | Description |
|-----------|-------------|-------------|
| Training Hall | 0-5 | New player practice arena, reduced penalties |
| Trial Hall | 5-10 | Beginner competitive fights |
| Challenge Hall | 5-33 | Open level range duels |
| Initiation Hall | 9-33 | Mid-level progression fights |
| Patron Hall | 16-33 | High-level competitive |
| Law Hall | 0-33 | Faction-specific (Lawful alignment) |
| Light Hall | 0-33 | Faction-specific (Light alignment) |
| Balance Hall | 0-33 | Faction-specific (Neutral alignment) |
| Chaos Hall | 0-33 | Faction-specific (Chaos alignment) |
| Dark Hall | 0-33 | Faction-specific (Dark alignment) |

### Fight Types
1. **Duels** (`duel`) — 1v1 combat
2. **Group Battles** (`group`) — Team vs Team (configurable sizes)
3. **Sacrifice Battles** (`sacrifice`) — Free-for-all melee
4. **Tactical** (`tactical`) — Strategy-based with positioning
5. **Betting/Totalizator** (`betting`) — Spectator wagering matches

### Fight Parameters
```yaml
fight_kind:
  - no_weapons: "Bare-handed combat only"
  - no_artifacts: "No magical items"
  - limited_artifacts: "Restricted equipment tiers"
  - free: "All equipment allowed"
  - clan_vs_clan: "Guild team battles"
  - faction_vs_faction: "Alignment-based teams"
  - clan_vs_all: "Guild vs random players"
  - faction_vs_all: "Alignment vs random"
  - closed: "Invite-only (up to 10v10)"

timeout_seconds: [120, 180, 240, 300]

trauma_percent:
  - 10: "Low (minor injuries)"
  - 30: "Medium (moderate injuries)"
  - 50: "High (serious injuries)"
  - 80: "Very High (severe injuries)"

group_params:
  - your_team_count: 1-10
  - your_team_level_min: 1-100
  - your_team_level_max: 1-100
  - enemy_team_count: 1-10
  - enemy_team_level_min: 1-100
  - enemy_team_level_max: 1-100
  - wait_time_minutes: [5, 10, 15, 30, 45, 60]
```

## Domain Models

### Existing Models
- `ArenaMatch` — Match metadata, status, spectator codes, broadcast channels
- `ArenaSeason` — Seasonal rankings and rewards periods
- `ArenaParticipation` — Per-character match results and rating changes
- `ArenaTournament` — Bracket-based competition structure
- `ArenaRanking` — Leaderboard positions

### New Models to Add

#### `ArenaRoom`
```ruby
# Room within arena complex with level/faction restrictions
class ArenaRoom < ApplicationRecord
  belongs_to :zone
  has_many :arena_matches

  enum :room_type, {
    training: 0, trial: 1, challenge: 2, initiation: 3,
    patron: 4, law: 5, light: 6, balance: 7, chaos: 8, dark: 9
  }

  validates :name, :level_min, :level_max, presence: true

  def accessible_by?(character)
    character.level.between?(level_min, level_max) &&
      (faction.nil? || character.faction == faction)
  end
end
```

#### `ArenaApplication`
```ruby
# Fight request/application waiting for opponents
class ArenaApplication < ApplicationRecord
  belongs_to :arena_room
  belongs_to :applicant, class_name: "Character"

  enum :fight_type, { duel: 0, group: 1, sacrifice: 2, tactical: 3 }
  enum :fight_kind, {
    no_weapons: 0, no_artifacts: 1, limited_artifacts: 2,
    free: 3, clan_vs_clan: 4, faction_vs_faction: 5,
    clan_vs_all: 6, faction_vs_all: 7, closed: 8
  }
  enum :status, { open: 0, matched: 1, started: 2, expired: 3, cancelled: 4 }

  validates :timeout_seconds, inclusion: { in: [120, 180, 240, 300] }
  validates :trauma_percent, inclusion: { in: [10, 30, 50, 80] }

  # Group fight parameters
  store_accessor :group_params, :team_count, :team_level_min, :team_level_max,
                 :enemy_count, :enemy_level_min, :enemy_level_max, :wait_minutes

  scope :available_for, ->(character) {
    open.where("level_min <= ? AND level_max >= ?", character.level, character.level)
  }

  def time_until_start
    return nil unless matched?
    [starts_at - Time.current, 0].max
  end
end
```

## Services & Workflows

### `Arena::ApplicationHandler`
Manages fight application lifecycle:
```ruby
class Arena::ApplicationHandler
  def create(character:, room:, params:)
    # Validate character can access room
    # Check for existing applications
    # Create ArenaApplication
    # Broadcast to arena channel
  end

  def accept(application:, acceptor:)
    # Validate acceptor eligibility
    # Match application -> create ArenaMatch
    # Start countdown timer
    # Notify all participants via ActionCable
  end

  def cancel(application:)
    # Remove from queue
    # Broadcast cancellation
  end
end
```

### `Arena::Matchmaker`
Auto-matches compatible applications:
```ruby
class Arena::Matchmaker
  def find_matches(room:)
    # Group open applications by fight_type
    # Match compatible level ranges
    # Create ArenaMatch for matched pairs/groups
    # Trigger countdown
  end

  def check_eligibility(character, application)
    return false if character.level < application.level_min
    return false if character.level > application.level_max
    return false if application.closed? && !invited?(character)
    return false if faction_restricted?(application) && !faction_match?(character)
    true
  end
end
```

### `Arena::CombatBroadcaster`
Real-time fight updates via ActionCable:
```ruby
class Arena::CombatBroadcaster
  def broadcast_countdown(match, seconds_remaining)
    ActionCable.server.broadcast(
      match.broadcast_channel,
      { type: "countdown", seconds: seconds_remaining }
    )
  end

  def broadcast_action(match, action)
    ActionCable.server.broadcast(
      match.broadcast_channel,
      { type: "combat_action", action: action.to_broadcast }
    )
  end

  def broadcast_result(match, result)
    ActionCable.server.broadcast(
      match.broadcast_channel,
      { type: "match_result", result: result }
    )
  end
end
```

## Controllers & Routes

### `ArenaController`
```ruby
resources :arena, only: [:index, :show] do
  resources :rooms, only: [:show], controller: "arena_rooms" do
    resources :applications, only: [:create, :destroy], controller: "arena_applications"
    post :accept_application, on: :member
  end
  resources :matches, only: [:show], controller: "arena_matches" do
    get :spectate, on: :member
    get :log, on: :member
  end
end
```

## Frontend Components

### Stimulus Controllers

#### `arena_controller.js`
Main arena interface:
```javascript
export default class extends Controller {
  static targets = ["rooms", "applications", "countdown", "matchArea"]
  static values = { roomId: Number, refreshInterval: { type: Number, default: 5000 } }

  connect() {
    this.subscribeToArena()
    this.startRefresh()
  }

  // Room navigation (building schema view)
  showRooms() { /* Toggle room grid visibility */ }
  selectRoom(event) { /* Navigate to room, check accessibility */ }

  // Application management
  submitApplication(event) { /* POST new fight application */ }
  acceptApplication(event) { /* Accept existing application */ }
  cancelApplication(event) { /* Cancel own application */ }

  // Fight countdown
  startCountdown(seconds) {
    this.countdownTarget.classList.add("visible")
    this.updateCountdown(seconds)
  }

  updateCountdown(seconds) {
    if (seconds <= 0) {
      this.countdownTarget.textContent = "FIGHT!"
      return
    }
    const mins = Math.floor(seconds / 60)
    const secs = seconds % 60
    this.countdownTarget.textContent = mins > 0
      ? `${mins} min ${secs} sec`
      : `${secs} seconds`
    setTimeout(() => this.updateCountdown(seconds - 1), 1000)
  }
}
```

#### `arena_match_controller.js`
Live combat view:
```javascript
export default class extends Controller {
  static targets = ["combatLog", "participantList", "actionButtons", "timer"]
  static values = { matchId: Number, spectating: Boolean }

  connect() {
    this.channel = consumer.subscriptions.create(
      { channel: "ArenaMatchChannel", match_id: this.matchIdValue },
      { received: (data) => this.handleBroadcast(data) }
    )
  }

  handleBroadcast(data) {
    switch(data.type) {
      case "countdown": this.updateTimer(data.seconds); break
      case "combat_action": this.appendCombatLog(data.action); break
      case "match_result": this.showResult(data.result); break
      case "hp_update": this.updateParticipantHP(data); break
    }
  }

  appendCombatLog(action) {
    const entry = document.createElement("div")
    entry.className = `combat-log-entry combat-log--${action.type}`
    entry.innerHTML = this.formatAction(action)
    this.combatLogTarget.appendChild(entry)
    this.scrollToBottom()
  }

  formatAction(action) {
    // Format: [Time] Attacker deals X damage to Defender (HP: Y/Z)
    return `<span class="combat-time">${action.timestamp}</span>
            <span class="combat-actor">${action.actor_name}</span>
            ${action.description}
            <span class="combat-result">${action.result}</span>`
  }
}
```

### CSS Styles (Neverlands-Inspired)

```css
/* Arena room grid */
.arena-rooms {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 4px;
}

.arena-room {
  padding: var(--nl-space-md);
  text-align: center;
  border: 1px solid var(--nl-border-medium);
  transition: all 0.2s;
}

.arena-room--available { background: #EEF5FF; cursor: pointer; }
.arena-room--unavailable { background: #f0f0f0; opacity: 0.6; }
.arena-room--current { background: #EAEAEA; border-color: var(--nl-gold); }
.arena-room--faction-light { border-left: 3px solid #FFD700; }
.arena-room--faction-dark { border-left: 3px solid #4B0082; }
.arena-room--faction-chaos { border-left: 3px solid #DC143C; }
.arena-room--faction-law { border-left: 3px solid #4169E1; }

/* Fight application list */
.arena-application {
  display: flex;
  align-items: center;
  gap: var(--nl-space-sm);
  padding: var(--nl-space-sm);
  background: var(--nl-bg-primary);
  border-bottom: 1px solid var(--nl-border-light);
}

.arena-application--own {
  background: rgba(255, 215, 0, 0.1);
  border-left: 3px solid var(--nl-gold);
}

.arena-application-info {
  flex: 1;
}

.arena-application-timer {
  font-size: 0.85rem;
  color: var(--nl-text-secondary);
}

.arena-application-timer--urgent {
  color: #CC0000;
  font-weight: bold;
}

/* Combat log */
.combat-log {
  max-height: 400px;
  overflow-y: auto;
  font-family: monospace;
  font-size: 0.9rem;
  background: #1a1a1a;
  color: #e0e0e0;
  padding: var(--nl-space-sm);
}

.combat-log-entry {
  padding: 2px 0;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.combat-log--damage { color: #ff6b6b; }
.combat-log--heal { color: #69db7c; }
.combat-log--buff { color: #74c0fc; }
.combat-log--debuff { color: #da77f2; }
.combat-log--critical { color: #ffd43b; font-weight: bold; }
.combat-log--miss { color: #868e96; font-style: italic; }
.combat-log--system { color: #adb5bd; }

.combat-time {
  color: #868e96;
  margin-right: 8px;
}

.combat-actor {
  font-weight: bold;
  color: #74c0fc;
}

/* Countdown overlay */
.arena-countdown {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background: rgba(0,0,0,0.9);
  border: 3px solid var(--nl-gold);
  padding: var(--nl-space-xl);
  text-align: center;
  z-index: 1000;
  min-width: 300px;
}

.arena-countdown-title {
  color: var(--nl-gold);
  font-size: 1.2rem;
  margin-bottom: var(--nl-space-sm);
}

.arena-countdown-timer {
  font-size: 2.5rem;
  font-weight: bold;
  color: #fff;
  font-family: monospace;
}

.arena-countdown-timer--final {
  color: #ff6b6b;
  animation: pulse 0.5s infinite;
}

/* Participant HP bars */
.arena-participant {
  display: flex;
  align-items: center;
  gap: var(--nl-space-sm);
  padding: var(--nl-space-xs);
}

.arena-participant--team-a { border-left: 3px solid #74c0fc; }
.arena-participant--team-b { border-left: 3px solid #ff6b6b; }

.arena-hp-bar {
  width: 100px;
  height: 8px;
  background: #2a2a2a;
  border-radius: 4px;
  overflow: hidden;
}

.arena-hp-fill {
  height: 100%;
  background: linear-gradient(90deg, #ff6b6b 0%, #69db7c 100%);
  transition: width 0.3s;
}

.arena-mp-bar {
  width: 100px;
  height: 6px;
  background: #2a2a2a;
  border-radius: 3px;
  overflow: hidden;
}

.arena-mp-fill {
  height: 100%;
  background: #74c0fc;
  transition: width 0.3s;
}
```

## ActionCable Channels

### `ArenaChannel`
Global arena updates (applications, room changes):
```ruby
class ArenaChannel < ApplicationCable::Channel
  def subscribed
    stream_from "arena:lobby"
    stream_from "arena:room:#{params[:room_id]}" if params[:room_id]
  end
end
```

### `ArenaMatchChannel`
Per-match combat updates:
```ruby
class ArenaMatchChannel < ApplicationCable::Channel
  def subscribed
    @match = ArenaMatch.find(params[:match_id])
    stream_from @match.broadcast_channel
  end

  def submit_action(data)
    return if @match.completed?
    Arena::CombatProcessor.process(
      match: @match,
      character: current_character,
      action: data["action"]
    )
  end
end
```

## Testing

### Request Specs
```ruby
RSpec.describe "Arena Applications", type: :request do
  it "creates a duel application" do
    post arena_room_applications_path(room), params: {
      fight_type: "duel",
      fight_kind: "free",
      timeout: 180,
      trauma_percent: 30
    }
    expect(response).to have_http_status(:created)
  end

  it "prevents low-level players from high-level rooms" do
    room = create(:arena_room, level_min: 20, level_max: 30)
    character = create(:character, level: 5)

    post arena_room_applications_path(room)
    expect(response).to have_http_status(:forbidden)
  end
end
```

---

## Responsible for Implementation Files
- **Models:** `app/models/arena_match.rb`, `app/models/arena_season.rb`, `app/models/arena_participation.rb`, `app/models/arena_room.rb` (new), `app/models/arena_application.rb` (new)
- **Services:** `app/services/arena/application_handler.rb`, `app/services/arena/matchmaker.rb`, `app/services/arena/combat_broadcaster.rb`, `app/services/arena/combat_processor.rb`, `app/services/arena/reward_job.rb`
- **Controllers:** `app/controllers/arena_controller.rb`, `app/controllers/arena_rooms_controller.rb`, `app/controllers/arena_applications_controller.rb`, `app/controllers/arena_matches_controller.rb`
- **Channels:** `app/channels/arena_channel.rb`, `app/channels/arena_match_channel.rb`
- **Frontend:** `app/javascript/controllers/arena_controller.js`, `app/javascript/controllers/arena_match_controller.js`, `app/javascript/channels/arena_channel.js`
- **Views:** `app/views/arena/*`, `app/views/arena_rooms/*`, `app/views/arena_matches/*`
- **Config:** `config/routes.rb`, `db/seeds.rb` (arena rooms)

