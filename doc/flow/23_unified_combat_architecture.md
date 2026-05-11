# Unified Combat Architecture

## Version History
- **v1.3** (2025-12-28): Implemented 8 architectural improvements:
  - #3: Concurrency locks (row-level locking, unique index for active battles)
  - #4: VitalsService integration for damage/healing
  - #2: Locality checks (same zone, range, safe buildings)
  - #6: RNG seed persistence on Battle for deterministic replay
  - #5: Unified damage formula (`CombatDamageFormula`)
  - #7: Anti-abuse protections (newbie, level gap, repeat kill farming)
  - #8: Fixed faction alignment (alliance/rebellion/neutral)
  - #9: Normalized HP fields (current_hp canonical, hp_remaining synced)
- **v1.2** (2025-12-27): Simplified architecture - integrated with existing battle system
- **v1.1** (2025-12-26): Added comprehensive test coverage (request, system, policy specs)
- **v1.0** (2025-12-26): Initial implementation - unified combat core with PVP support

## Overview

The Elselands MMORPG uses a **unified combat architecture** built on the existing battle system. Both PVE and PVP use the same core models (`Battle`, `BattleParticipant`, `CombatLogEntry`) with specialized service classes for different combat contexts.

| Context | Attacker | Defender | Service |
|---------|----------|----------|---------|
| Open World PVE | Character | NPC | `PveEncounterService` |
| Open World PVP | Character | Character | `PvpEncounterService` |
| Arena PVE | Character | Arena Bot | `Arena::CombatProcessor` |
| Arena PVP | Character | Character | `Arena::CombatProcessor` |

Removed legacy:

- `TacticalMatch` grid combat processors were removed from the mounted/player
  arena surface because the live Neverlands capture showed `Тактические` as a
  disabled arena tab, not a separate grid route.
- Arena betting/totalizator code was removed for the same reason: the captured
  `Тотализатор` tab is a disabled label in the arena frame, not a first-loop
  player feature.

## GDD Reference
- Section: Combat System
- Feature specs: Open world combat, PVP, Arena

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                       CORE MODELS (app/models/)                            │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐│
│  │     Battle      │    │BattleParticipant│    │   CombatLogEntry        ││
│  │  (persistence)  │◄──►│ (HP, team, etc) │◄──►│   (round log)           ││
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘│
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
         ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
         │PveEncounter  │  │PvpEncounter  │  │Arena::Combat │
         │   Service    │  │   Service    │  │  Processor   │
         └──────────────┘  └──────────────┘  └──────────────┘
                │                 │                  │
         ┌──────┴───────┐  ┌──────┴───────┐  ┌──────┴───────┐
         │ Open World   │  │ Open World   │  │   Arena      │
         │ NPC Combat   │  │ PVP Combat   │  │ (PVE + PVP)  │
         └──────────────┘  └──────────────┘  └──────────────┘
```

## PVP-Specific Components

### 1. PVP Flag System

Tracks when characters are flagged for PVP combat:

```ruby
# Flag a character for PVP
flag_service = Game::Pvp::FlagService.new(character)
flag_service.enable_pvp!           # Voluntary PVP flag
flag_service.flag_for_hostile_action!(target)  # Aggressor flag

# Check PVP status
flag_service.pvp_flagged?          # => true/false
flag_service.active_flags          # => PvpFlag records
```

### 2. Zone Rules

Determines if PVP is allowed based on zone settings:

```ruby
# Check if PVP is allowed
result = Game::Pvp::ZoneRules.check_pvp_allowed(zone, attacker, defender)
# => { allowed: true, reason: "Zone allows open PVP" }
# => { allowed: false, reason: "PVP is not allowed in safe zones" }

# Zone properties used:
# - zone.pvp_enabled? (boolean)
# - zone.pvp_mode (string: "open", "arena", "battleground", "faction_war", "flagged")
# - zone.biome (string: "city" is a safe biome)
```

### 3. PVP Encounter Service

Handles player-vs-player combat using the existing battle system:

```ruby
# Start a PVP encounter
service = Game::Combat::PvpEncounterService.new(attacker, defender, zone: zone)
result = service.start_encounter!

# Process combat actions
result = service.process_action!(
  character: attacker,
  action_type: :attack,
  body_part: "head"
)

# Process full turn
result = service.process_turn!(
  character: attacker,
  attacks: [{ body_part: "head", action_key: "aimed" }],
  blocks: [{ body_part: "torso" }],
  skills: []
)
```

### 4. PVP Combat Controller

Handles UI interactions for PVP combat:

```ruby
# Routes
POST /pvp_combat/attack     # Initiate PVP attack
GET  /pvp_combat/:id        # View battle
POST /pvp_combat/:id/action # Combat action
POST /pvp_combat/:id/turn   # Full turn submission
POST /pvp_combat/:id/flee   # Flee attempt
POST /pvp_combat/:id/surrender # Surrender
GET  /pvp_combat/status     # Check PVP flag status
POST /pvp_combat/toggle_pvp # Toggle voluntary PVP
```

## Implementation Notes

### Key Design Decisions

1. **No Parallel Combat Engine**: Instead of building a separate combat core (which would drift from the existing system), PVP uses the same `Battle`, `BattleParticipant`, and `CombatLogEntry` models as PVE.

2. **Service Pattern**: Each combat context has its own service class that handles the specific rules and behaviors while reusing the core models.

3. **Zone-Based Rules**: PVP is controlled at the zone level via `pvp_enabled` and `pvp_mode` columns, plus character flagging for optional PVP in neutral zones.

4. **Deterministic Combat**: All damage calculations use the same formulas as PVE, ensuring consistent gameplay.

### Combat Flow

1. **Initiation**:
   - Controller receives attack request
   - `ZoneRules.check_pvp_allowed` validates the attack
   - `PvpEncounterService.start_encounter!` creates the battle
   - Attacker is flagged for PVP via `FlagService`

2. **Actions**:
   - Player submits action via controller
   - Service validates action and calculates damage
   - Participant HP is updated
   - Combat log entry is created
   - ActionCable broadcasts updates

3. **Resolution**:
   - When a participant's HP reaches 0, battle is completed
   - Winner/loser is determined
   - Rewards are granted to winner
   - Loser's character HP is synced to 0

### Hotwire Integration

- **Turbo Frames**: Action panel and combat log use Turbo Frame updates
- **Turbo Streams**: HP bars and combat log update via Turbo Streams
- **Stimulus**: PVP combat controller handles UI interactions

```erb
<%# Example Turbo Stream response %>
<%= turbo_stream.update "combat-log" do %>
  <div class="combat-log-entries">
    <% @combat_log.each do |entry| %>
      <div class="combat-log-entry"><%= entry %></div>
    <% end %>
  </div>
<% end %>
```

## Test Coverage

### Request Specs (`spec/requests/pvp_combat_spec.rb`)
- Attack initiation (success + failures)
- Combat actions
- Flee attempts
- Surrender
- Authorization checks

### Policy Specs (`spec/policies/pvp_combat_policy_spec.rb`)
- Participant authorization
- Action permissions

### Service Specs (`spec/services/game/combat/pvp_encounter_service_spec.rb`)
- Encounter creation
- Action processing
- Turn resolution
- Reward calculation

### Zone Rules Specs (`spec/services/game/pvp/zone_rules_spec.rb`)
- PVP zone detection
- Safe zone detection
- Flag checking
- Faction warfare

### System Specs (`spec/system/pvp_combat_spec.rb`)
- UI interactions
- Turbo Frame updates
- Combat completion

## Responsible for Implementation Files

### Models
- `app/models/battle.rb` - Battle persistence (supports pvp battle_type, rng_seed)
- `app/models/battle_participant.rb` - Participant tracking (current_hp canonical, scopes)
- `app/models/combat_log_entry.rb` - Combat log persistence
- `app/models/pvp_flag.rb` - PVP flag tracking
- `app/models/character.rb` - Combat stats (attack_power, defense, critical_chance, agility)

### Controllers
- `app/controllers/pvp_combat_controller.rb` - PVP combat UI

### Views
- `app/views/pvp_combat/show.html.erb` - Battle view
- `app/views/pvp_combat/action.turbo_stream.erb` - Action updates
- `app/views/pvp_combat/turn.turbo_stream.erb` - Turn updates
- `app/views/pvp_combat/toggle_pvp.turbo_stream.erb` - PVP toggle

### Game Engine
- `app/lib/game/formulas/combat_damage_formula.rb` - Unified damage formula (PvE/PvP)

### Services
- `app/services/game/combat/pvp_encounter_service.rb` - PVP combat service (with all improvements)
- `app/services/game/pvp/zone_rules.rb` - Zone PVP rules (fixed faction alignment)
- `app/services/game/pvp/flag_service.rb` - PVP flag management
- `app/services/characters/vitals_service.rb` - Damage/healing application

### Policies
- `app/policies/pvp_combat_policy.rb` - PVP authorization

### Migrations
- `db/migrate/20251228200000_improve_pvp_battle_system.rb` - RNG seed, unique index, HP sync

### Specs
- `spec/requests/pvp_combat_spec.rb`
- `spec/policies/pvp_combat_policy_spec.rb`
- `spec/services/game/pvp/zone_rules_spec.rb`
- `spec/services/game/pvp/flag_service_spec.rb`
- `spec/services/game/combat/pvp_encounter_service_spec.rb`
- `spec/lib/game/formulas/combat_damage_formula_spec.rb`
- `spec/models/pvp_flag_spec.rb`
- `spec/models/battle_participant_spec.rb`
- `spec/system/pvp_combat_spec.rb`

---

## Related Documentation
- `doc/flow/16_combat_system.md` — PVE combat system flow
- `doc/flow/11_arena_pvp.md` — Arena PVP system
- `doc/COMBAT_SYSTEM_GUIDE.md` — Combat formulas and mechanics
- `doc/flow/22_unified_npc_architecture.md` — NPC architecture (for arena bots)
