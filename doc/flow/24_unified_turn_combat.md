# Unified Turn-Based Combat System

## Version History
- **v1.0** (2025-12-29): Initial implementation with body-part targeting, action points, and simultaneous turn resolution
- **v1.1** (2025-12-29): Added PVP integration, magic/skills UI, comprehensive system specs, dual route support (/battles and /pvp_combat)
- **v1.2** (2025-12-29): Documented passive skill integration with combat formulas, added gap analysis reference
- **v1.3** (2025-12-29): Complete skills-combat integration:
  - All resistance skills now apply via ResistanceFormula
  - Magic skills (elemental_magic, healing_arts) apply in SkillExecutor
  - Mana skills (arcane_power, spell_mastery) apply via Character model
  - NPC passive skill levels supported
  - Skill prerequisites system implemented
  - Perks system with mutual exclusions

## Overview

The Unified Turn-Based Combat System provides a single, consistent combat experience for all battle types:
- **PvE Combat** (Player vs NPC)
- **PvP Combat** (Player vs Player)
- **Arena Combat** (Matchmaking-based, ranked)

All combat types use the same core mechanics, formulas, and UI components. The only difference is the opponent type and matchmaking method.

## GDD Reference
- Section: `doc/gdd.md#combat-system`
- Feature spec: `doc/features/neverlands_inspired_combat.md`
- Arena spec: `doc/flow/11_arena_pvp.md`

---

## Core Mechanics

### Action Points (AP)

Each turn has an AP budget (default: 80). Players allocate AP across:
- **Attacks**: 45-60 AP per attack
- **Blocks**: 30 AP per block
- **Skills/Magic**: 40-100 AP depending on power

#### Multi-Attack Penalty
| Attacks | Penalty |
|---------|---------|
| 1 | +0 AP |
| 2 | +25 AP |
| 3 | +75 AP |
| 4 | +150 AP |

### Body Part Targeting

Four target zones with damage modifiers:
| Body Part | Damage Multiplier | Notes |
|-----------|-------------------|-------|
| Head | 1.3x | Harder to hit (+10% miss), higher crit |
| Torso | 1.0x | Standard |
| Stomach | 1.1x | Slightly easier to hit |
| Legs | 0.9x | Movement penalties on damage |

#### Attack Exclusivity Rules
- **Cannot attack Head + Legs in the same turn** (diagonal ban)
- Maximum 4 attacks per turn

### Blocking
- **Single block per turn** - choose one body part to protect
- Blocks can fully negate or reduce damage depending on roll
- Magic shields provide higher damage reduction

### Combat Flow
1. Both players select actions (attacks, blocks, skills)
2. Submit turn when ready
3. When all participants ready → simultaneous resolution
4. Damage, effects, and logs calculated deterministically
5. Repeat until one team eliminated

---

## Implementation Architecture

### Core Formulas (Deterministic)

All combat calculations use seeded RNG for replay capability.

```
app/lib/game/formulas/
├── hit_formula.rb          # Hit chance calculation
├── block_formula.rb        # Block effectiveness
├── critical_formula.rb     # Critical hit chance & multiplier
├── dodge_formula.rb        # Dodge/evasion mechanics
└── combat_damage_formula.rb # Unified damage calculation
```

#### Hit Formula
```ruby
hit_chance = BASE_HIT_CHANCE           # 85%
  + (attacker.accuracy * 0.5)          # Accuracy bonus
  + (attacker.dexterity * 0.3)         # Dexterity bonus
  - (defender.evasion * 0.4)           # Evasion penalty
  - (defender.agility * 0.2)           # Agility penalty
  + BODY_PART_MODIFIER                  # Head: -10%, Legs: -5%
  + ACTION_TYPE_MODIFIER                # Aimed: +15%, Power: -10%
  + SKILL_BONUSES                       # Melee, Evasion skills

# Clamped to 5-95%
```

#### Critical Formula
```ruby
crit_chance = BASE_CRIT_CHANCE         # 10%
  + (attacker.luck * 0.3)              # Luck bonus
  + attacker.critical_chance           # Direct stat
  - (defender.luck * 0.15)             # Defender luck
  + BODY_PART_MODIFIER                  # Head: +5%
  + ACTION_TYPE_MODIFIER                # Aimed: +10%
  + SKILL_BONUSES                       # Critical Strikes skill

# Clamped to 1-50%
# Base multiplier: 1.5x (+0.2x for head, +0.5x from skills)
```

### Combat Engine Classes

```
app/lib/game/combat/
├── action_validator.rb     # Validates turn actions
├── turn_resolver.rb        # Resolves combat turns
├── effect.rb               # Combat effect (buff/debuff)
└── effects_registry.rb     # All effect definitions
```

### Services

```
app/services/game/combat/
├── unified_combat_service.rb   # Main combat orchestration
├── turn_based_combat_service.rb # Legacy combat (still used)
└── pvp_encounter_service.rb     # PvP-specific logic
```

### Models

```
app/models/
├── battle.rb               # Combat session
└── battle_participant.rb   # Combatant in a battle
```

#### Battle Model Fields
```ruby
# Combat settings
combat_mode: "simultaneous" | "sequential"
action_points_per_turn: 80
max_mana_per_turn: 50
turn_timeout_seconds: 300

# State
turn_number: 1
round_number: 1
status: :pending | :active | :completed
winning_team: "alpha" | "beta"

# Determinism
rng_seed: integer
```

#### BattleParticipant Fields
```ruby
# Vitals
current_hp: integer
max_hp: integer
current_mp: integer
max_mp: integer
is_alive: boolean

# Actions
pending_attacks: jsonb    # [{body_part:, action_key:}]
pending_blocks: jsonb     # [{body_part:, action_key:}]
pending_skills: jsonb     # [{key:, target_id:}]
turn_submitted_at: datetime

# Effects & Stats
active_effects: jsonb     # [{type:, name:, duration:, ...}]
body_damage: jsonb        # Damage per body part
fatigue: decimal
```

---

## UI Components

### Stimulus Controller

```javascript
// app/javascript/controllers/combat_turn_controller.js

// Features:
// - Real-time AP tracking
// - Multi-attack penalty calculation
// - Attack exclusivity enforcement
// - Single block rule
// - Turn timer countdown
// - WebSocket updates via BattleChannel
```

### View Partials

```erb
app/views/combat/
├── _turn_combat_interface.html.erb  # Main combat UI
├── _battle_complete.html.erb        # Victory screen
└── _battle_defeat.html.erb          # Defeat screen
```

### Turbo Streams

```erb
app/views/battles/
├── submit_turn.turbo_stream.erb
├── flee.turbo_stream.erb
└── surrender.turbo_stream.erb
```

---

## Combat Effects System

### Effect Types
- **DOT** (Damage Over Time): Poison, Burn, Bleed
- **HOT** (Heal Over Time): Regeneration
- **Shield/Barrier**: Damage reduction
- **Buff**: Stat increases
- **Debuff**: Stat decreases
- **Stun**: Prevents action

### Effect Registry

Predefined effects in `Game::Combat::EffectsRegistry`:
```ruby
# Example effects:
poison: { type: :dot, duration: 3, damage_per_turn: 5 }
burn: { type: :dot, duration: 2, damage_per_turn: 8 }
regeneration: { type: :hot, duration: 5, heal_per_turn: 10 }
magic_shield: { type: :shield, duration: 2, damage_reduction: 0.3 }
berserker: { type: :buff, duration: 3, stat_changes: { strength: 15, defense: -10 } }
```

---

## Hotwire Integration

### Turbo Frames
- `#combat-interface` - Main combat area
- `#combat-log` - Combat log updates
- `#hp-bars` - Participant HP/MP displays

### Turbo Streams
- Round resolution results
- Vitals updates
- Effect applications
- Battle end announcements

### Stimulus Controllers
- `combat_turn_controller` - Action selection and validation
- ActionCable integration for real-time updates

---

## Passive Skills Integration

> **Full Documentation**: See `doc/flow/25_skills_combat_integration.md` for complete skill-combat integration details.

Combat formulas actively integrate with the passive skill system from `Game::Skills::PassiveSkillRegistry`.

### Combat Skills (All Implemented ✅)

| Skill | Formula/Service | Effect at Max Level |
|-------|---------|---------------------|
| `melee_combat` | HitFormula, TurnResolver | +10% hit, +50% damage |
| `ranged_combat` | HitFormula | +5% hit chance |
| `critical_strikes` | CriticalFormula | +15% crit chance, +0.5x multiplier |
| `evasion` | HitFormula, DodgeFormula | -8% enemy hit, +20% dodge |
| `block_mastery` | BlockFormula | +25% block chance |

### Magic Skills (All Implemented ✅)

| Skill | Formula/Service | Effect at Max Level |
|-------|---------|---------------------|
| `elemental_magic` | SkillExecutor | +50% spell damage |
| `healing_arts` | SkillExecutor | +40% healing effectiveness |
| `arcane_power` | Character#effective_max_mp | +30% max mana |
| `spell_mastery` | Character#reduced_mana_cost | -25% mana cost |

### Resistance Skills (All Implemented ✅)

| Skill | Formula | Effect at Max Level |
|-------|---------|---------------------|
| `fire_resistance` | ResistanceFormula | Reduces fire damage |
| `cold_resistance` | ResistanceFormula | Reduces cold/ice damage |
| `lightning_resistance` | ResistanceFormula | Reduces lightning damage |
| `physical_fortitude` | ResistanceFormula | Reduces physical damage |

### Integration Code Flow

```
Character.passive_skill_level(:melee_combat)
    │
    ▼
PassiveSkillRegistry.calculate_effect(:melee_combat, level)
    │
    ▼
Combat Formulas/Services apply bonus:
  - HitFormula (accuracy)
  - CriticalFormula (crit chance)
  - BlockFormula (block effectiveness)
  - ResistanceFormula (damage reduction)
  - SkillExecutor (spell power, healing)
    │
    ▼
TurnResolver logs skill bonuses in combat log
```

### Mana System Integration

```ruby
# Character model methods
character.effective_max_mp       # Base max_mp + arcane_power bonus
character.reduced_mana_cost(20)  # 20 - spell_mastery reduction
character.has_mana?(cost)        # Check with reduction applied
character.spend_mana!(cost)      # Spend with reduction
character.regenerate_mana!       # 5% of effective_max_mp per tick
```

### NPC Skill Integration

NPCs support passive skill levels via `NpcTemplate#passive_skill_level`:
```ruby
npc_template.passive_skill_level(:melee_combat)
# => Reads from metadata["passive_skills"] or defaults to (level / 2)
```

### Skill Prerequisites

Some skills require other skills at certain levels:

| Skill | Prerequisite |
|-------|--------------|
| `critical_strikes` | Melee Combat 30 OR Ranged Combat 30 |
| `block_mastery` | Evasion 20 |
| `healing_arts` | Elemental Magic 30 |
| `spell_mastery` | Arcane Power 20 |

Check with `Character#skill_prerequisites_met?(skill)` or `PassiveSkillRegistry.can_spend?(skill, character)`.
| `physical_fortitude` | ❌ Not applied | Physical damage reduction |
| `arcane_power` | ❌ Not applied | Max MP calculation |

---

## Test Coverage

### Formula Specs
```
spec/lib/game/formulas/
├── hit_formula_spec.rb
├── block_formula_spec.rb
├── critical_formula_spec.rb
└── dodge_formula_spec.rb
```

### Service Specs
```
spec/lib/game/combat/
├── action_validator_spec.rb
├── turn_resolver_spec.rb
└── unified_combat_service_spec.rb
```

### System Specs
```
spec/system/
├── combat_turn_interface_spec.rb        # Unit-level UI tests
└── pvp_two_player_combat_ui_spec.rb     # Two-player PVP UI tests
```

---

## Responsible for Implementation Files

### Models
- `app/models/battle.rb`
- `app/models/battle_participant.rb`

### Controllers
- `app/controllers/battles_controller.rb` - Unified battle controller (show, submit_turn, flee, surrender)
- `app/controllers/pvp_combat_controller.rb` - PvP-specific controller with legacy routes

### Game Engine
- `app/lib/game/formulas/hit_formula.rb`
- `app/lib/game/formulas/block_formula.rb`
- `app/lib/game/formulas/critical_formula.rb`
- `app/lib/game/formulas/dodge_formula.rb`
- `app/lib/game/combat/action_validator.rb`
- `app/lib/game/combat/turn_resolver.rb`
- `app/lib/game/combat/effect.rb`
- `app/lib/game/combat/effects_registry.rb`

### Services
- `app/services/game/combat/unified_combat_service.rb`

### Views
- `app/views/battles/show.html.erb`
- `app/views/battles/submit_turn.turbo_stream.erb`
- `app/views/battles/flee.turbo_stream.erb`
- `app/views/battles/surrender.turbo_stream.erb`
- `app/views/combat/_turn_combat_interface.html.erb`
- `app/views/combat/_battle_complete.html.erb`
- `app/views/combat/_battle_defeat.html.erb`

### JavaScript
- `app/javascript/controllers/combat_turn_controller.js`

### Config
- `config/gameplay/combat_actions.yml`

### Migrations
- `db/migrate/20251229000003_add_missing_combat_columns.rb`

### Specs
- `spec/lib/game/formulas/hit_formula_spec.rb`
- `spec/lib/game/formulas/block_formula_spec.rb`
- `spec/lib/game/formulas/critical_formula_spec.rb`
- `spec/lib/game/formulas/dodge_formula_spec.rb`
- `spec/lib/game/combat/action_validator_spec.rb`
- `spec/lib/game/combat/turn_resolver_spec.rb`
- `spec/services/game/combat/unified_combat_service_spec.rb`
- `spec/system/combat_turn_interface_spec.rb`
- `spec/system/pvp_two_player_combat_ui_spec.rb`

---

## Routes

### Battle Routes (Unified)
```ruby
# config/routes.rb
resources :battles, only: [:show] do
  member do
    post :submit_turn
    post :flee
    post :surrender
  end
end
```

### PvP Combat Routes (Legacy + Extended)
```ruby
resources :pvp_combat, only: [:show, :create] do
  collection do
    post :attack      # Initiate PVP attack
    get :status       # Check PVP flag status
    post :toggle_pvp  # Toggle voluntary PVP flag
  end
  member do
    post :action      # Single combat action
    post :turn        # Full turn with multiple actions
    post :flee        # Attempt to flee
    post :surrender   # Surrender the fight
  end
end
```

---

## PVP-Specific Features

### Zone Rules
PVP is only allowed when `Game::Pvp::ZoneRules.check_pvp_allowed` returns `{allowed: true}`.

### Anti-Abuse Protections
- **Newbie Protection**: Level < 10 cannot be attacked by level >= 10
- **Level Gap Cap**: Max 20 level difference
- **Repeat Kill Limit**: Max 3 kills per target per day
- **Attack Range**: Must be within 5 tiles

### PVP Flags
Players get flagged for PVP actions via `Game::Pvp::FlagService`:
- `hostile_action`: 5 minute flag after attacking
- `voluntary`: Toggle on/off manually
- `zone`: Auto-flag in PVP zones

---

## API Reference

### Starting a Battle
```ruby
result = Game::Combat::UnifiedCombatService.start_battle(
  initiator: character,
  opponent: npc_or_character,
  zone: zone,
  battle_type: :pve  # or :pvp, :arena
)
# => Result with :battle, :initiator_participant, :opponent_participant
```

### Submitting a Turn
```ruby
service = Game::Combat::UnifiedCombatService.new(battle)
result = service.submit_turn(
  participant,
  attacks: [{body_part: "head", action_key: "simple"}],
  blocks: [{body_part: "torso", action_key: "torso_block"}],
  skills: []
)
```

### Resolving a Round
```ruby
result = service.resolve_round!
# => Result with :log_entries, :hp_changes, :battle_ended, :winner_team
```

### Flee/Surrender
```ruby
service.flee(participant)
service.surrender(participant)
```

---

## Configuration

### Combat Actions (`config/gameplay/combat_actions.yml`)

```yaml
defaults:
  action_points_per_turn: 80
  max_mana_per_attack: 50

attack_types:
  simple:
    name: "Simple Attack"
    action_cost: 45
  aimed:
    name: "Aimed Attack"
    action_cost: 60

block_types:
  head_block:
    name: "Head Block"
    action_cost: 30
    body_parts: ["head"]

attack_penalties:
  - attacks: 2
    penalty: 25
  - attacks: 3
    penalty: 75
```

