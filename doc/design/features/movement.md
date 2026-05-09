# Movement

## Purpose

Movement gives the world weight. Outdoor travel should feel deliberate,
server-authored, and interruptible by local context. City movement is separate:
it is node-to-node navigation through illustrated hotspots.

## Neverlands Reference

Primary references:

- `doc/flow/neverlands_live_movement.md`
- `doc/flow/neverlands_live_city_movement.md`

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

## Out Of Scope

- Long-distance pathfinding as the first movement interaction.
- Browser-only cooldowns.
- City travel countdowns for the starter city.
