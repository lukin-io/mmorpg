# Unified NPC Architecture

## Version History
- **v1.0** (2025-12-22): Initial implementation - unified stat calculation and combat behavior
- **v1.1** (2025-12-22): Added avatar system for NPCs and players

## Overview

The Elselands MMORPG uses a **unified NPC architecture** where all NPCs share common attributes, behaviors, and stat calculations. This is similar to Single Table Inheritance (STI) but implemented via:

1. **Single model**: `NpcTemplate` as the source of truth
2. **Role field**: Determines NPC type and behavior (hostile, arena_bot, quest_giver, etc.)
3. **Metadata JSONB**: Stores role-specific data (loot tables, AI behavior, shop inventory)
4. **Shared concerns**: `Npc::CombatStats` and `Npc::Combatable` for combat logic

## GDD Reference
- Section: NPC System (general NPC definitions)
- Feature spec: Arena bots, outside-world hostile NPCs

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          NpcTemplate                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ Core Attributes: name, level, role, dialogue, metadata (JSONB)│  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                │                                     │
│       ┌────────────────────────┼────────────────────────┐           │
│       ▼                        ▼                        ▼           │
│  ┌──────────────┐      ┌──────────────┐       ┌──────────────┐     │
│  │Npc::CombatStats│     │Npc::Combatable│       │ Role-Specific│     │
│  │  (concern)    │     │  (concern)    │       │   Methods    │     │
│  │               │     │               │       │              │     │
│  │ combat_stats  │     │ hostile?      │       │ arena_bot?   │     │
│  │ combat_stat   │     │ attackable?   │       │ vendor?      │     │
│  │ max_hp        │     │ combat_behavior│      │ trainer?     │     │
│  │ attack_power  │     │ difficulty_rating│    │ arena_rooms  │     │
│  │ defense_value │     │ should_defend?│       │ avatar_emoji │     │
│  │ attack_damage_range│ │ loot_table   │       │              │     │
│  └──────────────┘      │ xp_reward     │       └──────────────┘     │
│                        └──────────────┘                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
            ┌───────────────────┼───────────────────┐
            ▼                   ▼                   ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │   TileNpc    │    │ArenaApplication│   │BattleParticipant│
    │(outside world)│   │(arena combat)  │   │  (PvE combat) │
    │              │    │               │    │               │
    │belongs_to    │    │belongs_to     │    │belongs_to     │
    │:npc_template │    │:npc_template  │    │:npc_template  │
    └──────────────┘    └──────────────┘    └──────────────┘
```

## Role Types

| Role | Combat? | Behavior | Description |
|------|---------|----------|-------------|
| `hostile` | Yes | aggressive | Attacks players on sight |
| `arena_bot` | Yes | balanced/varies | Training bots in arena |
| `guard` | Yes | defensive | Protects areas, attacks hostiles |
| `trainer` | Yes | defensive | Sparring partner for skills |
| `quest_giver` | No | passive | Provides quests |
| `vendor` | No | passive | Sells items |
| `innkeeper` | No | passive | Rest/logout services |
| `banker` | No | passive | Banking services |
| `auctioneer` | No | passive | Auction house |
| `crafter` | No | passive | Crafting services |
| `lore` | No | passive | Story/lore exposition |

## Stat Calculation (Npc::CombatStats)

Stats are calculated with the following priority:

1. **Explicit metadata stats**: `metadata["stats"]["attack"]` (highest priority)
2. **Individual metadata fields**: `metadata["base_damage"]`, `metadata["health"]`
3. **Formula defaults**: Based on NPC level

### Default Formulas

| Stat | Formula |
|------|---------|
| attack | `level * 3 + 5` |
| defense | `level * 2 + 3` |
| agility | `level + 5` |
| hp | `level * 10 + 20` |
| crit_chance | `10` (constant) |
| dodge_chance | `min(level / 2, 25)` |

### Role Modifiers

Arena bots are slightly weaker (×0.9 attack, ×0.9 defense, ×0.95 HP) for training purposes.

## Combat Behavior (Npc::Combatable)

The `combat_behavior` method returns `:aggressive`, `:balanced`, `:defensive`, or `:passive`.

### Defense Thresholds

| Behavior | HP Threshold | Defend Chance |
|----------|--------------|---------------|
| defensive | 70% | 40% |
| balanced | 40% | 20% |
| aggressive | 20% | 10% |
| passive | 100% | 80% |

## Implementation Notes

### Key Design Decisions

1. **No separate ArenaBot model**: Reuses `NpcTemplate` with `role: "arena_bot"`
2. **Concerns over inheritance**: Horizontal composition via Ruby concerns
3. **Backward compatibility**: Legacy methods (`health`, `damage_range`) delegate to new concern methods
4. **Deterministic combat**: All random decisions accept `rng:` parameter

### Metadata Structure Examples

**Hostile NPC (outside world)**:
```yaml
metadata:
  biome: "forest"
  health: 100
  base_damage: 15
  xp_reward: 50
  loot_table:
    - { item_key: "wolf_pelt", chance: 0.3 }
```

**Arena Bot**:
```yaml
metadata:
  difficulty: "easy"
  ai_behavior: "defensive"
  arena_rooms: ["training"]
  description: "A practice target for new fighters"
  avatar: "🎯"
```

## Service Integration

### PveEncounterService (outside world)

```ruby
# Uses unified combat_stats
def npc_stats
  @npc_stats ||= npc_template.combat_stats
end
```

### Arena::NpcCombatAi (arena)

```ruby
# Uses unified combat_behavior and should_defend?
def decide_action
  hp_ratio = calculate_hp_ratio(participation)
  if npc_template.should_defend?(current_hp_ratio: hp_ratio, rng: rng)
    Decision.new(action_type: :defend, ...)
  else
    attack_decision
  end
end

def stats
  @stats ||= npc_template.combat_stats
end
```

## Responsible for Implementation Files

### Models
- `app/models/npc_template.rb` - Central NPC model with concerns
- `app/models/tile_npc.rb` - Outside world NPC instances
- `app/models/arena_application.rb` - Arena applications (player or NPC)
- `app/models/arena_participation.rb` - Arena match participants
- `app/models/character.rb` - Player character with avatar assignment

### Concerns
- `app/models/concerns/npc/combat_stats.rb` - Unified stat calculation
- `app/models/concerns/npc/combatable.rb` - Combat behavior interface

### Services
- `app/services/game/combat/pve_encounter_service.rb` - Outside world combat
- `app/services/arena/npc_combat_ai.rb` - Arena NPC decision-making
- `app/services/arena/npc_application_service.rb` - Arena NPC applications
- `app/services/game/world/arena_npc_config.rb` - Arena NPC YAML loader

### Helpers
- `app/helpers/avatar_helper.rb` - Avatar rendering for players and NPCs

### Views
- `app/views/arena_matches/_participant.html.erb` - Arena participant with avatar
- `app/views/combat/_nl_participant.html.erb` - Combat participant with avatar

### Assets
- `app/assets/images/avatars/` - Player avatar images (6 options)
- `app/assets/images/npc/` - NPC avatar images (5 monsters)

### Configuration
- `config/gameplay/biome_npcs.yml` - Outside world NPC definitions
- `config/gameplay/arena_npcs.yml` - Arena bot definitions

### Database
- `db/migrate/20251222131711_add_avatar_to_characters.rb` - Avatar column

## Testing

All NPC types are testable with deterministic RNG. Test files:

### Concern Specs
- `spec/models/concerns/npc/combat_stats_spec.rb` — Stat calculation tests
  - Default formula calculations
  - Metadata overrides (stats, individual fields)
  - Role modifiers (arena_bot, guard, vendor, etc.)
  - Level override
  - Edge cases (nil metadata, empty values, boundaries)

- `spec/models/concerns/npc/combatable_spec.rb` — Combat behavior tests
  - Combat role detection
  - Behavior determination (aggressive, balanced, defensive, passive)
  - Defense decisions with RNG
  - Loot, XP, gold rewards
  - Initiative rolling

### Model Integration Specs
- `spec/models/npc_template_spec.rb` — Concern integration
  - Verifies concerns are properly included
  - Tests legacy method compatibility
  - Tests arena-specific methods

### Service Specs
- `spec/services/arena/npc_combat_ai_spec.rb` — Arena AI tests
  - Decision making by behavior type
  - Stats from unified concern
  - Determinism with seeded RNG
  - Edge cases (no opponents, nil metadata)

- `spec/services/game/combat/pve_encounter_service_spec.rb` — PvE integration
  - NPC stats from unified concern
  - Role modifier consistency
  - Cross-system stat consistency

### Example Test

```ruby
RSpec.describe NpcTemplate do
  describe "unified combat stats" do
    let(:wolf) { create(:npc_template, role: "hostile", level: 5) }
    let(:arena_bot) { create(:npc_template, role: "arena_bot", level: 5) }

    it "calculates consistent stats across roles" do
      expect(wolf.combat_stats[:attack]).to eq(20)  # 5*3+5
      expect(arena_bot.combat_stats[:attack]).to eq(18)  # (5*3+5)*0.9
    end

    it "respects metadata overrides" do
      wolf.metadata = { "stats" => { "attack" => 100 } }
      expect(wolf.combat_stats[:attack]).to eq(100)
    end
  end
end
```

## Avatar System

### Overview

Both NPCs and players have avatar images displayed in combat, arena, and profile views.

### Player Avatars

Players are assigned a random avatar on character creation from 6 options stored in `app/assets/images/avatars/`:

| Avatar | Filename |
|--------|----------|
| Dwarven | `dwarven.png` |
| Nightveil | `nightveil.png` |
| Lightbearer | `lightbearer.png` |
| Pathfinder | `pathfinder.png` |
| Arcanist | `arcanist.png` |
| Ironbound | `ironbound.png` |

**Implementation:**
- `Character#avatar` column stores the avatar name
- `before_validation :assign_random_avatar` auto-assigns on create
- `Character#avatar_image_path` returns full asset path

### NPC Avatars

NPCs use monster images stored in `app/assets/images/npc/`:

| Avatar | Filename | Used By |
|--------|----------|---------|
| Scarecrow | `scarecrow.png` | Arena bots (all) |
| Wolf | `wolf.png` | Forest/Plains wolves |
| Boar | `boar.png` | Wild boars, bears (visual placeholder) |
| Skeleton | `skeleton.png` | Undead enemies |
| Zombie | `zombie.png` | Bog zombies, undead |

**Avatar Resolution Priority:**
1. Explicit `metadata["avatar_image"]` in YAML config
2. Role-based default (`arena_bot` → scarecrow)
3. NPC key pattern matching (`*wolf*` → wolf)
4. Random fallback for hostile NPCs

**Implementation:**
- `NpcTemplate#avatar_image` returns filename with extension
- `NpcTemplate#avatar_image_path` returns `npc/{filename}`

### Helper Methods

`AvatarHelper` provides view helpers:

```ruby
# For characters
character_avatar_tag(character, size: :medium)

# For NPCs
npc_avatar_tag(npc_template, size: :large)

# For arena participations (handles both)
participation_avatar_tag(participation, size: :medium)

# For battle participants (handles both)
battle_participant_avatar_tag(participant, size: :small)
```

**Size Options:** `:small` (32px), `:medium` (48px), `:large` (64px), `:xlarge` (96px)

### Configuration Examples

**Arena NPC (arena_npcs.yml):**
```yaml
- key: arena_training_dummy
  name: Sparring Dummy
  role: arena_bot
  metadata:
    avatar: "🎯"           # Emoji for text displays
    avatar_image: "scarecrow.png"  # Image for UI
```

**Open World NPC (biome_npcs.yml):**
```yaml
- key: plains_wolf
  name: Plains Wolf
  role: hostile
  metadata:
    avatar_image: "wolf.png"
```

### Avatar-Related Files

- `app/helpers/avatar_helper.rb` - View helpers for rendering avatars
- `app/models/character.rb` - `AVATARS`, `avatar_image_path`, auto-assignment
- `app/models/npc_template.rb` - `avatar_image`, `avatar_image_path`
- `app/assets/images/avatars/*.png` - Player avatar images
- `app/assets/images/npc/*.png` - NPC avatar images
- `app/assets/stylesheets/application.css` - Avatar CSS classes

### Testing

Avatar specs are in:
- `spec/helpers/avatar_helper_spec.rb` - Helper method tests
- `spec/models/character_spec.rb` - Avatar assignment tests

## Future Extensions

1. **Boss NPCs**: Add `boss` role with special mechanics
2. **NPC Skills**: Add skill definitions to metadata, process in combat
3. **Faction System**: NPCs with faction affiliations affecting behavior
4. **Dynamic Scaling**: Scale NPC stats based on player level/gear
5. **Custom Player Avatars**: Allow players to change avatars via shop/achievements

