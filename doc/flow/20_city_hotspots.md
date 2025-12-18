# City Hotspots System

## Version History
- **v1.0** (2024-12-18): Initial implementation - interactive illustrated city view with building hotspots

## Overview
The City Hotspots system provides an interactive illustrated city view for city-type zones. Instead of a tile-based map grid, players see a visual illustration with clickable building hotspots. Each hotspot can lead to different game features (arena, crafting, healing) or zone transitions.

Inspired by Neverlands' city view where buildings highlight on hover and clicking navigates to specific features.

## GDD Reference
- Feature: City interior navigation via illustrated view
- Inspired by: Neverlands city location system

## Implementation Notes

### Key Design Decisions
1. **City biome detection** - Zones with `biome: "city"` render the illustrated view instead of tile grid
2. **Overlay positioning** - Each hotspot is positioned at exact pixel coordinates on `city.png` background
3. **Highlight-on-hover effect** - Overlay images (same size as building areas in city.png) are hidden by default (opacity: 0) and shown on hover (opacity: 1), creating a "highlight" effect
4. **Flexible actions** - Hotspots can navigate to zones (`enter_zone`) or features (`open_feature`)

### How the Overlay System Works
The city view displays `city.png` (1536×1024) as the background. Each building in the illustration has a corresponding overlay image (e.g., `arena.png`) that is:

1. **Same dimensions** as that building's area in city.png
2. **Positioned absolutely** at the exact pixel coordinates where the building appears
3. **Invisible by default** (opacity: 0)
4. **Visible on hover** (opacity: 1), creating a highlight/glow effect

This matches the Neverlands approach where hovering over a building area shows its highlight overlay:
```html
<img src="loc5_b.png"   <!-- Normal: invisible/transparent -->
     onmouseover="this.src = 'loc5_b_hl.png';"  <!-- Hover: highlighted -->
     onmouseout="this.src='loc5_b.png';" />
```

### Hotspot Types
| Type | Purpose | Clickable |
|------|---------|-----------|
| `building` | Interactive buildings (arena, workshop) | Yes |
| `exit` | Zone transition (leave city) | Yes |
| `feature` | Opens game feature panel | Yes |
| `decoration` | Visual only (trees, fountains) | No |

### Action Types
| Action | Behavior |
|--------|----------|
| `enter_zone` | Move character to destination_zone |
| `open_feature` | Navigate to feature URL (/arena, /crafting) |
| `none` | No action (decorations) |

### Entry Flow
1. Player enters city zone (via TileBuilding)
2. WorldController detects `biome == "city"`
3. City view rendered with background + hotspots
4. Hotspots positioned absolutely on illustration
5. Hover → image swap + tooltip
6. Click → form submission → interact_hotspot action

### Image Assets
**Background:** `app/assets/images/city.png` (1536 x 1024)

**Overlay images** (stored in `image_hover` field):
| Hotspot | Overlay Image | Purpose |
|---------|---------------|---------|
| Arena | `arena.png` | PvP battles feature |
| Workshop | `workshop.png` | Crafting feature |
| Clinic | `clinic.png` | Healing feature |
| Gate | `gate.png` | Exit to world map |
| House | `house.png` | Player housing |
| Tree | `tree.png` | Decoration (no action) |

**Note:** Each overlay image must be:
- Cropped to the exact building area size
- Positioned using `position_x`/`position_y` matching city.png coordinates
- The image's natural dimensions define the clickable area

## Hotwire Integration

### Views
- `app/views/world/city_view.html.erb` - Main city view (replaces map)
- `app/views/world/_city_hotspot.html.erb` - Individual hotspot partial

### Stimulus Controller
`city_view_controller.js`:
- `showOverlay` action: Add `city-hotspot-overlay--visible` class (opacity → 1)
- `hideOverlay` action: Remove visible class (opacity → 0)
- `showTooltip` / `hideTooltip`: Display building names at cursor
- `moveTooltip`: Position tooltip following cursor movement

### Turbo
- `interact_hotspot` returns either:
  - Redirect to feature page (arena, crafting)
  - Map update for zone transitions

## Game Engine Classes
- `CityHotspot` - ActiveRecord model for hotspot definitions
- `Game::World::CityHotspotService` - Hotspot info and interaction logic

## Responsible for Implementation Files

### Models
- `app/models/city_hotspot.rb` - CityHotspot model with validations, scopes, interaction methods

### Controllers
- `app/controllers/world_controller.rb` - Updated with city_zone?, render_city_view, interact_hotspot

### Views
- `app/views/world/city_view.html.erb` - City view template
- `app/views/world/_city_hotspot.html.erb` - Hotspot partial

### JavaScript
- `app/javascript/controllers/city_view_controller.js` - Stimulus controller for hover/tooltip

### Services
- `app/services/game/world/city_hotspot_service.rb` - Hotspot retrieval and interaction

### Styles
- `app/assets/stylesheets/application.css` - City view CSS (appended)

### Routes
- `config/routes.rb` - Added `interact_hotspot` POST route

### Database
- `db/migrate/TIMESTAMP_create_city_hotspots.rb` - Migration for city_hotspots table
- `db/seeds.rb` - Seed data for Castleton Keep hotspots

### Specs
- `spec/models/city_hotspot_spec.rb` - Model specs
- `spec/services/game/world/city_hotspot_service_spec.rb` - Service specs
- `spec/factories/city_hotspots.rb` - Factory definitions

## Database Schema

```ruby
create_table :city_hotspots do |t|
  t.references :zone, null: false, foreign_key: true
  t.string :key, null: false              # Unique identifier within zone
  t.string :name, null: false             # Display name (shown in tooltip)
  t.string :hotspot_type, null: false     # building, exit, decoration, feature
  t.integer :position_x, null: false      # Pixels from left of city.png
  t.integer :position_y, null: false      # Pixels from top of city.png
  t.string :image_normal                  # (Not used - kept for compatibility)
  t.string :image_hover                   # Overlay image shown on hover
  t.string :action_type, null: false      # enter_zone, open_feature, none
  t.references :destination_zone          # Target zone for enter_zone
  t.jsonb :action_params, default: {}     # { "feature" => "arena" }
  t.integer :required_level, default: 1   # Min level to interact
  t.boolean :active, default: true        # Can be interacted with
  t.integer :z_index, default: 0          # Layering order (higher = on top)
  t.timestamps
end
```

### Indexes
- `[zone_id, key]` - Unique hotspot per zone
- `hotspot_type` - Type filtering
- `active` - Active hotspot filtering

## Usage Examples

### Creating a City Hotspot
```ruby
CityHotspot.create!(
  zone: castleton,
  key: "arena",
  name: "Arena",
  hotspot_type: "building",
  position_x: 600,      # X position in city.png where building starts
  position_y: 100,      # Y position in city.png where building starts
  image_hover: "arena.png",  # Overlay image (same size as building area)
  action_type: "open_feature",
  action_params: { "feature" => "arena" },
  required_level: 5,
  active: true,
  z_index: 20
)
```

### Determining Hotspot Position
To find the correct `position_x`/`position_y` for a building:
1. Open `city.png` in an image editor
2. Find the pixel coordinates of the building's top-left corner
3. Ensure the overlay image starts at those exact coordinates

### Service Usage
```ruby
service = Game::World::CityHotspotService.new(
  character: current_character,
  zone: current_zone
)

if service.city_zone?
  hotspots = service.hotspots_for_display
  # Render city view with hotspots
end

# Handle hotspot interaction
result = service.interact!(hotspot_id)
if result.success
  if result.redirect_url
    redirect_to result.redirect_url
  elsif result.destination_zone
    # Zone transition - reload world view
  end
end
```

## CSS Structure
```css
.city-view-container         /* Main container with background */
.city-view                   /* Background image (city.png) */
.city-hotspot                /* Absolutely positioned hotspot div */
.city-hotspot--building|exit|decoration|feature  /* Type variants */
.city-hotspot-button         /* Clickable button (transparent) */
.city-hotspot-form           /* Form wrapper for hotspot actions */
.city-hotspot-overlay        /* Overlay image (opacity: 0 → 1 on hover) */
.city-hotspot-overlay--visible  /* Active hover state */
.city-hotspot-overlay--locked   /* Grayscale for locked hotspots */
.city-hotspot-lock           /* Lock icon for blocked buildings */
.city-hotspot-hitbox         /* Fallback clickable area if no image */
.city-tooltip                /* Tooltip following cursor */
```

## Future Enhancements
- Animated hotspots (GIF support)
- Time-of-day city backgrounds
- Weather effects overlay
- NPC indicators on hotspots
- Quest markers on buildings
- Multiple city layouts per zone (seasonal)
- Hotspot sounds on hover/click

