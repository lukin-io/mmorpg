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

The visual motion follows the captured client: cells are `100 x 100`, the
player marker remains fixed over the center cell, and the map translates one
cell beneath it for an adjacent move. Reachable cells are marked by a solid red
outline. The idle compass changes to a walking marker while a compact red timer
is centered in the cell directly above the player. Reloading partway through a
move reconstructs the partial translation and remaining time from the
server-provided timestamps.

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
- Client animation is linear presentation only; it never advances the
  finalized coordinate on its own.
- Before an offered move is accepted, a live source-backed hostile encounter on
  the current cell can replace movement with the shared fight state. The
  movement offer remains unaccepted and the finalized coordinate does not
  change.

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
  same persisted position/resume logic. If the last accessible gameplay context
  is an implemented city interior such as Shop, login resumes that interior
  without changing the persisted city position. It must not route the player to
  an unrelated dashboard before the game surface.

Expected player result: if a player walks in the open world, closes the browser,
and opens the game later, they are still at the same finalized cell or at the
completed destination if the travel timer elapsed while they were away.

An interrupted wilderness action stores only an allowlisted logical return
context on the fight. Finishing its explicit result returns to the unchanged
world cell, or to Character/Inventory when that was the interrupted shell
destination. It never stores or follows an arbitrary browser URL.

If the player logged out in Shop, login reopens Shop with its sanitized tab,
category, and numeric filters. Leaving Shop for the city records the city/world
surface again. An inaccessible Shop record falls back to that unchanged city or
outdoor position.

## City Rules

- City entry is a contextual action offered by an outside tile.
- City nodes are named locations in a graph.
- City node transitions are immediate unless explicitly designed otherwise.
- The illustrated `760 x 255` scene is the navigation surface: polygon or
  positioned regions show tooltips and submit server-owned action keys.
- Keyboard/focus proxies expose the same action names without adding a
  separate visible generic navigation menu.
- Building entry is a city hotspot action.
- Building return goes to the parent city node via `Город`.
- Leaving a city returns to an outside map tile.

## Travel Time

The clean starter reference remains `30` seconds for a normal adjacent
wilderness step near Oktal. The 2026-07-21 returning-character follow-up showed
that Neverlands sends server-calculated values per map state: a character with
Wanderer `100` received a `32`-second current step and a `49`-second next-cell
value while other source modifiers were also present.

The complete Neverlands formula is therefore still an evidence gap. For the
MVP, isolate the explicitly required Wanderer relationship against the clean
starter baseline:

```text
wanderer = clamp(effective_wanderer_level, 0, 100)
reduction_seconds = floor(wanderer * 5 / 100)
travel_seconds = clamp(30 - reduction_seconds, 25, 30)
```

This produces whole-second bands: `0..19 => 30`, `20..39 => 29`, `40..59 =>
28`, `60..79 => 27`, `80..99 => 26`, and `100 => 25`. The duration is computed
when the server creates the movement offer and remains fixed on that command
through acceptance, reload, and completion.

No terrain, diagonal, encumbrance, fatigue, effect, or profession timing
modifier is implemented. Terrain labels may identify a tile, but they must not
alter movement duration by themselves. Additional modifiers require dedicated
source observations that isolate their inputs.

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
- `features/progression_stats_skills.md` can reduce travel time through skills.
- `features/items_inventory_equipment.md` can increase travel time through
  carried weight.

## Rails-Friendly Direction

The open-world map should use one server-authored state-building pipeline:

1. Finalize due movement for the character.
2. Load the current authoritative character location.
3. Materialize tile context for the current location:
   - hidden NPC encounter state;
   - building, city, dungeon, or portal entrances;
   - authored resource-search and other captured local actions;
   - terrain, validated `100 x 100` cell art, and passability.
4. Create short-lived action offers for everything the player can do:
   - movement offers;
   - enter city/building/dungeon offers;
   - inspect/profile/inventory offers when needed by the UI.
5. Render only visible offers to the browser; resolve hidden hostile
   interruption before the selected action completes.
6. Accept an action only when its action key still matches the current
   character, zone, coordinate, target, and action type.

Suggested Rails shape:

- one model for finalized character location;
- one model for movement commands and their lifecycle;
- one model for short-lived contextual action offers;
- one service that builds tile state and offers from persisted state;
- one service that accepts an action key and dispatches to movement,
  NPC, combat, or building-entry rules.

Movement and non-movement tile actions should both produce auditable server
state. The browser should submit choices, not decide what choices exist.

## Outdoor Cell Composition

Use the existing specialized layers instead of a generic legacy `feature`
object:

| Layer | Responsibility |
| --- | --- |
| Sparse tile template | terrain/passability override and authored local-action definitions |
| Tile NPC | materialized hostile NPC state, HP, defeat, respawn, and combat target |
| Tile entrance | the three captured Forpost city gates; future entrance types require capture |
| World action offer | short-lived character/zone/coordinate/action/target authorization |

A cell can contain an NPC, an entrance, and local actions at the same time.
Movement completion rebuilds all of them. The launch resource action is
Neverlands `look` / `Оглядеться`: it searches for herbs or local resources and
can be interrupted by a hostile NPC before the resource action completes.

Movement consumes the resolved 100px cell presentation but does not own its
asset keys or sheet geometry. Add special-cell art through the authoring workflow
in `doc/features/world.md`, section 7.2; do not encode art selection in movement
commands or browser animation state.

The source client also recognizes fishing, drinking, and digging actions. Keep
those identifiers valid in authored tile data, but do not invent their rewards,
tools, timers, depletion, or profession formulas before capturing a successful
flow.

## Out Of Scope

- Long-distance pathfinding as the first movement interaction.
- Browser-only cooldowns.
- City travel countdowns for the starter city.
