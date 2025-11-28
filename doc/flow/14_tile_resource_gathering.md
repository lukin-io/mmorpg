# 14_tile_resource_gathering.md — Tile-Based Resource & NPC Spawning System
---
title: WEB-114 — Tile Resource & NPC Spawning Flow
description: Documents the biome-based resource spawning, NPC spawning, gathering mechanics, inventory integration, and 30-minute respawn system.
date: 2025-11-28
---

## Summary
- Players can gather resources directly from map tiles based on the tile's biome.
- Resources are added to the player's inventory upon successful gathering.
- Each tile can have one resource at a time; once gathered, it depletes.
- Depleted resources respawn after ~30 minutes with a new random resource appropriate to the biome.
- **NPCs also spawn randomly on tiles** based on biome, with ~30 minute respawn (+/- 5 min variance).
- Hostile NPCs can be attacked; friendly NPCs can be interacted with (vendors, quest givers, etc.)
- This system is separate from profession-based `GatheringNode` which requires specific professions.

## How Spawning Works

### Resource Spawning Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                    RESOURCE SPAWN FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Player visits tile (zone, x, y)                                │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ TileResource.at_tile│◄──── Check DB for existing resource   │
│  └─────────────────────┘                                        │
│            │                                                    │
│     Found? │                                                    │
│            ├────Yes────► Return existing resource info          │
│            │                                                    │
│            No                                                   │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Determine biome     │◄──── From MapTileTemplate or Zone      │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ BiomeResourceConfig │◄──── Load YAML for this biome          │
│  │ .sample_resource()  │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Weighted random     │◄──── Roll based on spawn_chance        │
│  │ selection           │      (higher = more likely)            │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Create TileResource │◄──── INSERT into tile_resources        │
│  │ record              │      (unique constraint on zone,x,y)   │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  Return resource info (name, type, available, etc.)             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### NPC Spawning Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                      NPC SPAWN FLOW                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Player visits tile (zone, x, y)                                │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ TileNpc.at_tile     │◄──── Check DB for existing NPC         │
│  └─────────────────────┘                                        │
│            │                                                    │
│     Found? │                                                    │
│            ├────Yes────► Return existing NPC info               │
│            │                                                    │
│            No                                                   │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Determine biome     │◄──── From MapTileTemplate or Zone      │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ BiomeNpcConfig      │◄──── Load YAML for this biome          │
│  │ .sample_npc()       │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Weighted random     │◄──── Roll based on spawn_chance        │
│  │ selection           │      Selects NPC type                  │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Find/Create         │◄──── Lookup or create NpcTemplate      │
│  │ NpcTemplate         │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Calculate level     │◄──── base_level ± level_variance       │
│  │ with variance       │      (e.g., 3 ± 2 = Lv.1-5)            │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Create TileNpc      │◄──── INSERT with full HP, alive        │
│  │ record              │      (unique constraint on zone,x,y)   │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  Return NPC info (name, level, hp, role, etc.)                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Respawn Algorithm

```
┌─────────────────────────────────────────────────────────────────┐
│                     RESPAWN FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Resource gathered / NPC defeated                               │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Calculate respawn   │                                        │
│  │ duration            │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            │   RESOURCES:                                       │
│            │   base = 30 minutes                                │
│            │   + biome_modifier (forest: -5min, mountain: +10)  │
│            │   + rarity_modifier (rare: +15min, epic: +30min)   │
│            │   clamp(10min, 2hours)                             │
│            │                                                    │
│            │   NPCs:                                            │
│            │   base = 30 minutes                                │
│            │   + random(-5min, +5min)  ◄── variance             │
│            │   + biome_modifier (forest: -3min, mountain: +5)   │
│            │   + rarity_modifier (rare: +10, elite: +20)        │
│            │   clamp(10min, 3hours)                             │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Set respawns_at     │◄──── Time.current + duration           │
│  │ timestamp           │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Schedule background │◄──── TileResourceRespawnJob or         │
│  │ job                 │      TileNpcRespawnJob                 │
│  └─────────────────────┘                                        │
│            │                                                    │
│            │   ... time passes ...                              │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Job executes        │◄──── At respawns_at time               │
│  │ .respawn!           │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Select NEW random   │◄──── Different resource/NPC may spawn! │
│  │ entity from biome   │                                        │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────┐                                        │
│  │ Update record       │◄──── Reset HP, clear defeated_at,      │
│  │                     │      set new key/type, clear respawns  │
│  └─────────────────────┘                                        │
│            │                                                    │
│            ▼                                                    │
│  Entity is now available for next player visit                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Weighted Random Selection

The `spawn_chance` value determines how likely each resource/NPC is to spawn:

```ruby
# Example: Forest biome resources
resources = [
  { key: "oak_wood",      spawn_chance: 35 },  # 35% chance
  { key: "birch_wood",    spawn_chance: 25 },  # 25% chance
  { key: "moonleaf_herb", spawn_chance: 20 },  # 20% chance
  { key: "wild_berries",  spawn_chance: 15 },  # 15% chance
  { key: "ancient_oak",   spawn_chance: 5  },  # 5% chance (rare!)
]
# Total: 100

# Algorithm:
total_weight = 100
roll = rand(100)  # e.g., 42

cumulative = 0
resources.each do |r|
  cumulative += r[:spawn_chance]
  return r if roll < cumulative
  # roll=42: oak(35) no, birch(60) yes! → birch_wood selected
end
```

### Key Design Decisions

1. **One entity per tile** — Unique constraint on (zone, x, y) prevents duplicates
2. **Lazy spawning** — Resources/NPCs only spawn when player visits, not pre-populated
3. **Random on respawn** — A new random entity spawns, not the same one
4. **Server-authoritative** — All spawning logic runs server-side
5. **Background jobs** — Respawns handled asynchronously, not blocking requests
6. **Biome inheritance** — Tile biome → Zone biome → "plains" fallback

---

## Key Concepts

### Biome-Based Resources
Each biome type spawns specific resources:

| Biome | Resource Types | Examples |
|-------|---------------|----------|
| Plains | Ore, Herb | Iron Ore, Copper Ore, Healing Herb, Flax Plant |
| Forest | Wood, Herb | Oak Wood, Birch Wood, Moonleaf Herb, Wild Berries |
| Mountain | Ore, Crystal | Gold Vein, Silver Ore, Mythril Ore, Crystal Formation |
| Swamp | Herb, Ore | Swamp Moss, Poison Bloom, Bog Iron, Glowing Mushroom |
| Lake/River | Fish, Herb | Common Fish, Golden Carp, Water Lily, River Pearl |
| City | None | No natural resources spawn in cities |

### Resource Rarity
Resources have rarity tiers affecting spawn weights and respawn times:
- **Common** (highest spawn chance, 30min respawn)
- **Uncommon** (moderate spawn chance, 30min respawn)
- **Rare** (+15min respawn penalty)
- **Epic** (+30min respawn penalty)

### Respawn Mechanics
- Base respawn time: **30 minutes**
- Biome modifiers: Forest (-5min), Mountain (+10min), Swamp (-2min)
- Rarity modifiers: Rare (+15min), Epic (+30min)
- Min/max bounds: 10 minutes to 2 hours

## User Flow

```
1. Player navigates to a map tile
2. System checks for existing TileResource at (zone, x, y)
3. If none exists, spawns random resource based on biome
4. UI shows "Gather [Resource Name]" button if available
5. Player clicks gather button
   ↓
6. TileGatheringService.gather! called
7. Resource quantity decremented
8. Item added to player inventory
9. If depleted (qty = 0):
   - Set respawns_at timestamp
   - Schedule TileResourceRespawnJob
10. UI shows success message with item gained
11. Resource shows "Depleted - Respawns in X:XX" until ready
```

## Technical Implementation

### Models

**TileResource** (`app/models/tile_resource.rb`)
- Tracks resource at specific (zone, x, y) coordinates
- Fields: zone, x, y, biome, resource_key, resource_type, quantity, respawns_at
- Unique index on (zone, x, y)
- Scopes: `.available`, `.depleted`, `.needs_respawn`

**ItemTemplate** (extended)
- Added `key` column for unique resource identification
- Added `item_type` column: "equipment", "material", "consumable"
- Materials bypass `stat_modifiers` validation

### Services

**Game::World::TileGatheringService**
- Orchestrates gathering: find/spawn resource, harvest, add to inventory
- Creates ItemTemplate on-the-fly if not seeded
- Returns structured result with success/failure, item details, respawn info

**Game::World::BiomeResourceConfig**
- Loads `config/gameplay/biome_resources.yml`
- Provides weighted random selection based on spawn_chance
- Methods: `.for_biome`, `.sample_resource`, `.respawn_modifier`

### Jobs

**TileResourceRespawnJob**
- Enqueued when resource depletes
- Scheduled for respawn_duration into future
- Calls `TileResource#respawn!` which selects new random resource

### Controller

**WorldController#gather_resource** (POST /world/gather_resource)
- Validates character position
- Delegates to TileGatheringService
- Returns HTML/Turbo Stream/JSON response
- Updates action panel and location info via Turbo

### Views

**world/_actions.html.erb**
- Shows "Gather [Resource]" button when resource available
- Shows depleted state with respawn countdown when unavailable
- Uses `resource_icon` helper for visual indicators

### Configuration

**config/gameplay/biome_resources.yml**
```yaml
forest:
  respawn_modifier: -300  # 5 minutes faster
  resources:
    - key: oak_wood
      type: wood
      name: Oak Wood
      quantity: 2
      spawn_chance: 35
      metadata:
        rarity: common
```

## Routes

```ruby
resource :world, only: [:show] do
  collection do
    post :gather_resource  # NEW
    # ... other actions
  end
end
```

## UI/UX

### Gather Button Styles
- Color-coded by resource type (green=herb, gray=ore, brown=wood, blue=fish, purple=crystal)
- Hover effect with glow matching resource color
- Active/pressed state feedback

### Depleted State
- Grayed out resource icon
- Strike-through resource name
- Gold badge showing respawn countdown (e.g., "Respawns in 25m 30s")

## Responsible for Implementation Files

### Models
- `app/models/tile_resource.rb` — TileResource model with harvest/respawn logic
- `app/models/item_template.rb` — Extended with key, item_type, material support

### Services
- `app/services/game/world/tile_gathering_service.rb` — Gathering orchestration
- `app/services/game/world/biome_resource_config.rb` — YAML config loader

### Jobs
- `app/jobs/tile_resource_respawn_job.rb` — Background respawn scheduler

### Controllers
- `app/controllers/world_controller.rb` — #gather_resource action

### Views
- `app/views/world/_actions.html.erb` — Gather button UI

### Helpers
- `app/helpers/world_helper.rb` — resource_icon, format_time_remaining

### Configuration
- `config/gameplay/biome_resources.yml` — Biome resource definitions

### Database
- `db/migrate/20251127180441_create_tile_resources.rb` — Creates tile_resources table
- `db/seeds.rb` — Resource ItemTemplates (26 material items)

### Factories
- `spec/factories/tile_resources.rb` — Test factory

### Specs
- `spec/models/tile_resource_spec.rb` — Model specs

## Testing & QA

### Model Tests
- Validation of required fields
- Scope behavior (available, depleted, at_tile)
- Harvest mechanics (quantity decrement, harvester tracking)
- Respawn mechanics (time calculation, biome selection)

### Integration Points
- Inventory system: Items added via `Game::Inventory::Manager`
- Position system: Uses `character.position` (not `current_position`) → `CharacterPosition`
- Zone system: Uses `Zone#biome` for resource type determination
- Combat system: Attack via `start_combat_path(npc_template_id:, tile_npc_id:)`
  - See `doc/COMBAT_SYSTEM_GUIDE.md` for full combat mechanics
  - Action Points scale with level and agility: `50 + (level * 3) + (agility * 2)`

### Important Model Notes
- `Character` has `has_one :position` (not `current_position`)
- `NpcTemplate` stores stats in `metadata` JSONB column, not a `stats` attribute
  - `metadata["health"]` — NPC max HP
  - `metadata["base_damage"]` — NPC attack power
  - `metadata["stats"]` — Optional full stats hash
- `TileResource.at_tile(zone, x, y)` — Class method returning single record
- `TileNpc.at_tile(zone, x, y)` — Class method returning single record

---

## Tile NPC Spawning

### Concept
Similar to resources, NPCs spawn randomly on tiles based on biome. Hostile NPCs can be attacked for combat/loot, while friendly NPCs offer services like trading, quests, or training.

### Biome NPCs

| Biome | Hostile NPCs | Friendly NPCs | Respawn Modifier |
|-------|--------------|---------------|------------------|
| Plains | Wild Boar, Plains Wolf, Bandit Scout | Wandering Merchant, Lost Traveler | +0 |
| Forest | Forest Wolf, Giant Spider, Goblin Scout, Forest Bear | Forest Sprite, Hermit Druid | -3 min |
| Mountain | Mountain Goat, Rock Elemental, Harpy, Mountain Troll | Dwarven Prospector | +5 min |
| Swamp | Giant Swamp Rat, Bog Zombie, Poison Frog, Swamp Hag | - | -2 min |
| Lake | Lake Serpent, Giant Crab | Water Sprite, Old Fisherman | +0 |
| River | River Crocodile, River Troll, Giant Otter | - | -1 min |
| City | *(none)* | *(placed NPCs only)* | N/A |

### Respawn Mechanics
- **Base respawn time:** 30 minutes
- **Random variance:** ±5 minutes (25-35 min range)
- **Biome modifiers:** Forest (-3min), Mountain (+5min), Swamp (-2min)
- **Rarity modifiers:** Rare (+10min), Elite (+20min), Boss (+60min)
- **Min/max bounds:** 10 minutes to 3 hours

### NPC Roles

| Role | Behavior | Actions |
|------|----------|---------|
| `hostile` | Can be attacked | Attack → Combat |
| `vendor` | Sells items | Talk → Shop interface |
| `quest_giver` | Offers quests | Talk → Quest dialog |
| `trainer` | Teaches skills | Talk → Training options |
| `guard` | Zone info | Talk → Area info |
| `friendly` | Lore/flavor | Talk → Dialogue |

### Technical Implementation

**TileNpc Model** (`app/models/tile_npc.rb`)
- Tracks NPC at specific (zone, x, y) coordinates
- Fields: zone, x, y, npc_template_id, npc_key, npc_role, level, current_hp, max_hp, defeated_at, respawns_at
- Scopes: `.alive`, `.defeated`, `.hostile`, `.friendly`

**TileNpcService** (`app/services/game/world/tile_npc_service.rb`)
- Spawns random NPC when player visits tile
- Creates NpcTemplate on-the-fly if not seeded
- Returns NPC info for display

**BiomeNpcConfig** (`app/services/game/world/biome_npc_config.rb`)
- Loads `config/gameplay/biome_npcs.yml`
- Weighted random selection based on `spawn_chance`
- Separate pools for hostile/friendly NPCs

**TileNpcRespawnJob** (`app/jobs/tile_npc_respawn_job.rb`)
- Scheduled when NPC is defeated
- Spawns new random NPC from biome pool

### UI Display

```html
<!-- Alive hostile NPC -->
<div class="npc-info npc-info--hostile">
  <div class="npc-header">
    <span class="npc-icon">👹</span>
    <span class="npc-name">Wild Boar</span>
    <span class="npc-level">Lv.2</span>
  </div>
  <div class="npc-hp-bar">
    <div class="npc-hp-fill" style="width: 100%"></div>
    <span class="npc-hp-text">80/80</span>
  </div>
  <a href="/combat?npc_id=..." class="btn-attack">⚔️ Attack</a>
</div>

<!-- Defeated NPC -->
<div class="npc-defeated">
  <span class="npc-icon">💀</span>
  <span class="npc-name">Wild Boar</span>
  <span class="npc-respawn">Respawns in 25m 30s</span>
</div>
```

### Additional Files

**Models:**
- `app/models/tile_npc.rb` — TileNpc with defeat/respawn logic

**Services:**
- `app/services/game/world/tile_npc_service.rb` — NPC spawn orchestration
- `app/services/game/world/biome_npc_config.rb` — YAML config loader

**Jobs:**
- `app/jobs/tile_npc_respawn_job.rb` — Background respawn scheduler

**Configuration:**
- `config/gameplay/biome_npcs.yml` — Biome NPC definitions

**Database:**
- `db/migrate/20251128075552_create_tile_npcs.rb` — Creates tile_npcs table

**Factories:**
- `spec/factories/tile_npcs.rb` — Test factory

**Specs:**
- `spec/models/tile_npc_spec.rb` — Model specs

---

## Future Enhancements
- [ ] Gathering skill/profession bonuses to yield
- [ ] Rare resource "lucky find" events
- [ ] Tool requirements (pickaxe for ore, axe for wood)
- [ ] Party gathering bonuses
- [ ] Seasonal/event resource spawns
- [ ] Resource quality tiers (normal, high-quality, pristine)
- [ ] NPC patrol routes (move between tiles)
- [ ] NPC aggression radius (attack player on sight)
- [ ] Elite/Boss NPC spawn events
- [ ] NPC loot drops on defeat
- [ ] Party-based NPC combat

