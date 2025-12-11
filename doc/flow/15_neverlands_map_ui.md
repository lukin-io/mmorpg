# 15_neverlands_map_ui.md — Game Map & UI Flow
---
title: WEB-115 — Game Map & Layout Flow
description: Documents the game layout, tile-based world map, HP/MP vitals system, movement mechanics, and UI components inspired by classic browser MMORPGs.
date: 2025-12-06
updated: 2025-12-11
---

## Summary
This document covers the game interface implemented for Elselands, including:
- Game layout with top bar, main content area, floating players panel, and bottom chat bar
- Tile-based world map with mouse-click navigation
- HP/MP vitals bars with client-side regeneration
- City/location views with large images
- Online players panel with sorting

## Visual Reference
Original reference screenshots and source code are stored in `nl/` folder:
- `nl/map.jpg` — Tile-based world map with cursor
- `nl/map_move.jpg` — Movement timer during travel (red badge)
- `nl/city.jpg` — City location with detailed image
- `nl/main_ui.jpg` — Main game interface layout
- `nl/profile.jpg` — Character profile with equipment
- `nl/layout.jpg` — UI wireframe layout

Full analysis in `doc/features/neverlands_inspired.md`.

---

## Game Layout Structure

### Layout Template
**File:** `app/views/layouts/game.html.erb`

```
+------------------------------------------------------------+
|  TOP BAR: Name[Lv] + HP Bar + [values] | Nav Links | ✕    |
+------------------------------------------------------------+
|                                                            |
|                    MAIN CONTENT (full)                     |
|      (Map / City Image / Profile / Combat / etc.)          |
|                                                            |
|                                    +-------------------+   |
|                                    | FLOATING PLAYERS  |   |
|                                    | Sort: a-z z-a     |   |
|                                    | Location [count]  |   |
|                                    | → Player1[10]     |   |
|                                    | → Player2[15]     |   |
|                                    +-------------------+   |
+------------------------------------------------------------+
| [Action] [Say]  | Chat messages... |     Time: 18:45:30   |
+------------------------------------------------------------+
```

### Key Layout Components

**Top Bar (`.nl-top-bar`):**
- Character name as link
- Level in brackets: `[10]`
- HP bar (red, inline)
- Vitals text: `[HP/MaxHP | MP/MaxMP]`
- Navigation links: Quests, Character, Inventory, Enter/Exit
- Close button (✕)

**Main Area (`.nl-main-area`):**
- Full width content area
- Contains map or city view
- Floating players panel in bottom-right corner

**Floating Players Panel (`.nl-players-float`):**
- Sort links: a-z, z-a, 0-33, 33-0
- Auto-refresh checkbox
- Location name and player count
- Player list with faction icons

**Bottom Chat Bar (`.nl-bottom-bar`):**
- Action buttons: Действие, Сказать
- Chat messages area
- Chat input field
- Time display

### Stimulus Controller
**File:** `app/javascript/controllers/game_layout_controller.js`

**Features:**
- Players list sorting
- Auto-refresh toggle (30 second interval)
- Chat focus
- LocalStorage persistence for preferences
- Notifications

**Targets:**
- `mainContent`, `playersPanel`, `playersList`
- `chatArea`, `chatMessages`, `notifications`

---

## Top Bar Components

### Character Info & Vitals
**Partial:** `app/views/shared/_nl_vitals_bar.html.erb`

**Inline format:**
```html
<div class="nl-vitals-inline">
  <div class="nl-hp-bar-inline">
    <div class="nl-bar-fill" style="width: 75%;"></div>
  </div>
  <span class="nl-vitals-text">[75/100 | 40/80]</span>
</div>
```

### Navigation Links
```html
<nav class="nl-top-nav">
  <a class="nl-nav-link">Quests</a>
  <a class="nl-nav-link">Character</a>
  <a class="nl-nav-link">Inventory</a>
  <a class="nl-nav-link">Enter</a>  <!-- or Exit in city -->
</nav>
```

CSS: `.nl-nav-link` — Blue text (#336699), underline on hover

---

## HP/MP Vitals System

### Stimulus Controller
**File:** `app/javascript/controllers/nl_vitals_controller.js`

**Client-side regeneration formula:**
```javascript
// Per tick (1 second):
currentHp += maxHp / hpRegenRate;  // HP regen
currentMp += maxMp / mpRegenRate;  // MP regen
```

**Data Values:**
- `currentHp`, `maxHp`, `currentMp`, `maxMp`
- `hpRegenRate` (default: 1500 ticks to full)
- `mpRegenRate` (default: 9000 ticks to full)

**Targets:**
- `hpBar`, `hpFill`, `text`

---

## World Map System

### Map Partial
**File:** `app/views/world/_map.html.erb`

**Structure:**
```html
<div class="nl-map-container" data-controller="nl-world-map">
  <!-- Viewport -->
  <div class="nl-map-viewport">
    <!-- Map table with tiles -->
    <div class="nl-map-world">
      <table>
        <tr>
          <td class="nl-map-tile nl-tile-bg--plains" id="tile_5_5">
            <!-- Adjacent walkable tile: clickable -->
            <div class="nl-tile-clickable nl-tile-clickable--available"
                 data-action="click->nl-world-map#clickTile"
                 data-available="true">
            </div>
          </td>
        </tr>
      </table>
    </div>

    <!-- Overlay (cursor, timer) -->
    <div class="nl-map-overlay">
      <div class="nl-cursor">
        <div class="nl-cursor-img nl-cursor-img--idle"></div>
      </div>
      <div class="nl-timer-text" style="display: none;">
        <span class="nl-timer-seconds"></span>
      </div>
    </div>
  </div>

  <!-- Location info bar -->
  <div class="nl-map-info">
    <span class="nl-location-name">Zone Name</span>
    <span class="nl-location-coords">[10, 10]</span>
  </div>
</div>
```

### Map Navigation (Mouse-Click Only)

**File:** `app/javascript/controllers/nl_world_map_controller.js`

**Features:**
- Click on adjacent tiles to move (no keyboard navigation)
- Supports all 8 directions: cardinal (N, S, E, W) and diagonal (NE, SE, SW, NW)
- Red dashed border highlights available tiles
- Movement countdown timer (red badge with number)
- Server-side movement validation

**Movement Directions:**
The player can move to any of the 8 adjacent tiles:
- **Cardinal:** north (0, -1), south (0, +1), east (+1, 0), west (-1, 0)
- **Diagonal:** northeast (+1, -1), southeast (+1, +1), southwest (-1, +1), northwest (-1, -1)

**Movement Flow:**
1. All 8 adjacent walkable tiles display red dashed border (`.nl-tile-clickable--available`)
2. Player clicks an available tile
3. JavaScript determines direction from dx/dy offset
4. JavaScript sets cooldown in `sessionStorage` (persists across DOM updates)
5. Hidden form submits via `requestSubmit()` (Turbo handles the response)
6. Timer badge shows countdown during movement
7. Server responds with Turbo Stream to update map
8. New Stimulus controller connects, reads cooldown from `sessionStorage`
9. Cursor repositions to new location

### Critical: Turbo Stream Update Pattern

**IMPORTANT:** All map-related Turbo Stream responses MUST use `turbo_stream.update` (NOT `replace`).

Using `replace` removes the entire `<turbo-frame>` element, which prevents subsequent updates from finding their target.

**Correct Pattern:**
```ruby
# In WorldController
turbo_stream.update("game-map", partial: "world/map", locals: {...})
```

**Incorrect Pattern (DO NOT USE):**
```ruby
# This breaks subsequent updates!
turbo_stream.replace("game-map", partial: "world/map", locals: {...})
```

**Actions that update the map:**
- `move` — After successful movement
- `gather_resource` — After gathering (resource state changes)
- Any action that modifies the visible map state

### Live Tile Features

The map now shows **live data** from the database, not static procedural features.

**`add_live_tile_features(zone_name, x, y, metadata)`**

This method checks actual database records for each tile:
- **Resources**: Checks `TileResource.at_tile()` and only shows if `available?` returns true
- **NPCs**: Checks `TileNpc.at_tile()` and only shows if `alive?` returns true

This ensures:
- Depleted resources (quantity = 0) don't show resource markers
- Dead/despawned NPCs don't show NPC markers
- Map updates reflect the actual game state after each action

**Data Values:**
- `playerX`, `playerY` — Current position
- `moveUrl` — Server endpoint (`/world/move`)
- `zoneWidth`, `zoneHeight` — Zone dimensions
- `tileSize` (default: 100px)
- `moveCooldown` (default: 3 seconds)
- `zoneName` — Current zone name

### Tile Types

**Clickable States:**
```css
.nl-tile-clickable--available {
  border: 3px dashed #CC0000;  /* Red dashed border */
  animation: nl-tile-pulse 1.5s infinite;
  cursor: pointer;
}

.nl-tile-player {
  /* Player's current position - no click handler */
}

.nl-tile-inactive {
  /* Non-adjacent or unwalkable - no click handler */
}
```

**Terrain Backgrounds:**
```css
.nl-tile-bg--plains  { background: linear-gradient(...green...); }
.nl-tile-bg--forest  { background: linear-gradient(...dark green...); }
.nl-tile-bg--mountain { background: linear-gradient(...brown...); }
.nl-tile-bg--city    { background: linear-gradient(...gray...); }
.nl-tile-bg--river   { background: linear-gradient(...blue...); }
.nl-tile-bg--desert  { background: linear-gradient(...tan...); }
```

### Cursor & Timer

**Cursor (red border on player position):**
```css
.nl-cursor-img--idle {
  /* Red square border, blinking animation */
  background-image: url("...red border svg...");
  animation: nl-cursor-blink 1s infinite;
}
```

**Timer (red badge during movement):**
```css
.nl-timer-seconds {
  display: inline-block;
  padding: 2px 6px;
  background: #CC0000;
  border: 1px solid #990000;
  border-radius: 8px;
  color: #FFFFFF;
  font-weight: bold;
}
```

---

## City/Location View

### City Partial
**File:** `app/views/world/_city_view.html.erb`

**Structure:**
```html
<div class="nl-city-view">
  <!-- Large location image -->
  <div class="nl-city-image-container">
    <img class="nl-city-image" src="...">
  </div>

  <!-- Description text -->
  <div class="nl-city-description">
    <p>Location description...</p>
    <p class="nl-warning">Warning text...</p>
  </div>

  <!-- Interactive buildings (optional) -->
  <div class="city-map">...</div>
</div>
```

---

## Online Players Panel

### Players List Partial
**File:** `app/views/shared/_nl_players_list.html.erb`

**Structure:**
```html
<div class="nl-player-entry">
  <span class="nl-player-arrow">→</span>
  <span class="nl-player-icon nl-faction-light">☠</span>
  <a class="nl-player-name-link">PlayerName</a>
  <span class="nl-player-lvl">[10]</span>
  <span class="nl-player-status">g</span>
</div>
```

**Faction Icons:**
- `.nl-faction-light` — Blue (#0052A6)
- `.nl-faction-dark` — Red (#CC0000)
- `.nl-faction-neutral` — Green (#087C20)

---

## CSS Theme (Light)

```css
.nl-game-layout {
  --nl-bg: #FFFFFF;
  --nl-border: #CCCCCC;
  --nl-border-gold: #DECFA6;
  --nl-text: #000000;
  --nl-text-dim: #666666;
  --nl-link: #336699;
  --nl-hp-fill: #CC0000;
  --nl-mp-fill: #336699;
}
```

---

## Implementation Files

**Layout:**
- `app/views/layouts/game.html.erb`
- `app/javascript/controllers/game_layout_controller.js`
- `app/assets/stylesheets/application.css` (`.nl-*` classes)

**Vitals:**
- `app/views/shared/_nl_vitals_bar.html.erb`
- `app/javascript/controllers/nl_vitals_controller.js`

**Map:**
- `app/views/world/_map.html.erb`
- `app/views/world/show.html.erb`
- `app/javascript/controllers/nl_world_map_controller.js`
- `app/controllers/world_controller.rb`

**City:**
- `app/views/world/_city_view.html.erb`

**Online Players:**
- `app/views/shared/_nl_players_list.html.erb`

**Documentation:**
- `doc/features/neverlands_inspired.md` — Feature reference with original source
- `doc/MAP_DESIGN_GUIDE.md` — Map architecture guide

---

## Testing

### RSpec Coverage

**Request Specs:** `spec/requests/world_spec.rb`
- Movement in all 8 directions (cardinal: north, south, east, west + diagonal: northeast, southeast, southwest, northwest)
- Boundary checking (can't move outside zone)
- Turbo stream responses
- Zone transitions (enter/exit)

**Service Specs:** `spec/services/game/movement/turn_processor_spec.rb`
- Movement in all 4 cardinal directions
- Movement in all 4 diagonal directions (northeast, southeast, southwest, northwest)
- Cooldown enforcement
- Terrain modifiers

**View Specs:**
- `spec/views/world/_map_spec.rb` — Map rendering, clickable tiles, cursor, timer
- `spec/views/shared/_nl_vitals_bar_spec.rb` — Vitals bar format, HP/MP display
- `spec/views/layouts/game_spec.rb` — Layout structure, top bar, players panel
- `spec/views/shared/_nl_players_list_spec.rb` — Players list rendering

### Manual Testing Checklist
- [ ] Map tiles render with correct terrain backgrounds
- [ ] All 8 adjacent tiles (cardinal + diagonal) show red dashed border
- [ ] Click on adjacent tile triggers movement in correct direction
- [ ] Diagonal movement works (NE, SE, SW, NW)
- [ ] Timer badge shows countdown during movement
- [ ] Non-adjacent tiles are not clickable
- [ ] Cursor shows on player position
- [ ] HP bar displays correctly in top bar
- [ ] Navigation links work (Quests, Character, Inventory)
- [ ] Floating players panel displays correctly
- [ ] Chat input in bottom bar works
