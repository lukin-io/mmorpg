# 4_world_npc_systems.md — World, NPC, and Quest Flows
---
title: WEB-104 — World/NPC/Quest Flow
description: Documents deterministic world data sources, NPC archetypes, quest orchestration, seasonal events, magistrate reporting, and responsive UI requirements for mobile clients.
date: 2025-11-22
updated: 2025-12-22
---

## Version History
- **v1.0** (2025-11-22): Initial implementation
- **v1.1** (2025-12-22): Added Unified NPC Architecture section with concerns-based design
- **v1.2** (2025-12-22): Added Avatar System for NPCs and players

## Summary
- Deterministic world metadata now lives under `config/gameplay/world/**` and is parsed via `Game::World::RegionCatalog`.
- **Unified NPC Architecture**: All NPCs share common behavior via `NpcTemplate` model with `Npc::CombatStats` and `Npc::Combatable` concerns.
- NPC archetypes + monster taxonomy are data-driven; spawn overrides flow through `SpawnSchedule` records managed in Hotwire UI.
- Quest progression (main, side, daily, dynamic) persists through `Quest*` tables and services inside `Game::Quests::*`.
- Seasonal + tournament events spawn concrete instances via `Game::Events::Scheduler` + `ScheduledEventJob`.
- Magistrate/guard NPCs accept in-game reports which create `NpcReport` tickets through `Game::Moderation::NpcIntake`.
- Quest layouts, map/quest/chat panels share the new `layout-stack` Stimulus controller for mobile Safari/Chrome.

## World Structure
- `config/gameplay/world/regions.yml` mirrors Elselands regions (forest, mountain, river, city, castle). Each entry encodes landmarks, hidden areas, resource focus, and clan buff payloads.
- `config/gameplay/world/resource_nodes.yml` pinpoints deterministic coordinates for herb, ore, fishing, artisan, and siege caches.
- `Game::World::RegionCatalog` loads YAML at boot, memoizes `Game::World::Region` POROs, and exposes helpers for territory, zone, or coordinate lookups.
- `Economy::TaxCalculator` and `ClanTerritory#clan_bonuses` consume region metadata so clan ownership buffs/taxes apply automatically wherever `territory_key` matches.

---

## Unified NPC Architecture (Base Layer)

> **Reference**: See `doc/flow/22_unified_npc_architecture.md` for detailed technical specification.

All NPCs in Elselands share a common foundation via the **Unified NPC Architecture**. This pattern is similar to Single Table Inheritance (STI) but uses Ruby concerns for shared behavior.

### Core Components

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
│  └──────────────┘      └──────────────┘       └──────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
```

| Component | Purpose | File |
|-----------|---------|------|
| `NpcTemplate` | Central model - single source of truth | `app/models/npc_template.rb` |
| `Npc::CombatStats` | Stat calculation (attack, defense, HP) | `app/models/concerns/npc/combat_stats.rb` |
| `Npc::Combatable` | Combat behavior (hostile?, should_defend?) | `app/models/concerns/npc/combatable.rb` |
| `metadata` JSONB | Role-specific extensions | Database column |

### NPC Roles

| Role | Combat? | Default Behavior | Use Case |
|------|---------|------------------|----------|
| `hostile` | ✅ | aggressive | World enemies, monsters |
| `arena_bot` | ✅ | balanced | Arena training opponents |
| `guard` | ✅ | defensive | Town guards, protectors |
| `trainer` | ✅ | defensive | Combat training, sparring |
| `quest_giver` | ❌ | passive | Quest NPCs |
| `vendor` | ❌ | passive | Shops, merchants |
| `innkeeper` | ❌ | passive | Rest, healing |
| `banker` | ❌ | passive | Banking services |
| `auctioneer` | ❌ | passive | Auction house |
| `crafter` | ❌ | passive | Crafting stations |
| `lore` | ❌ | passive | Story, exposition |

---

## How to Create a New NPC

### Step 1: Define in YAML (for data-driven NPCs)

**Outside World NPC** (`config/gameplay/biome_npcs.yml`):
```yaml
forest:
  description: "Forest creatures"
  npcs:
    - key: forest_wolf
      name: Forest Wolf
      role: hostile
      level: 5
      hp: 80
      damage: 12
      xp: 50
      dialogue: "*growls menacingly*"
      spawn_chance: 25
      metadata:
        biome: forest
        rarity: common
        avatar_image: "wolf.png"  # Image in app/assets/images/npc/
        loot_table:
          - { item_key: "wolf_pelt", chance: 0.3 }
```

**Arena Bot** (`config/gameplay/arena_npcs.yml`):
```yaml
training:
  npcs:
    - key: arena_practice_golem
      name: Practice Golem
      role: arena_bot
      level: 3
      hp: 60
      damage: 5
      xp: 10
      dialogue: "*mechanical whirring*"
      metadata:
        difficulty: easy
        ai_behavior: defensive
        arena_rooms: ["training"]
        avatar: "🤖"             # Emoji for text displays
        avatar_image: "scarecrow.png"  # Image for UI
```

### Step 2: Create NpcTemplate Record

The YAML is loaded and creates `NpcTemplate` records. Or create directly:

```ruby
NpcTemplate.create!(
  npc_key: "forest_wolf",
  name: "Forest Wolf",
  role: "hostile",
  level: 5,
  dialogue: "*growls menacingly*",
  metadata: {
    "health" => 80,
    "base_damage" => 12,
    "xp_reward" => 50,
    "loot_table" => [{ "item_key" => "wolf_pelt", "chance" => 0.3 }]
  }
)
```

### Step 3: Access Stats via Unified Interface

```ruby
wolf = NpcTemplate.find_by(npc_key: "forest_wolf")

# Stats from Npc::CombatStats concern
wolf.combat_stats       # => { attack: 12, defense: 13, hp: 80, ... }
wolf.max_hp             # => 80
wolf.attack_power       # => 12
wolf.attack_damage_range # => 9..15

# Behavior from Npc::Combatable concern
wolf.hostile?           # => true
wolf.can_engage_combat? # => true
wolf.combat_behavior    # => :aggressive
wolf.should_defend?(current_hp_ratio: 0.2, rng: rng) # => true/false
wolf.xp_reward          # => 50
wolf.loot_table         # => [{ "item_key" => "wolf_pelt", ... }]
```

---

## How to Extend an Existing NPC Type

### Option 1: Add Role-Specific Metadata

Extend behavior without code changes by adding metadata fields:

```ruby
# Create a special boss version of an existing enemy
NpcTemplate.create!(
  npc_key: "alpha_wolf",
  name: "Alpha Wolf",
  role: "hostile",
  level: 15,
  dialogue: "*howls with authority*",
  metadata: {
    "health" => 500,
    "base_damage" => 35,
    "difficulty" => "elite",      # Used by difficulty_rating
    "can_flee" => false,          # Override default behavior
    "flee_threshold" => 0.0,
    "loot_table" => [
      { "item_key" => "alpha_pelt", "chance" => 1.0 },
      { "item_key" => "rare_fang", "chance" => 0.5 }
    ],
    "stats" => {                  # Explicit stat override
      "attack" => 40,
      "defense" => 25,
      "crit_chance" => 20
    }
  }
)
```

### Option 2: Add New Role Methods

Add role-specific methods to `NpcTemplate`:

```ruby
# app/models/npc_template.rb
class NpcTemplate < ApplicationRecord
  # Existing concerns
  include Npc::CombatStats
  include Npc::Combatable

  # Add new role check
  def boss?
    metadata&.dig("difficulty") == "boss" || metadata&.dig("rarity") == "boss"
  end

  # Boss-specific behavior
  def special_abilities
    return [] unless boss?
    metadata&.dig("abilities") || []
  end
end
```

### Option 3: Create Role-Specific Concern

For complex role-specific behavior, create a new concern:

```ruby
# app/models/concerns/npc/boss_mechanics.rb
module Npc
  module BossMechanics
    extend ActiveSupport::Concern

    def enrage_threshold
      metadata&.dig("enrage_threshold") || 0.25
    end

    def enraged?(current_hp_ratio)
      difficulty_rating == :boss && current_hp_ratio < enrage_threshold
    end

    def enrage_damage_multiplier
      metadata&.dig("enrage_multiplier") || 1.5
    end
  end
end

# Include in NpcTemplate
class NpcTemplate < ApplicationRecord
  include Npc::CombatStats
  include Npc::Combatable
  include Npc::BossMechanics  # New concern
end
```

---

## Stat Calculation Priority

Stats are calculated in this order (first match wins):

1. **Explicit `stats` hash in metadata** (highest priority)
   ```json
   { "stats": { "attack": 100, "defense": 50 } }
   ```

2. **Individual metadata fields**
   ```json
   { "base_damage": 25, "health": 200 }
   ```

3. **Formula defaults based on level**
   | Stat | Formula |
   |------|---------|
   | attack | `level * 3 + 5` |
   | defense | `level * 2 + 3` |
   | agility | `level + 5` |
   | hp | `level * 10 + 20` |

4. **Role modifiers applied last**
   | Role | Attack | Defense | HP |
   |------|--------|---------|-----|
   | hostile | 1.0× | 1.0× | 1.0× |
   | arena_bot | 0.9× | 0.9× | 0.95× |
   | guard | 1.2× | 1.5× | 1.3× |
   | vendor | 0.3× | 0.3× | 0.5× |

---

## Integration Points

### Where NPCs Are Used

| System | Model | Reference |
|--------|-------|-----------|
| World map | `TileNpc` | `belongs_to :npc_template` |
| PvE Combat | `BattleParticipant` | `belongs_to :npc_template` |
| Arena applications | `ArenaApplication` | `belongs_to :npc_template` |
| Arena combat | `ArenaParticipation` | `belongs_to :npc_template` |

### Services Using NpcTemplate

| Service | Purpose |
|---------|---------|
| `Game::Combat::PveEncounterService` | Outside world combat |
| `Arena::NpcCombatAi` | Arena bot AI decisions |
| `Arena::NpcApplicationService` | Create arena bot applications |
| `Game::World::BiomeNpcConfig` | Load biome NPCs from YAML |
| `Game::World::ArenaNpcConfig` | Load arena bots from YAML |
| `Game::Npc::DialogueService` | NPC dialogue interactions |

---

## NPCs & Monsters
- `config/gameplay/world/npcs.yml` defines vendors, trainers, storytellers, guards, event hosts, and magistrates with faction alignment, dialogue states, quest hooks, and moderation categories.
- `config/gameplay/world/monsters.yml` defines per-region taxonomy with rarity tiers, loot tables, and respawn timers.
- `Game::World::NpcArchetype` + `Game::World::MonsterProfile` wrap YAML entries; `Game::World::PopulationDirectory` exposes NPC lookups, monster spawn entries, and magistrates flagged for reporting.
- `SpawnSchedule` records allow GMs/moderators to override respawn/rates. Hotwire UI at `/spawn_schedules` writes to this table; overrides flow back into `EncounterResolver` via `PopulationDirectory`.
- `Game::Exploration::EncounterResolver` now blends zone encounter tables with population spawn entries, surfacing rarity + respawn hints for deterministic RNG rolls.

### NPC Dialogue System (✅ Implemented)
**Service:** `Game::Npc::DialogueService` — orchestrates all NPC interactions
**Controller:** `WorldController#interact`, `WorldController#dialogue_action`
**Files:**
- `app/services/game/npc/dialogue_service.rb`
- `app/views/world/dialogue.html.erb`
- `app/views/world/_dialogue_*.html.erb` (quests, vendor, trainer, innkeeper, banker, guard, hostile, generic, result)

**Supported NPC Roles:**
| Role | Dialogue Type | Actions |
|------|--------------|---------|
| `quest_giver` | Quest list | Accept, complete, view progress |
| `vendor` | Shop inventory | Buy items, sell items |
| `trainer` | Skill list | Learn skills (gold cost) |
| `innkeeper` | Room options | Rest (heal HP, buffs) |
| `banker` | Balance view | Deposit, withdraw gold/silver |
| `guard` | Zone info | Get directions, area info |
| `hostile` | Combat prompt | Attack or flee |
| `auctioneer` | Redirect | Opens `/auction_listings` |
| `crafter` | Redirect | Opens `/crafting_jobs` |

**Flow:**
1. Player clicks NPC on map → `WorldController#interact`
2. `DialogueService#start_dialogue!` returns role-specific data
3. View renders appropriate dialogue partial based on `result.dialogue_type`
4. Player selects action → `WorldController#dialogue_action`
5. `DialogueService#process_choice!` executes action (buy, rest, accept quest, etc.)
6. Turbo Stream updates dialogue content or redirects

**Key Behaviors:**
- Quest availability filtered by level requirement
- Vendor prices from NPC metadata or item base price
- Trainer skills filtered by requirements and already-learned
- Inn rooms: Common (50% HP, 10g), Private (100% HP, 50g), Suite (100% HP + buff, 200g)
- Bank stores gold/silver separately from character wallet

### NPCs at Current Tile (✅ Implemented)
**Model:** `NpcTemplate` — enhanced with zone scopes and spawn logic
**Method:** `WorldController#npcs_at_current_tile`

**Implementation:**
- `NpcTemplate.in_zone(zone_name)` — queries NPCs by metadata zone field
- `NpcTemplate#can_spawn_at?(zone:, x:, y:)` — checks position restrictions
- `#hostile_npcs_at_tile` / `#friendly_npcs_at_tile` — role-based filtering

**NPC Metadata Fields:**
```json
{
  "zone": "Whispering Woods",
  "zones": ["Forest", "Plains"],
  "spawn_area": { "min_x": 0, "max_x": 10, "min_y": 0, "max_y": 10 },
  "biomes": ["forest", "plains"],
  "greetings": ["Hello!", "Greetings traveler."],
  "inventory": [{ "item_key": "health_potion", "price": 50 }],
  "teaches": { "class": 1 }
}
```

## Quests & Narrative
- Schema: `quest_chains`, `quests`, `quest_objectives`, `quest_assignments`, and `cutscene_events`.
- Services: `Game::Quests::StorylineProgression` gates sequential unlocks; `DailyRotation` handles morning/afternoon/evening resets; `DynamicHookResolver` unlocks seasonal/tournament quests.
- Controller/UI: `QuestsController` (Hotwire) renders quest log, dialogue, dailies, and magistrate links; responsive layout ensures stacked panels on mobile browsers.
- Data: assignments attach to `Character`, enabling per-character state for main, side, daily, and event hooks.

## Events & Special Features
- Schema: `event_instances`, `arena_tournaments`, and `community_objectives` extend seasonal/tournament flows.
- `Game::Events::Scheduler` spawns instances, announcer NPC references, tournament brackets, and community objective drives.
- `ScheduledEventJob` now resolves event slugs → scheduler orchestration, so `EventSchedule` entries can enqueue deterministic runs.
- GMs manage lifecycle via existing `GameEventsController` + `Events::LifecycleService`, backed by the richer domain objects above.

## Moderation & Reporting
- `NpcReport` captures magistrate/guard intake categories (chat abuse, botting, griefing, exploit reports).
- `Game::Moderation::NpcIntake` validates NPC roles, persists reports, and logs actions to `AuditLog`.
- `NpcReportsController` + Hotwire form provide in-world reporting UX; NPC dialogue snippet surfaces in the form when an `npc_key` is provided.

## Mobile & Accessibility
- `layout-stack` Stimulus controller toggles stacked layout classes for quest/map/chat containers when viewport ≤ 768px.
- Quest UI uses semantic headings + stacking frames, ensuring Safari/Chrome mobile players can accept/complete quests quickly.
- Dialogue frames expose report links plus button-sized touch targets following the short-session requirement.

## Responsible for Implementation Files

### NPC Core (Unified Architecture)
- **Model:** `app/models/npc_template.rb` — Central NPC model
- **Concerns:**
  - `app/models/concerns/npc/combat_stats.rb` — Stat calculation
  - `app/models/concerns/npc/combatable.rb` — Combat behavior
- **Instance Models:**
  - `app/models/tile_npc.rb` — World map NPC instances
  - `app/models/battle_participant.rb` — PvE combat participants
  - `app/models/arena_application.rb` — Arena fight applications
  - `app/models/arena_participation.rb` — Arena match participants

### NPC Configuration
- `config/gameplay/world/npcs.yml` — World NPC definitions
- `config/gameplay/world/monsters.yml` — Monster taxonomy
- `config/gameplay/biome_npcs.yml` — Biome-specific hostile NPCs
- `config/gameplay/arena_npcs.yml` — Arena bot definitions

### NPC Services
- `app/services/game/npc/dialogue_service.rb` — NPC dialogue system
- `app/services/game/world/biome_npc_config.rb` — Load biome NPCs
- `app/services/game/world/arena_npc_config.rb` — Load arena bots
- `app/services/game/combat/pve_encounter_service.rb` — PvE combat
- `app/services/arena/npc_combat_ai.rb` — Arena bot AI
- `app/services/arena/npc_application_service.rb` — Arena bot applications

### World Data
- `config/gameplay/world/regions.yml`, `config/gameplay/world/resource_nodes.yml`
- `app/lib/game/world/region.rb`, `npc_archetype.rb`, `monster_profile.rb`
- `app/services/game/world/region_catalog.rb`, `population_directory.rb`

### Encounters & Economy
- `app/services/game/exploration/encounter_resolver.rb`
- `app/services/economy/tax_calculator.rb`

### Quests & UI
- `app/models/quest*.rb`, `app/services/game/quests/*.rb`
- `app/controllers/quests_controller.rb`, `app/views/quests/**`
- `app/javascript/controllers/layout_stack_controller.js`

### Events
- `app/models/event_instance.rb`, `arena_tournament.rb`, `community_objective.rb`
- `app/services/game/events/scheduler.rb`, `app/jobs/scheduled_event_job.rb`

### NPC Moderation
- `app/models/npc_report.rb`
- `app/services/game/moderation/npc_intake.rb`
- `app/controllers/npc_reports_controller.rb`

### Admin Tools
- `app/models/spawn_schedule.rb`
- `app/controllers/spawn_schedules_controller.rb`, `app/views/spawn_schedules/**`

### Policies
- `app/policies/quest_policy.rb`, `quest_assignment_policy.rb`
- `app/policies/spawn_schedule_policy.rb`, `npc_report_policy.rb`

### Migrations
- `20251122130000_create_spawn_schedules.rb`
- `20251122130500_create_questing_system.rb`
- `20251122132000_create_event_instances_and_tournaments.rb`
- `20251122133000_create_npc_reports.rb`
- `20251218174018_add_npc_support_to_arena.rb`
- `20251218174704_add_metadata_to_arena_participations.rb`
- `20251222131711_add_avatar_to_characters.rb`

### Avatar System
- `app/helpers/avatar_helper.rb` — Avatar rendering helpers
- `app/assets/images/avatars/` — Player avatar images (6 options)
- `app/assets/images/npc/` — NPC avatar images (5 monsters)

### Related Documentation
- `doc/flow/22_unified_npc_architecture.md` — Technical architecture details
- `doc/flow/22_arena_npc_bots.md` — Arena bot implementation
- `doc/flow/11_arena_pvp.md` — Arena system (includes NPC bots)

## Testing & QA

### NPC Core Specs
- `spec/models/concerns/npc/combat_stats_spec.rb` — Stat calculation tests
  - Default formulas, metadata overrides, role modifiers, edge cases
- `spec/models/concerns/npc/combatable_spec.rb` — Combat behavior tests
  - Role detection, behavior types, defense decisions, rewards
- `spec/models/npc_template_spec.rb` — Model integration tests
  - Concern integration, legacy compatibility, scopes
- `spec/services/arena/npc_combat_ai_spec.rb` — Arena AI tests
  - Decisions, determinism, unified architecture integration
- `spec/services/game/combat/pve_encounter_service_spec.rb` — PvE combat tests
  - NPC stats consistency, role modifiers

### World & Quest Specs
- `spec/services/game/world/*` — World catalog, region, NPC config tests
- `spec/services/game/quests/*` — Quest progression, dailies, event hooks
- `spec/services/game/events/scheduler_spec.rb` — Event scheduling
- `spec/services/game/moderation/npc_intake_spec.rb` — NPC moderation
- `spec/jobs/scheduled_event_job_spec.rb` — Background jobs

### Avatar System Specs
- `spec/helpers/avatar_helper_spec.rb` — Avatar helper tests
  - Player avatar rendering (character_avatar_tag)
  - NPC avatar rendering (npc_avatar_tag)
  - Participation and battle participant avatars
  - Size options, fallbacks, metadata overrides
- `spec/models/character_spec.rb` — Character avatar tests
  - Auto-assignment on create
  - Avatar image path generation

### Test Coverage Notes
- All NPC types testable with deterministic RNG via `rng:` parameter
- Factory traits: `:npc` for arena participations
- World catalog tests ensure YAML coverage
- Quest services cover sequential unlocks, dailies, and event hooks
- Avatar tests verify image path resolution and helper output


