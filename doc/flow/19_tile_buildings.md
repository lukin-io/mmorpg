# Tile Buildings System

## Version History
- **v1.0** (2024-12-16): Initial implementation - buildings on map tiles with enter/exit functionality
- **v1.1** (2024-12-16): Added comprehensive specs (model, service, request), updated documentation guides

## Overview
The Tile Buildings system allows placing enterable structures (castles, forts, inns, dungeons, portals) on specific map tiles. Players can see building icons on the map and enter them to transition to interior zones.

## GDD Reference
- Feature spec: Custom implementation for zone transitions via map structures

## Implementation Notes

### Key Design Decisions
1. **Follows TileNpc/TileResource pattern** - Buildings are stored with zone name + x,y coordinates for consistent map tile integration
2. **Optional destination zones** - Buildings without destinations still appear on map (useful for visual markers or future features)
3. **Level/faction requirements** - Buildings can restrict entry based on character level or faction
4. **Metadata for extensions** - Quest requirements, dungeon keys, and other data stored in JSONB metadata

### Building Types
- `castle` - Main city/stronghold entrances
- `fort` - Military outposts
- `inn` - Rest locations
- `shop` - Merchant buildings
- `dungeon_entrance` - Dungeon entry points
- `portal` - Magical transport points
- `guild_hall` - Guild headquarters
- `tavern` - Social hubs
- `temple` - Religious sites

### Entry Flow
1. Player navigates to tile with building
2. Building appears in actions panel with "Enter" button
3. Player clicks enter → `enter_building` action validates requirements
4. Character position updated to destination zone
5. Map and actions refresh via Turbo

### Map Display
Buildings appear as icons on the world map alongside NPCs and resources:
- 🏰 Castle
- 🏯 Fort
- 🏨 Inn
- 🏪 Shop
- ⚔️ Dungeon Entrance
- 🌀 Portal
- 🏛️ Guild Hall
- 🍺 Tavern
- ⛪ Temple

## Hotwire Integration

### Turbo Frames
- Building info displayed in `available-actions` frame
- Map tiles updated via `game-map` frame

### Turbo Streams
- `enter_building` action returns stream response updating map after zone transition

### Stimulus
- Uses existing `nl-world-map` controller for map interactions

## Game Engine Classes
- `TileBuilding` - ActiveRecord model for building data
- `Game::World::TileBuildingService` - Service for building info and entry logic

## Responsible for Implementation Files

### Models
- `app/models/tile_building.rb` - TileBuilding model with validations, scopes, and entry logic

### Controllers
- `app/controllers/world_controller.rb` - Updated with `enter_building` action and building helpers

### Views
- `app/views/world/_map.html.erb` - Building markers on map tiles
- `app/views/world/_actions.html.erb` - Building interaction UI in actions panel

### Services
- `app/services/game/world/tile_building_service.rb` - Building info retrieval and entry handling

### Routes
- `config/routes.rb` - Added `enter_building` POST route

### Database
- `db/migrate/TIMESTAMP_create_tile_buildings.rb` - Migration for tile_buildings table
- `db/seeds.rb` - Seed data for castle entrances and example buildings

### Specs
- `spec/models/tile_building_spec.rb` - Model validations, scopes, methods, edge cases (105 examples)
- `spec/services/game/world/tile_building_service_spec.rb` - Service functionality, edge cases (38 examples)
- `spec/requests/world_spec.rb` - enter_building controller action specs (40+ examples)
- `spec/factories/tile_buildings.rb` - Factory definitions with traits

## Database Schema

```ruby
create_table :tile_buildings do |t|
  t.string :zone, null: false           # Zone name where building appears
  t.integer :x, null: false             # X coordinate on map
  t.integer :y, null: false             # Y coordinate on map
  t.string :building_key, null: false   # Unique identifier
  t.string :building_type, null: false  # castle, fort, inn, etc.
  t.string :name, null: false           # Display name
  t.references :destination_zone        # Zone to enter (optional)
  t.integer :destination_x              # Spawn X in destination
  t.integer :destination_y              # Spawn Y in destination
  t.string :icon                        # Custom emoji icon
  t.integer :required_level, default: 1 # Min level to enter
  t.string :faction_key                 # Faction restriction
  t.jsonb :metadata, default: {}        # Additional data
  t.boolean :active, default: true      # Can be entered
  t.timestamps
end
```

### Indexes
- `[zone, x, y]` - Unique tile lookup
- `building_key` - Unique key lookup
- `building_type` - Type filtering
- `active` - Active building filtering

## Usage Examples

### Creating a Castle Entrance
```ruby
TileBuilding.create!(
  zone: "Starter Plains",
  x: 7,
  y: 0,
  building_key: "castleton_gate",
  building_type: "castle",
  name: "Castleton Keep Gates",
  destination_zone: Zone.find_by(name: "Castleton Keep"),
  destination_x: 5,
  destination_y: 9,
  icon: "🏰",
  required_level: 1,
  metadata: { "description" => "Main gates to Castleton Keep" }
)
```

### Checking Building at Tile
```ruby
service = Game::World::TileBuildingService.new(
  character: current_character,
  zone: "Starter Plains",
  x: 7,
  y: 0
)

if service.building_present?
  info = service.building_info
  puts "Found: #{info[:name]}"

  if info[:can_enter]
    result = service.enter!
    puts result.message
  else
    puts "Cannot enter: #{info[:blocked_reason]}"
  end
end
```

## Future Enhancements
- Building interiors with NPC placement
- Quest-locked buildings
- Guild-owned structures
- Building upgrades/customization
- Time-limited access (events)
- Building discovery/exploration tracking

