# Combat System - Flow Documentation

## Overview

The combat system implements Neverlands-inspired turn-based PvE combat with:
- Body-part targeting (head, torso, stomach, legs) for attacks and blocks
- Action point (AP) budgeting per turn
- Magic/skill slot activation
- Simultaneous turn resolution
- Detailed combat logs and statistics

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
  - `show` - Display active battle
  - `start` - Start combat with NPC
  - `action` - Process turn actions
  - `flee` - Attempt to escape

### Services
- `app/services/game/combat/pve_encounter_service.rb` - PvE encounter management
- `app/services/game/combat/turn_based_combat_service.rb` - Turn resolution
- `app/services/game/combat/turn_resolver.rb` - Attack/damage calculation
- `app/services/game/combat/skill_executor.rb` - Skill execution
- `app/services/game/combat/log_writer.rb` - Combat log generation
- `app/services/game/combat/post_battle_processor.rb` - Rewards, XP

### Views
- `app/views/combat/show.html.erb` - Combat page
- `app/views/combat/_battle.html.erb` - Main battle layout
- `app/views/combat/_nl_participant.html.erb` - Player/enemy display
- `app/views/combat/_nl_action_selection.html.erb` - Attack/block selectors
- `app/views/combat/_nl_magic_slots.html.erb` - Skill slots
- `app/views/combat/_nl_combat_log.html.erb` - Combat log display
- `app/views/combat/_nl_group_display.html.erb` - Team display
- `app/views/combat/_result.html.erb` - Battle result screen

### JavaScript
- `app/javascript/controllers/turn_combat_controller.js` - Stimulus controller
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

## Turbo Stream Updates

Combat uses Turbo Streams for real-time updates:
```ruby
turbo_stream.update("participant-1", partial: "combat/nl_participant", ...)
turbo_stream.update("participant-2", partial: "combat/nl_participant", ...)
turbo_stream.append("nl-log-table", partial: "combat/nl_log_entries", ...)
```

## Testing

### Request Specs
- `spec/requests/combat_spec.rb`

### Service Specs
- `spec/services/game/combat/pve_encounter_service_spec.rb`
- `spec/services/game/combat/turn_based_combat_service_spec.rb`
- `spec/services/game/combat/turn_resolver_spec.rb`

### System Specs
- `spec/system/combat_spec.rb`

## Responsible Implementation Files

| Type | Path |
|------|------|
| Controller | `app/controllers/combat_controller.rb` |
| Service | `app/services/game/combat/*.rb` |
| Model | `app/models/battle.rb`, `app/models/battle_participant.rb` |
| Views | `app/views/combat/_*.html.erb` |
| JavaScript | `app/javascript/controllers/turn_combat_controller.js` |
| CSS | `app/assets/stylesheets/application.css` (nl-combat-* classes) |
| Specs | `spec/requests/combat_spec.rb`, `spec/services/game/combat/*_spec.rb` |

