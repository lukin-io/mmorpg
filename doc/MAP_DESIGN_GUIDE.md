# MAP_DESIGN_GUIDE.md — Zone & Grid Architecture for Neverlands MMORPG

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

# 8. Environmental Effects

Example effects:
- fog (reduces visibility)
- fire (damage tile)
- slow zones

Suggest store effects in:
```
tile.effects = [ { name: "fire", damage: 2 } ]
```

---

# 9. Dynamic vs Static Maps

## Static
- handcrafted
- loaded from assets

## Dynamic
- procedural generation
- dungeon layouts
- randomized terrain

Both can be supported.

---

# 10. Summary

Use this guide when implementing:
- zones
- map rendering
- tile interactions
- movement rules
- environmental effects
- pathfinding

This ensures consistent world design in the Rails MMORPG engine.
