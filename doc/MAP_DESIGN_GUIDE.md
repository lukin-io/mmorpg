# MAP_DESIGN_GUIDE.md — Zone & Grid Architecture for Elselands MMORPG

This guide explains how maps, zones, tiles, and world layout are implemented
inside the Rails game engine.

---

# 1. Philosophy

Your maps must be:
- tile-based
- deterministic
- server-authoritative
- simple to render via Turbo

Zones are defined in DB.
Grids/tiles are built dynamically at runtime or loaded from JSON/YAML.

---

# 2. Zone Model

```
Zone
  id
  name
  width
  height
  terrain_data (JSON) ← serialized tiles
```

---

# 3. Tile Structure

```
Tile {
  x: Integer
  y: Integer
  passable: Boolean
  terrain: String ("grass", "mountain", "forest")
  effects: [] (optional)
}
```

Tiles are POROs (not stored individually in the DB).

---

# 4. Rendering Maps with Turbo

Use Turbo Frames:

```
<turbo-frame id="zone-map">
  <%= render "zones/map", zone: @zone %>
</turbo-frame>
```

Tiles can be rendered as:

```erb
<div class="tile <%= tile.terrain %> <%= 'blocked' unless tile.passable? %>">
  ...
</div>
```

Turbo Streams can update:
- player movement
- NPC movement
- tile effects (fire, poison fog, etc.)

---

# 5. Loading Maps

You may store maps as:
- JSON file per zone
- YAML file per zone
- DB field `terrain_data`

Example JSON:

```json
{
  "width": 30,
  "height": 20,
  "tiles": [
    {"x":0,"y":0,"passable":true,"terrain":"grass"},
    ...
  ]
}
```

---

# 6. Movement Rules

- characters move tile-by-tile
- cannot move through blocked tiles
- cannot occupy same tile unless in battle
- pathfinding handled by:
  ```
  Game::Movement::Pathfinder
  ```

Suggested algorithms:
- BFS for shortest path (no weights)
- Dijkstra for weighted terrain
- A* for advanced movement

---

# 7. Spawn Points

A zone can define:

```
spawn_points: [
  { x: 2, y: 3, type: "player" },
  { x: 10, y: 5, type: "wolf" }
]
```

Or define an NPC spawner service.

---

# 8. Tile Buildings (Enterable Structures)

Buildings are placed at specific tile coordinates and allow zone transitions.

## 8.1 TileBuilding Model

```
TileBuilding
  zone: String        # Zone name where building appears
  x: Integer          # X coordinate
  y: Integer          # Y coordinate
  building_key: String # Unique identifier
  building_type: String # castle, fort, inn, shop, dungeon_entrance, portal, etc.
  name: String        # Display name
  destination_zone: Zone # Zone to enter (optional)
  destination_x: Integer # Spawn X in destination (optional)
  destination_y: Integer # Spawn Y in destination (optional)
  icon: String        # Custom emoji icon
  required_level: Integer # Min level to enter
  faction_key: String # Faction restriction (optional)
  metadata: JSONB     # Additional data (description, quest requirements)
  active: Boolean     # Can be entered
```

## 8.2 Building Types

| Type | Icon | Purpose |
|------|------|---------|
| castle | 🏰 | Main city/stronghold entrances |
| fort | 🏯 | Military outposts |
| inn | 🏨 | Rest locations |
| shop | 🏪 | Merchant buildings |
| dungeon_entrance | ⚔️ | Dungeon entry points |
| portal | 🌀 | Magical transport points |
| guild_hall | 🏛️ | Guild headquarters |
| tavern | 🍺 | Social hubs |
| temple | ⛪ | Religious sites |

## 8.3 Entry Requirements

Buildings can restrict entry based on:
- Character level (`required_level`)
- Faction membership (`faction_key`)
- Quest completion (`metadata.required_quest`)
- Item possession (`metadata.required_item`)

## 8.4 Map Display

Buildings appear on tiles alongside NPCs and resources:

```erb
<%# Building marker %>
<% if tile_meta["building"].present? %>
  <div class="nl-tile-entity nl-tile-building">
    <span class="nl-entity-icon"><%= tile_meta['building_icon'] %></span>
  </div>
<% end %>
```

## 8.5 Service Usage

```ruby
service = Game::World::TileBuildingService.new(
  character: current_character,
  zone: "Starter Plains",
  x: 7,
  y: 0
)

if service.building_present?
  info = service.building_info
  result = service.enter!  # Move character to destination
end
```

---

# 9. Environmental Effects

Example effects:
- fog (reduces visibility)
- fire (damage tile)
- slow zones

Suggest store effects in:
```
tile.effects = [ { name: "fire", damage: 2 } ]
```

---

# 10. Dynamic vs Static Maps

## Static
- handcrafted
- loaded from assets

## Dynamic
- procedural generation
- dungeon layouts
- randomized terrain

Both can be supported.

---

# 11. Summary

Use this guide when implementing:
- zones
- map rendering
- tile interactions (NPCs, resources, buildings)
- movement rules
- environmental effects
- pathfinding
- zone transitions (via TileBuilding)

This ensures consistent world design in the Rails MMORPG engine.
