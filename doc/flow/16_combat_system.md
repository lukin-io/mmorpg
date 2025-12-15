# Combat System - Flow Documentation

## Version History
- **v1.0** (2024-12-01): Initial implementation
- **v1.1** (2024-12-15): Added BattleChannel for real-time HP/MP updates, combat log persistence, and battle completion handling

## Overview

The combat system implements Neverlands-inspired turn-based PvE combat with:
- Body-part targeting (head, torso, stomach, legs) for attacks and blocks
- Action point (AP) budgeting per turn
- Magic/skill slot activation
- Simultaneous turn resolution
- Detailed combat logs and statistics
- **Real-time HP/MP updates via ActionCable** (BattleChannel)
- **Persistent combat logs** (stored in `combat_log_entries` table)
- **Proper battle completion handling** with rewards display

## UI Layout

```
+------------------+--------------------+------------------+
|  PLAYER PANEL    |   CENTER PANEL     |   ENEMY PANEL    |
|                  |                    |                  |
| [HP Bar 4/5]     | [Action Icons]     | [HP Bar 90/90]   |
| [MP Bar 7/7]     |                    | [MP Bar 07/07]   |
| 96% stamina      | AP Limit: 80       | 100% stamina     |
|                  | Used: 0            |                  |
| [Avatar]         |                    | [Avatar]         |
| [Equip Slots]    | Attack Selectors:  | [Equip Slots]    |
|  - Helmet        |  Head [dropdown]   |                  |
|  - Weapon        |  Torso [dropdown]  | Stats:           |
|  - Armor         |  Body [dropdown]   |  Strength: 24    |
|  - etc.          |  Legs [dropdown]   |  Agility: 30     |
|                  |                    |  Luck: 20        |
|                  | Block Selectors:   |  Armor: 20       |
|                  |  Head [dropdown]   |  Evasion: 90%    |
|                  |  Torso [dropdown]  |  Accuracy: 90%   |
|                  |  Body [dropdown]   |  Crush: 50%      |
|                  |  Legs [dropdown]   |                  |
|                  |                    |                  |
|                  | [Turn] [Reset]     |                  |
|                  |                    |                  |
|                  | Team1 vs Team2     |                  |
|                  | Combat Log...      |                  |
+------------------+--------------------+------------------+
```

## File Structure

### Controllers
- `app/controllers/combat_controller.rb` - Main combat controller
  - `show` - Display active battle (loads persisted combat logs)
  - `start` - Start combat with NPC
  - `action` - Process turn actions (renders `_result` partial on battle completion)
  - `flee` - Attempt to escape

### Services
- `app/services/game/combat/pve_encounter_service.rb` - PvE encounter management
  - `start_encounter!` - Creates battle and broadcasts `combat_started`
  - `process_turn!` - Resolves round and broadcasts `round_complete`
  - `complete_battle!` - Marks battle as completed and broadcasts `combat_ended`
  - `persist_log_entry!` - Saves combat log entries to database
- `app/services/game/combat/turn_based_combat_service.rb` - Turn resolution
- `app/services/game/combat/turn_resolver.rb` - Attack/damage calculation
- `app/services/game/combat/skill_executor.rb` - Skill execution
- `app/services/game/combat/log_writer.rb` - Combat log generation
- `app/services/game/combat/post_battle_processor.rb` - Rewards, XP

### Channels
- `app/channels/battle_channel.rb` - Real-time battle updates
  - Streams `battle:#{battle_id}` for round_complete, vitals_update, combat_ended events
  - `request_state` action returns current battle state (turn, participants, logs)
  - Only allows subscriptions for battle participants

### Views
- `app/views/combat/show.html.erb` - Combat page
- `app/views/combat/_battle.html.erb` - Main battle layout (includes `characterId` data attribute)
- `app/views/combat/_nl_participant.html.erb` - Player/enemy display
- `app/views/combat/_nl_action_selection.html.erb` - Attack/block selectors
- `app/views/combat/_nl_magic_slots.html.erb` - Skill slots
- `app/views/combat/_nl_combat_log.html.erb` - Combat log display
- `app/views/combat/_nl_log_entries.html.erb` - New log entries (with dynamic CSS classes)
- `app/views/combat/_nl_group_display.html.erb` - Team display
- `app/views/combat/_result.html.erb` - Battle result screen (XP, gold, item rewards)

### JavaScript
- `app/javascript/controllers/turn_combat_controller.js` - Stimulus controller
  - Subscribes to `BattleChannel` and `VitalsChannel`
  - Handles `round_complete`, `vitals_update`, `combat_ended` events
  - Updates participant HP/MP bars in real-time
  - Displays battle results with "Return to World" button
- `app/javascript/controllers/pve_combat_controller.js` - PvE-specific logic

## Combat Flow

### 1. Start Combat
```
Player clicks "Attack" on NPC
  → POST /combat/start {npc_template_id}
  → PveEncounterService.start_encounter!
    → Create Battle record
    → Create BattleParticipant for player
    → Create BattleParticipant for NPC
    → Broadcast combat started
  → Redirect to /combat
```

### 2. Combat Round
```
Player selects actions:
  - Choose attacks (0-4 body parts)
  - Choose blocks (0-1 body part)
  - Activate skills (optional)

Player clicks "Submit Turn"
  → POST /combat/action {action_type: :turn, attacks: [...], blocks: [...], skills: [...]}
  → PveEncounterService.process_turn!
    → Validate action points
    → Queue player actions
    → Generate NPC actions (AI)
    → TurnBasedCombatService.resolve_round!
      → Process skills (buffs, heals)
      → Process attacks (hit/miss/block/crit)
      → Apply damage
      → Check for death
    → Update combat log
  → Turbo Stream update UI
```

### 3. Battle End
```
When participant HP <= 0:
  → Battle.status = :completed
  → PostBattleProcessor.process!
    → Calculate rewards (XP, gold, items)
    → Update character stats
    → Respawn NPC (if applicable)
  → Render _result.html.erb
```

## Action Point System

| Action | AP Cost |
|--------|---------|
| Simple Attack | 0 |
| Aimed Attack | 20 |
| Basic Block | 30 |
| Shield Block | 40 |
| Special Skills | 45-150 |

**Multi-Attack Penalty:**
- 1 attack: 0 AP penalty
- 2 attacks: 25 AP penalty
- 3 attacks: 75 AP penalty
- 4 attacks: 150 AP penalty

## Body Part Targeting

| Body Part | Damage Multiplier | Block Effectiveness |
|-----------|-------------------|---------------------|
| Head | 1.5x | 60% |
| Torso | 1.0x | 80% |
| Stomach | 1.2x | 50% |
| Legs | 0.8x | 70% |

## Combat Calculations

### Hit Chance
```ruby
base_hit_chance = 85
modified_hit = base_hit_chance + attacker.accuracy - defender.evasion
roll = rand(100)
hit = roll < modified_hit
```

### Block Chance
```ruby
if defender.blocking?(body_part)
  block_chance = body_part_config[body_part]["block_effectiveness"]
  blocked = rand(100) < block_chance
  damage = blocked ? damage * 0.2 : damage
end
```

### Damage Formula
```ruby
base_damage = attacker.strength * weapon_multiplier
critical = rand(100) < critical_chance ? 1.5 : 1.0
body_multiplier = body_part_config[body_part]["damage_multiplier"]
armor_reduction = defender.armor / 100.0
final_damage = (base_damage * critical * body_multiplier * (1 - armor_reduction)).round
```

## CSS Theme (Neverlands-Style)

All combat CSS uses the `.nl-combat-*` prefix and CSS variables defined in `.nl-combat-container`:

### Color Variables
```css
--combat-bg-white: #FFFFFF;
--combat-bg-light: #FAFAFA;
--combat-bg-cream: #FCFAF3;
--combat-bg-gray: #F5F5F5;
--combat-border: #CCCCCC;
--combat-border-gold: #DECFA6;
--combat-border-dark: #665B48;
--combat-gold: #A29275;
--combat-text: #222222;
--combat-text-dim: #888888;
--combat-text-muted: #556680;
--combat-link: #336699;
--combat-red: #CC0000;
--combat-green: #148101;
--combat-blue: #0052A6;       /* Player name color */
--combat-blue-enemy: #087C20; /* Enemy name color */
```

### HP/MP Bars
- HP Bar: Cyan gradient `#7FD4D4 → #4FC8C8 → #7FD4D4`
- MP Bar: Blue gradient `#6699CC → #4477AA → #6699CC`
- Empty bar: Light gray `#E0E0E0`
- Critical HP: Red gradient with pulse animation

### Typography
- Font Family: `Verdana, Tahoma, Arial, sans-serif`
- Base Font Size: `12px`
- Combat log: `11px`
- Timestamps: `10px` monospace

## Real-Time Updates

### ActionCable (BattleChannel)
Combat uses ActionCable for real-time HP/MP and log updates:

```ruby
# Server broadcasts to battle channel
ActionCable.server.broadcast("battle:#{battle_id}", {
  type: "round_complete",
  battle_id: battle_id,
  turn: battle.current_turn,
  combat_log: [message],
  participants: {
    participant_id => { current_hp: hp, current_mp: mp, max_hp: max_hp, max_mp: max_mp }
  }
})
```

```javascript
// Client subscribes in turn_combat_controller.js
this.battleSubscription = consumer.subscriptions.create(
  { channel: "BattleChannel", battle_id: this.battleIdValue },
  { received: (data) => this.handleBattleUpdate(data) }
)
```

### Turbo Stream Updates
Combat also uses Turbo Streams for form responses:
```ruby
turbo_stream.update("participant-#{id}", partial: "combat/nl_participant", ...)
turbo_stream.append("nl-log-table", partial: "combat/nl_log_entries", ...)
turbo_stream.replace("nl-combat-container", partial: "combat/result", ...) # On battle end
```

### Combat Log Persistence
Combat logs are persisted to `combat_log_entries` table for page reload support:
```ruby
CombatLogEntry.create!(
  battle: battle,
  participant: participant,
  log_type: :attack | :damage | :block | :heal | :buff | :death | :victory | :defeat,
  message: "Warrior attacks Bandit Scout for 15 damage",
  damage_amount: 15,
  round_number: battle.current_turn
)
```

## Testing

### Request Specs
- `spec/requests/combat_spec.rb`
  - Combat action processing
  - Battle completion via Turbo Stream (replaces `nl-combat-container` with result)
  - Victory/defeat scenarios

### Channel Specs
- `spec/channels/battle_channel_spec.rb`
  - Subscription confirmation for battle participants
  - Rejection for non-participants/invalid battles
  - `request_state` action transmits battle state (turn, HP/MP, logs)

### Service Specs
- `spec/services/game/combat/pve_encounter_service_spec.rb`
  - Turn processing with attacks and blocks
  - Combat log persistence on battle completion
  - ActionCable broadcasts (round_complete, combat_ended)
- `spec/services/game/combat/turn_based_combat_service_spec.rb`
- `spec/services/game/combat/turn_resolver_spec.rb`

### System Specs
- `spec/system/combat_spec.rb`

## Responsible Implementation Files

| Type | Path |
|------|------|
| Controller | `app/controllers/combat_controller.rb` |
| Channel | `app/channels/battle_channel.rb` |
| Service | `app/services/game/combat/*.rb` |
| Model | `app/models/battle.rb`, `app/models/battle_participant.rb`, `app/models/combat_log_entry.rb` |
| Views | `app/views/combat/_*.html.erb` |
| JavaScript | `app/javascript/controllers/turn_combat_controller.js` |
| CSS | `app/assets/stylesheets/application.css` (nl-combat-* classes) |
| Specs | `spec/requests/combat_spec.rb`, `spec/channels/battle_channel_spec.rb`, `spec/services/game/combat/*_spec.rb` |

