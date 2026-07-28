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
- A completed wilderness step applies its snapshotted `1..2` fatigue gain.
- At effective fatigue `86%` or higher, Move, Look, and Enter are unavailable
  until natural recovery lowers the value.
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

## City And Linked-Location Rules

- City entry is a contextual action offered by an outside tile.
- City nodes are named locations in a graph.
- City node transitions are immediate unless explicitly designed otherwise.
- Current city nodes use their captured native scene geometry and
  server-offered polygon/positioned regions. Do not reuse the village size for
  city districts.
- Keyboard/focus proxies expose the same action names without adding a
  separate visible generic navigation menu.
- Building entry is a city hotspot action.
- Building return goes to the parent city node via `Город`.
- Leaving a city returns to an outside map tile.
- An outdoor `location` entrance opens an allowlisted interior without
  replacing the persisted outdoor coordinate.
- The captured village interior uses a native `760 × 255` CSS-built scene;
  Trading Post and exit polygons each submit fresh server-owned action keys.
- Linked Shop access and login resume remain valid only while the exact
  entrance cell is still active and accessible.

## Travel Time

The clean starter reference remains `30` seconds for a normal adjacent
wilderness step near Oktal. The 2026-07-21 returning-character follow-up showed
that Neverlands sends server-calculated values per map state: a character with
Wanderer `100` received a `32`-second current step and a `49`-second next-cell
value while other source modifiers were also present.

The 2026-07-28 village route added several `24`-second steps plus a `32`-second
step. The complete Neverlands formula is therefore still an evidence gap. For
the MVP, preserve an exact positive duration authored in destination metadata;
otherwise isolate the Wanderer fallback against the clean starter baseline:

```text
if destination.metadata.travel_seconds is a positive integer:
  travel_seconds = destination.metadata.travel_seconds
else:
  wanderer = clamp(effective_wanderer_level, 0, 100)
  reduction_seconds = floor(wanderer * 6 / 100)
  travel_seconds = clamp(30 - reduction_seconds, 24, 30)
```

The fallback produces whole-second bands: `0..16 => 30`, `17..33 => 29`,
`34..49 => 28`, `50..66 => 27`, `67..83 => 26`, `84..99 => 25`, and
`100 => 24`. The duration is computed when the server creates the movement
offer and remains fixed on that command through acceptance, reload, and
completion.

No inferred terrain, diagonal, encumbrance, fatigue, effect, or profession
**timing** modifier is implemented. Fatigue gates the named outdoor actions but
does not change their duration. A terrain label alone must not alter movement
duration; only the exact authored `travel_seconds` override may do so.
Additional formula modifiers require dedicated source observations that
isolate their inputs.

## Wilderness Fatigue

The Neverlands wiki supplies an exact MVP-safe fatigue slice:

- accepting a move snapshots a random gain of `1` or `2` on the movement
  command so retry/reload cannot reroll it;
- successful completion applies that gain at the authoritative movement end;
- one fatigue point recovers for each complete three-minute interval;
- the effective value is clamped to `0..100`;
- at `86` or above, the server issues no wilderness movement offers and no
  Enter/Look action offers, and acceptance rechecks the same rule;
- city node transitions are not wilderness actions and remain available.

The wiki also says high fatigue affects combat, but the penalty formula is not
complete enough to implement. Combat must not guess it.

## State Concepts

- finalized coordinate;
- active movement source coordinate;
- active movement target coordinate;
- movement start time;
- movement end time;
- remaining seconds;
- persisted fatigue and its recovery anchor;
- snapshotted per-command fatigue gain;
- reachable destination offers;
- contextual action offers;
- locked reason.

## Interactions

- `areas/world_map.md` owns the outdoor screen.
- `areas/cities_and_buildings.md` owns city and building movement.
- `features/progression_stats_skills.md` can reduce travel time through skills.
- `features/items_inventory_equipment.md` can increase travel time through
  carried weight.
- `features/professions.md` may consume an eligible cell action later, but it
  must reuse the same server-authored fatigue/action boundary.

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
| Tile entrance | captured Forpost city gates or allowlisted linked-location entrance; future types require capture |
| Tile entrance location metadata | captured interior geometry and features on the same persisted building record; never position authority |
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
