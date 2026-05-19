# Movement

## Purpose

Movement gives the world weight. Outdoor travel should feel deliberate,
server-authored, and interruptible by local context. City movement is separate:
it is node-to-node navigation through illustrated hotspots.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/source_material.md`

Observed split:

| Movement Type | Feel | State Shape |
| --- | --- | --- |
| Wilderness | timed coordinate travel | current tile, offered destinations, countdown |
| City | immediate illustrated hotspot navigation | current city node, offered hotspots |
| Building | immediate feature entry/return | current building, parent city node |

## Player Experience

On the world map, the player sees nearby clickable destinations. Clicking one
starts a visible travel countdown. During travel, movement and conflicting
actions are locked. On completion, the current location, nearby actions, and
local player list refresh.

In a city, the player clicks a district or building hotspot and immediately
arrives at the new node or building.

## Wilderness Rules

- The server decides which nearby tiles are reachable.
- Each offered destination includes target coordinates, travel time, and an
  action key.
- The browser only renders server-offered destinations as clickable.
- Accepted movement creates a travel state with start and end timestamps.
- Character position finalizes when travel completes.
- Reload during travel resumes the remaining countdown.
- Completion refreshes available actions and local presence.
- Passability and travel time are server rules, not browser rules.

## Persistence Contract

Neverlands-style movement is persistent server state, not browser state.

Authoritative state:

- a character location record stores the finalized coordinate and zone;
- a movement command record stores each offered, accepted, active, completed,
  failed, or cancelled movement;
- an accepted movement does not immediately change the finalized character
  location.
- Active movement stores source coordinate, target coordinate, start time,
  end time, travel duration, and action key.
- Reopening the browser must load from database state:
  - if no movement is active, the player appears at the finalized coordinate;
  - if movement is active and not due, the countdown resumes from `ends_at`;
  - if movement is due, the server finalizes it before rendering the map.
- Login with an existing character enters the world screen directly and uses the
  same persisted position/resume logic. It must not route the player to an
  unrelated dashboard before the game surface.

Expected player result: if a player walks in the open world, closes the browser,
and opens the game later, they are still at the same finalized cell or at the
completed destination if the travel timer elapsed while they were away.

## City Rules

- City entry is a contextual action offered by an outside tile.
- City nodes are named locations in a graph.
- City node transitions are immediate unless explicitly designed otherwise.
- Building entry is a city hotspot action.
- Building return goes to the parent city node via `Город`.
- Leaving a city returns to an outside map tile.

## Travel Time

Baseline formula:

```text
travel_seconds =
  base_zone_seconds
  * terrain_modifier
  * diagonal_modifier
  * encumbrance_modifier
  / mount_multiplier
  * skill_modifier
```

Initial starter reference: `30` seconds for a normal adjacent wilderness step
near Oktal.

## State Concepts

- finalized coordinate;
- active movement source coordinate;
- active movement target coordinate;
- movement start time;
- movement end time;
- remaining seconds;
- reachable destination offers;
- contextual action offers;
- locked reason.

## Interactions

- `areas/world_map.md` owns the outdoor screen.
- `areas/cities_and_buildings.md` owns city and building movement.
- `features/gathering_professions.md` can lock movement while an action timer
  runs.
- `features/progression_stats_skills.md` can reduce travel time through skills.
- `features/items_inventory_equipment.md` can increase travel time through
  carried weight.

## Rails-Friendly Direction

The open-world map should use one server-authored state-building pipeline:

1. Finalize due movement for the character.
2. Load the current authoritative character location.
3. Materialize tile context for the current location:
   - resources;
   - NPCs;
   - building, city, dungeon, or portal entrances;
   - terrain and passability.
4. Create short-lived action offers for everything the player can do:
   - movement offers;
   - gather offers;
   - attack/talk offers;
   - enter city/building/dungeon offers;
   - inspect/profile/inventory offers when needed by the UI.
5. Render only those offers to the browser.
6. Accept an action only when its action key still matches the current
   character, zone, coordinate, target, and action type.

Suggested Rails shape:

- one model for finalized character location;
- one model for movement commands and their lifecycle;
- one model for short-lived contextual action offers;
- one service that builds tile state and offers from persisted state;
- one service that accepts an action key and dispatches to movement,
  gathering, NPC, combat, or building-entry rules.

Movement and non-movement tile actions should both produce auditable server
state. The browser should submit choices, not decide what choices exist.

## Out Of Scope

- Long-distance pathfinding as the first movement interaction.
- Browser-only cooldowns.
- City travel countdowns for the starter city.
