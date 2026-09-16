# Movement

Domain navigation: [World](../../domains/world.md).

[WORLD](../../WORLD.md#5-travel-context-and-return-behavior) describes routes,
entry/return and saved context; [FORMULAS](../../FORMULAS.md#8-world-movement-and-encounter-timing)
records timing and fatigue. The [World handbook](../../features/world.md)
owns current offers, authoritative movement and encounter handoffs.

## Purpose

Movement gives the world weight. Outdoor travel should feel deliberate,
server-authored, and interruptible by local context. City movement is separate:
it is node-to-node navigation through illustrated hotspots.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/source_material.md`
- `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`

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
- Coordinates use `x` as the column and `y` as the row. A destination is one
  legal eight-direction step exactly when:

  ```text
  abs(target.x - current.x) <= 1
  AND abs(target.y - current.y) <= 1
  AND target != current
  ```

  This is Chebyshev distance `1`: the four cardinal and four diagonal cells
  may be offered; the current cell and every multi-cell jump may not.
- Each offered destination includes target coordinates, travel time, and an
  action key.
- The browser only renders server-offered destinations as clickable.
- Accepted movement creates a travel state with start and end timestamps.
- Character position finalizes when travel completes.
- Reload during travel resumes the remaining countdown.
- Completion refreshes available actions and local presence while retaining
  unchanged overlapping terrain cells and updating the entering map edges.
- A completed wilderness step applies its snapshotted `1..2` fatigue gain.
- At effective fatigue `86%` or higher, Move, Look, and Enter are unavailable
  until recovery lowers the value. An authored water cell can still offer
  Drink; its fatigue recovery must not inherit that gate.
- Passability and travel time are server rules, not browser rules.
- Client animation is linear presentation only; it never advances the
  finalized coordinate on its own.
- Before an offered move is accepted, a live source-backed hostile encounter on
  the current cell can replace movement with the shared fight state. The
  movement offer remains unaccepted and the finalized coordinate does not
  change.

The visible wilderness is assembled from those same authoritative cells. Each
`100 x 100` cell renders its validated explicit art or guarded starter PNG;
unresolved art uses per-cell CSS terrain. Required missing PNGs never load
the full authoring master, while explicit nonsliced catalogs retain their
configured sheet crops. Moving scrolls
the assembled cells beneath the fixed player marker. Optional 200px density
variants are browser-selected rasters for that same 100px CSS footprint; they
do not change the accepted direction, deadline or translation distance.
Artwork never decides
passability, resources, entrances, NPCs, or other cell content.

## Persistence Contract

Neverlands-style movement is persistent server state, not browser state.

Conflicting player actions share the character's serialization boundary.
Movement validates the current owned offer before evaluating a hostile
interruption. Accepted travel and the captured Look, Fish, or Drink deadline exclude a new
move or Enter/Character/Inventory action; stale keys cannot trigger an encounter
as a side effect of failed movement validation. Repeated processing cannot
extend a deadline, apply fatigue twice, or change a completed command back to
moving/failed.

Spatial reads are bounded independently of zone size: movement offer
generation reads only the eight neighboring coordinates, acceptance/completion
read the exact target, and rendering reads the nearby buffer. The Neverlands
client retains overlapping cells; fresh movement controls remain server-owned.
The local implementation supplies entering edge cells and fresh controls when
its signed prior buffer still matches the character, zone, visible dimensions
and content. Viewport hints select bounded odd cell counts, not reachable
coordinates; a debounced resize GET may refresh owned offers while preserving
accepted movement and its deadline. Changed content, resized dimensions, an
invalid/stale buffer or reload uses a complete bounded snapshot.
The buffer hint never authorizes movement or decides the current position.

`zone_id` on position/command records is the existing region identity.
Multi-zone readiness uses this identity and independent zone-scoped content;
no competing region/position model is needed. The MVP launches one outdoor
zone. Full population of that zone is Stage 2. Additional zones, enabled
inter-zone routes, and walking border mappings are post-MVP TODOs. Configured
airship journeys already use the same zone-qualified position through their
separate paid transport lifecycle, defined in
`doc/design/features/airship_travel.md`; normal routes await destination,
path, and schedule content. A
server-side relocation invalidates active travel from the previous source
region/cell before its deadline; it cannot reuse an old region's offer at the
same local coordinates.
Successful movement, city-node transitions, and city-gate entry also clear the
previous interior context in the position transaction. The shared local-chat
owner records the resulting cell/room entry there; duplicate completion or an
unchanged room reload cannot reset its timestamp. Region identity uses the
existing Zone ID and stable name-keyed cell content; a populated name cannot
be renamed or deleted while that content remains.

Authoritative state:

- a character location record stores the finalized coordinate and zone;
- a movement command record stores `offered`, `moving`, `completed`, `failed`,
  or `cancelled` state; acceptance changes `offered` to `moving`;
- an accepted movement does not immediately change the finalized character
  location.
- Active movement stores source coordinate, target coordinate, start time,
  end time, travel duration, and action key.
- Reopening the browser must load from database state:
  - if no movement is active, the player appears at the finalized coordinate;
  - if movement is active and not due, the countdown resumes from `ends_at`;
  - if movement is due, the server finalizes it before rendering the map.
- Login restores an owned aboard airship journey before saved ground surfaces,
  using the separate lifecycle in `doc/design/features/airship_travel.md`.
  Otherwise it restores World/city, village, city/village Shop, an allowlisted
  city building, or an
  accessible selected Arena room. An invalid saved room falls back to World
  without changing the persisted position. No unrelated dashboard precedes the
  game surface.

Expected player result: if a player walks in the open world, closes the browser,
and opens the game later, they are still at the same finalized cell or at the
completed destination if the travel timer elapsed while they were away.

An interrupted wilderness action stores only an allowlisted logical return
context on the fight. Finishing its explicit result returns to the unchanged
world cell, or to Character/Inventory when that was the interrupted shell
destination. It never stores or follows an arbitrary browser URL.

If the player logged out in Shop, login reopens Shop with its sanitized tab,
category, and numeric filters. City Shop returns to its city node. Village Shop
returns to Village Square; the separate Leave action returns outdoors. Both
village surfaces retain the exact entrance cell. A valid selected Arena room
also resumes after login using current city and room access, without depending
on an old entry cookie. Inaccessible saved surfaces fall back to the unchanged
city or outdoor position.

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
- Actual HTML room visits update saved room identity and its presence/chat
  audience; room JSON previews do not move the player between audiences.

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

### Configurable local parameters

The preceding numbers describe the current defaults, not a recovered complete
Neverlands formula. `config/gameplay/world_rules.yml` stores validated numeric
parameters for the Wanderer fallback, fatigue gain/recovery/gates, captured
local-action durations, and the explicitly local presence freshness policy.
`Game::World::Rules` rejects malformed values, unsupported keys, and invalid
ranges; it does not evaluate expressions or accept browser-supplied formulas.
The travel calculation receives the effective Wanderer value as a scalar. Its
caller resolves equipment and skill once for the adjacent destination batch.

The normal ruleset loads on process start/use or an explicit validated reload.
An offered movement duration, accepted fatigue gain, and started local-action
deadline remain persisted snapshots if configuration changes. Natural recovery
and presence freshness use the currently loaded policy. Equipment, terrain,
effect, encounter-probability, and profession coefficients still require
isolated Neverlands evidence before being added.

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
- a Drink at an authored water cell immediately removes two fatigue points,
  bounded at zero, and retains a 60-second work lock. No skill gate applies;
- the wiki establishes four points with Nature Child. That known value is
  preserved as configuration data; the unsupported perk itself is not granted
  or enabled. Character Progression owns its acquisition/effect gap in
  `doc/features/character_progression.md` section 6.5;
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
- `features/items_inventory_equipment.md` owns carried weight and equipment;
  carried weight does not currently modify movement duration. Supported
  equipment skill bonuses may affect the effective Wanderer fallback.
- `features/professions.md` may consume an eligible cell action later, but it
  must reuse the same server-authored fatigue/action boundary.

## Rails-Friendly Direction

The open-world map should use one server-authored state-building pipeline:

1. Finalize due movement for the character.
2. Load the current authoritative character location.
3. Resolve persisted tile context for the current location:
   - hidden NPC encounter state;
   - the captured city gate or allowlisted village entrance;
   - authored resource-search and other captured local actions;
   - terrain, validated `100 x 100` cell art, and passability.
4. Create short-lived action offers for everything the player can do:
   - movement offers;
   - enter city or village offers;
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
`doc/features/world.md`, section 7.4, is the operational authoring contract for
those layers. It maps `db/seeds.rb`, the outdoor-NPC config, persisted records,
resolution, offers, cleanup, and coverage. Movement must consume that composed
state; it must not introduce another building/resource/NPC source.
Movement completion resolves the new current cell. Unchanged overlapping map
art remains in the browser; this does not retain stale gameplay offers.
The September 8 water-cell capture extends the timed local-action contract:

| Action | Immediate result/effect | Captured work lock |
| --- | --- | --- |
| Look Around (`look`) | Empty vegetation result; no item/currency | 28 seconds |
| Drink (`dri`) | Success result and two fatigue points recovered | 60 seconds |
| Fish (`fis`), without bait | “No bait available”; no catch, fatigue gain, or proficiency growth | 30 seconds |

Only an exact current cell with the authored action may offer it. Fishing and
drinking have no skill gate. Successful fishing still requires the separate
rod/bait/cast flow and evidence for consumption, yields, tool wear, and
proficiency growth; the captured empty entry is not a completed profession.
Successful gathering remains deferred to alchemy. Digging requires a skill,
but its eligibility and outcomes remain uncaptured.

A hostile can interrupt before local work starts, and a passive fight may
supersede active work. Closing the result hides it without cancelling the
lock; reload recovers the same persisted deadline. Drink's fatigue change,
result, and deadline commit together; duplicate requests cannot recover more
fatigue or restart the timer. Result delivery is consumed once independently
of gameplay completion.

Movement consumes the resolved 100px cell presentation but does not own its
asset keys or sheet geometry. Add special-cell art through the authoring workflow
in `doc/features/world.md`, section 7.2; do not encode art selection in movement
commands or browser animation state.

Keep source action identifiers valid in authored tile data. The captured
Drink and empty fishing entry are distinct from successful gathering/casting;
do not extrapolate rewards, depletion, or profession formulas from them.

## Out Of Scope

- Long-distance pathfinding as the first movement interaction.
- Browser-only cooldowns.
- City travel countdowns for the starter city.
- Full zone population (Stage 2), additional outdoor zones, and unobserved
  walking border mappings (post-MVP TODO). Paid
  airship travel is a separate capability, not an adjacent walking command.
- Gathering yields, profession growth, or uncaptured timing modifiers.
