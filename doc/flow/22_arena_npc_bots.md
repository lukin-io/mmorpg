# 22. Arena NPC Bots Flow

## Version History
- **v1.0** (2024-12-18): Initial implementation - NPC arena bots for training fights
- **v1.1** (2025-12-22): Updated to reference Unified NPC Architecture

## Overview
Arena NPC Bots provide automated opponents for players to practice combat in the arena. These bots create fight applications that players can accept, enabling low-stakes training matches where players can learn combat mechanics without risking significant trauma or penalties.

**Architecture Note**: Arena bots use the **Unified NPC Architecture** — they are `NpcTemplate` records with `role: "arena_bot"`. Stats and behavior come from the shared concerns `Npc::CombatStats` and `Npc::Combatable`. See `doc/flow/22_unified_npc_architecture.md` for the base layer.

## GDD Reference
- Section: Arena PvP (training mode)
- Feature spec: `doc/flow/11_arena_pvp.md`
- Base NPC system: `doc/flow/4_world_npc_systems.md` (Unified NPC Architecture section)
- Technical architecture: `doc/flow/22_unified_npc_architecture.md`

## Key Concepts

### NPC Bot Types
Bots are categorized by difficulty and AI behavior:

| Difficulty | HP Range | Damage | AI Behavior | Target Rooms |
|------------|----------|--------|-------------|--------------|
| Easy | 30-70 | 3-8 | Defensive | Training |
| Medium | 70-130 | 8-18 | Balanced | Training, Trial |
| Hard | 100-220 | 14-40 | Aggressive | Trial, Challenge |

### AI Behaviors
- **Defensive**: Prefers blocking when HP < 70%, 40% defend chance
- **Balanced**: Mix of attack/defend, defends when HP < 40%
- **Aggressive**: Always attacks, rarely defends

## Use Cases

### UC-1: NPC Creates Application (Background Job)
**Actor:** System (NpcSpawnerJob)
**Flow:**
1. `Arena::NpcSpawnerJob` runs periodically (every 60 seconds)
2. Checks NPC-enabled rooms (training, trial, challenge)
3. If room has < 2 open NPC applications, spawns more
4. `Arena::NpcApplicationService#create_for_room` picks random NPC
5. Creates `ArenaApplication` with `npc_template_id`
6. Broadcasts to `arena:room:{id}` channel

### UC-2: Player Accepts NPC Application
**Actor:** Player browsing Training Grounds
**Flow:**
1. Player sees NPC application with bot indicator (🤖)
2. Clicks "Accept" on NPC application
3. `ArenaApplicationsController#accept` → `Arena::ApplicationHandler#accept`
4. Detects `npc_application?` → calls `accept_npc_application`
5. Creates `ArenaMatch` with `is_npc_fight: true` in metadata
6. Creates `ArenaParticipation` for player (team "a")
7. Creates `ArenaParticipation` for NPC (team "b", with `npc_template_id`)
8. NPC HP tracked in participation metadata
9. 5-second countdown (shorter than PvP)
10. Match starts

### UC-3: Combat with NPC
**Actor:** Player in NPC match
**Flow:**
1. Player submits attack action
2. `Arena::CombatProcessor#process_action` processes player attack
3. Detects `npc_fight?` → opponent is NPC
4. `process_attack_on_npc` calculates damage against NPC stats
5. Updates NPC HP in participation metadata
6. Broadcasts `npc_vitals_update` to match channel
7. After player turn, `process_npc_turn` is called
8. `Arena::NpcCombatAi#decide_action` determines NPC action
9. NPC attacks player or defends based on AI behavior
10. Broadcasts `npc_combat_action` to match channel
11. Loop until one side wins

### UC-4: NPC Defeated
**Actor:** Player wins against NPC
**Flow:**
1. NPC HP reaches 0
2. `handle_npc_defeat` marks participation as "defeated"
3. Broadcasts `npc_defeated` event
4. Match ends with player victory
5. Reduced trauma (10% vs 30% normal)
6. XP reward based on NPC level

## Implementation Notes

### Stat Extraction Pattern (Unified Architecture)

Arena bots now use the **Unified NPC Architecture** via concerns. Stats come directly from `NpcTemplate`:

```ruby
# Old pattern (deprecated)
# npc_config = Game::World::ArenaNpcConfig.find_npc(npc.npc_key)

# New pattern - uses Npc::CombatStats concern
npc = NpcTemplate.find_by(npc_key: "arena_training_dummy")
stats = npc.combat_stats  # => { attack: 8, defense: 5, hp: 28, ... }

# Arena bots have 0.9x attack/defense modifier (training purpose)
# This is automatically applied by the concern based on role
```

The `Arena::NpcCombatAi` service uses this directly:

```ruby
class Arena::NpcCombatAi
  def stats
    @stats ||= npc_template.combat_stats  # From Npc::CombatStats concern
  end
end
```

### Deterministic AI
All NPC decisions use seeded RNG for testability. The AI uses the unified `Npc::Combatable` concern:

```ruby
ai = Arena::NpcCombatAi.new(
  npc_template: npc,
  match: match,
  rng: Random.new(match.id + Time.current.to_i)
)
decision = ai.decide_action

# Internally, decide_action uses the concern's should_defend? method:
# npc_template.should_defend?(current_hp_ratio: hp_ratio, rng: rng)
# npc_template.combat_behavior  # => :defensive, :balanced, :aggressive, :passive
```

### HP Tracking for NPCs
Since NPCs don't have Character records, HP is tracked in participation metadata:

```ruby
# ArenaParticipation for NPC
participation.metadata = {
  "current_hp" => 100,
  "max_hp" => 100,
  "defending" => false
}
```

## Hotwire Integration

### ActionCable Broadcasts
- `new_application`: NPC application created (includes `is_npc: true`)
- `npc_match_created`: Match between player and NPC started
- `npc_combat_action`: NPC performed an action
- `npc_vitals_update`: NPC HP changed
- `npc_defeated`: NPC was defeated

### Turbo Streams
- Application list shows NPC badge/indicator
- Combat log shows NPC actions with different styling
- HP bars update for both player and NPC

## Game Engine Classes

| Class | Purpose |
|-------|---------|
| `Game::World::ArenaNpcConfig` | Load and query arena NPC definitions from YAML |
| `Arena::NpcApplicationService` | Create NPC applications for rooms |
| `Arena::NpcCombatAi` | Deterministic AI for NPC combat decisions |
| `Arena::NpcSpawnerJob` | Background job to maintain NPC application pool |

## Configuration

### arena_npcs.yml Structure
```yaml
training:
  description: "Training Grounds bots"
  npcs:
    - key: arena_training_dummy
      name: Sparring Dummy
      role: arena_bot
      level: 1
      hp: 40
      damage: 3
      xp: 5
      metadata:
        difficulty: easy
        ai_behavior: defensive
        arena_rooms: [training]
```

### NPC-Enabled Rooms
Configured in `Arena::NpcSpawnerJob::NPC_ENABLED_ROOMS`:
- `training` (levels 1-10)
- `trial` (levels 5-10)
- `challenge` (levels 5-33)

## Responsible for Implementation Files

### Models
- `app/models/npc_template.rb` - Added `arena_bot` role, arena helper methods
- `app/models/arena_application.rb` - Added `npc_template` association, NPC helpers
- `app/models/arena_participation.rb` - Added `npc_template` association, HP tracking

### Services
- `app/services/game/world/arena_npc_config.rb` - Load arena NPC definitions
- `app/services/arena/npc_application_service.rb` - Create NPC applications
- `app/services/arena/npc_combat_ai.rb` - NPC combat decision-making
- `app/services/arena/application_handler.rb` - Modified for NPC acceptance
- `app/services/arena/combat_processor.rb` - Modified for NPC combat

### Jobs
- `app/jobs/arena/npc_spawner_job.rb` - Periodically spawn NPC applications

### Config
- `config/gameplay/arena_npcs.yml` - Arena NPC definitions

### Migrations
- `db/migrate/20251218174018_add_npc_support_to_arena.rb` - Add NPC refs to tables
- `db/migrate/20251218174704_add_metadata_to_arena_participations.rb` - Add metadata column

### Specs
- `spec/services/game/world/arena_npc_config_spec.rb`
- `spec/services/arena/npc_application_service_spec.rb`
- `spec/services/arena/npc_combat_ai_spec.rb`

### Factories
- `spec/factories/arena_participations.rb` - Added `:npc` trait

