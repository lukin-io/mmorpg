# Neverlands Movement Codebase Analysis

Date: 2026-05-09
Reference observations:

- `doc/flow/neverlands_live_movement.md`
- `doc/flow/neverlands_live_city_movement.md`

Canonical design docs:

- `doc/design/features/movement.md`
- `doc/design/areas/world_map.md`
- `doc/design/areas/cities_and_buildings.md`

This document compares the current Rails movement implementation with the
live Neverlands movement contract observed from `Oktal, West Gate`. The app is
still in development, so the recommendation assumes schema changes and a DB
reset are acceptable.

## Executive Summary

The current app implements movement as an immediate server-side position
update plus an action cooldown. Neverlands implements movement as a
server-authoritative accepted command with a travel timer, locked UI state,
local animation, resumable in-progress movement, and a completion step that
refreshes reachable tiles and action buttons.

The biggest implementation gaps are:

- movement requests submit only a direction, not a server-offered destination
  coordinate plus an action key;
- `WorldController#move` bypasses `MovementCommand`, so the documented command
  queue is not the runtime path;
- `TurnProcessor` mutates `character_positions` immediately, so there is no
  "moving" state, ETA, resume data, or completion boundary;
- the client cooldown is stored in `sessionStorage`, not server-authoritative
  movement state;
- direction/passability logic is duplicated and inconsistent across controller,
  view, JS, pathfinder, command model, and tile provider;
- action buttons are built separately from movement responses, while
  Neverlands treats movement completion as the context-refresh boundary.

## Live Neverlands Target Contract

Observed initial state:

- current coordinate: `1019,1025`;
- location shown by chat/player frame: Oktal, West Gate;
- movement time: `30` seconds;
- available destinations supplied by the server as `[x, y, action_key]`;
- only one destination was initially clickable: `1018,1025`;
- the request went to `gameplay/ajax/map_ajax.php?act=1` with `mx`, `my`,
  `gti`, action key, and random cache buster;
- the response was `GO@x@y@[next_tiles]@[buttons]@[map_meta]`.

Important behaviors from the live client:

1. Server decides reachable tiles and assigns each a short-lived action key.
2. Client only renders those server-supplied destinations as clickable.
3. On click, client submits destination coordinates, travel duration, and
   action key.
4. Server accepts movement before animation starts.
5. During movement, available destinations are cleared and buttons are disabled.
6. Client animates the map locally every 50 ms and shows a countdown.
7. Completion updates current coordinates, next reachable destinations, action
   buttons, map metadata, optional message, and location/player list.
8. Page reload can resume in-progress movement from server-provided state.
9. Non-movement responses such as `MESS`, `RESO`, and `F5` can also lock,
   unlock, or rebuild movement availability.

For this codebase, the exact string protocol does not need to be copied. The
required design shape is the same: an authoritative movement offer, an accepted
travel state, and a completion response.

## Current Runtime Flow

### Server Entry Point

`app/controllers/world_controller.rb` handles movement in `move`:

```ruby
direction = params[:direction]&.to_sym
Game::Movement::TurnProcessor.new(character: current_character, direction: direction).call
@position.reload
render_map_update
```

The request submits only `direction`. There is no destination coordinate,
movement action key, expected travel cost, route id, or command id.

### Movement Processing

`app/services/game/movement/turn_processor.rb`:

- supports 8 directions in `OFFSETS`;
- computes target from current position plus direction offset;
- validates target via `TileProvider` and `MovementValidator`;
- calculates cooldown using target tile metadata;
- checks `CharacterPosition#ready_for_action?`;
- resolves encounter;
- immediately updates `x`, `y`, `last_action_at`, and `last_turn_number`.

That means the database position has already changed before the browser timer
finishes. The timer is presentation-only.

### Position State

`app/models/character_position.rb` stores:

- `zone_id`;
- `x`, `y`;
- `state`: `active`, `downed`, `respawning`;
- `last_turn_number`;
- `last_action_at`;
- `respawn_available_at`.

It has no movement fields:

- no source coordinate;
- no target coordinate;
- no `moving` state;
- no `movement_started_at`;
- no `movement_ends_at`;
- no accepted command id;
- no resume payload.

### Command Queue

`app/services/game/movement/command_queue.rb` and
`app/models/movement_command.rb` exist, but `WorldController#move` does not use
them.

The queue currently wraps immediate movement:

1. `enqueue` predicts target and stores a `MovementCommand`.
2. background job calls `process`;
3. `process` calls `TurnProcessor`;
4. `TurnProcessor` immediately mutates `character_positions`.

The queue is useful as an audit start, but not as Neverlands-style travel. It
also stores only cardinal directions because `MovementCommand::DIRECTIONS` is
`north/south/east/west`, while `TurnProcessor` and the map support diagonals.

### Map Rendering

`app/views/world/_map.html.erb` renders a 5x5 grid around the character and
marks all adjacent walkable tiles clickable. It computes availability in the
view from:

- coordinate adjacency;
- `tile.walkable`;
- current tile exclusion.

It does not render server-issued movement action keys per destination. The hidden
form contains only `direction`.

### Browser Controller

`app/javascript/controllers/nl_world_map_controller.js`:

- derives direction from the clicked tile;
- writes a global `elselands_move_cooldown` timestamp to `sessionStorage`;
- changes cursor/timer state before the server accepts the move;
- submits the hidden form with `direction`;
- relies on Turbo to replace map/location/action partials.

This differs from Neverlands in two key ways:

- cooldown is client-owned and can drift from server state;
- there is no accepted movement payload that contains destination, next tiles,
  buttons, and map metadata.

### Action Buttons

`app/views/world/_actions.html.erb` renders cardinal buttons only. The map view
supports all 8 adjacent directions, and `TurnProcessor` supports all 8, so the
UI exposes different movement capabilities depending on whether the player
clicks the map or the action panel.

Action availability is also separated from movement responses. Neverlands
returns the next action buttons in the movement response; this code recalculates
actions in `WorldController#available_actions` after Turbo refresh.

## Inconsistencies And Risks

### Runtime Path Mismatch

The deleted legacy gameplay flow doc claimed movement intents persisted through
`MovementCommand` and were drained by a job. Runtime movement does not follow
that path; `WorldController#move` calls `TurnProcessor` directly.

### Direction Support Mismatch

- `TurnProcessor` supports 8 directions.
- `_map.html.erb` supports 8 adjacent clickable targets.
- `nl_world_map_controller.js` supports 8 directions.
- `_actions.html.erb` exposes only cardinal buttons.
- `MovementCommand` validates only cardinal directions.
- `Pathfinder` explores only cardinal directions.

A Neverlands-like system should have one canonical movement direction and
adjacency policy. If diagonals are allowed, every layer must support them. If
they are not allowed, the map should not render diagonal destinations.

### Passability Mismatch

`WorldController#nearby_tiles_with_features` generates procedural fallback
terrain and marks `mountain` and `river` as unwalkable. `TileProvider#tile_at`
assumes missing in-bounds tile records are passable unless the whole zone biome
is `mountain`, `water`, or `ocean`.

This can produce a clickable/un-clickable mismatch between the rendered map and
the service that actually validates movement.

### Availability Mismatch

`WorldController#available_directions` checks only zone bounds, not passability.
The action panel can therefore offer a direction that `TurnProcessor` rejects.

### Cooldown Mismatch

The controller's `movement_cooldown` is calculated from current tile metadata.
`TurnProcessor` calculates cooldown from target tile metadata. The browser uses
the controller value in `data-nl-world-map-move-cooldown-value`, so the visible
timer can differ from the server's actual readiness check.

The base movement cooldown is 10 seconds. The observed Neverlands movement from
`1019,1025` to `1018,1025` was 30 seconds. That does not mean every move must
be 30 seconds, but the GDD needs a canonical travel-time model.

### Destination Offer Gap

Neverlands uses a per-offer key for each destination. The current implementation
has no per-destination action key. It accepts a direction and relies on later
validation. That is acceptable for basic movement validation, but it does not
match the reference design where the server issues the exact destination offer
and later validates that offer.

### Resume Gap

Neverlands can render an in-progress movement after reload. Current state is
only `last_action_at`; after reload the browser can show a timer from
`sessionStorage`, but the server has already moved the character and cannot
restore source, destination, remaining travel, disabled actions, or animation
progress.

### Removed Legacy JS

The older `app/javascript/controllers/game_world_controller.js` movement
controller was deleted during the Neverlands cleanup. It was not wired by the
rendered map and described a different movement model from the current
`nl-world-map` surface.

### Data Model Gap

`map_tile_templates.zone` is a string name while `character_positions.zone_id`
is a real FK. Several world objects also use zone strings. The code has helper
workarounds such as `MapTileTemplate#zone=`, but movement code still mixes
`zone`, `zone.name`, and `Zone` objects. Since DB reset is allowed, this should
be normalized before movement becomes more complex.

### Seed And Map Gap

The seed map is small and partly random. Neverlands uses stable world
coordinates around `1019,1025`, deterministic tile image paths, and
server-supplied movement options. A deterministic Neverlands-inspired starter
area should replace random map generation for movement tests and GDD examples.

## Recommended Target Architecture

### Source Of Truth

Make `doc/design/gdd.md` the single design source. It should explicitly link
to:

- `doc/design/features/movement.md` as the canonical movement design;
- `doc/design/areas/world_map.md` as the canonical wilderness map design;
- `doc/design/areas/cities_and_buildings.md` as the canonical city movement
  design;
- `doc/flow/neverlands_live_movement.md` as observed reference behavior;
- `doc/flow/neverlands_live_city_movement.md` as observed city reference
  behavior;
- this analysis as the implementation gap list;
- future implementation docs only as derived technical notes.

When a doc conflicts with the GDD, the GDD wins.

### Canonical Movement Service Boundary

Introduce a single movement read model and command flow:

- `Game::Movement::Availability` or `Game::Movement::MapState`
  - returns current position;
  - returns current movement state;
  - returns server-offered destinations with action keys;
  - returns current tile actions/buttons;
  - returns map metadata such as travel time, visual variant, and messages.
- `Game::Movement::AcceptMove`
  - accepts `target_x`, `target_y`, `expected_duration`, `action_key`;
  - validates action key, character state, passability, cooldown, and
    destination;
  - creates/updates a movement command/session;
  - returns accepted travel payload.
- `Game::Movement::CompleteMove`
  - finalizes a move when `movement_ends_at <= Time.current`;
  - updates authoritative position;
  - resolves encounter and tile effects;
  - returns next available destinations and buttons.

The controller should call these services and stop owning movement math.

### Schema Shape

Because dev reset is allowed, prefer replacing the current minimal command
shape instead of layering hacks over it.

Recommended `movement_commands` fields:

- `character_id`;
- `zone_id`;
- `from_x`, `from_y`;
- `target_x`, `target_y`;
- `direction`;
- `status`: `offered`, `accepted`, `moving`, `completed`, `failed`,
  `cancelled`;
- `action_key_digest`;
- `action_key_expires_at`;
- `travel_seconds`;
- `started_at`;
- `ends_at`;
- `completed_at`;
- `failure_reason`;
- `response_payload` or `metadata` for next tiles/buttons/map metadata.

Recommended `character_positions` movement fields:

- `movement_state`: `idle`, `moving`, `locked`;
- `moving_from_x`, `moving_from_y`;
- `moving_to_x`, `moving_to_y`;
- `movement_started_at`;
- `movement_ends_at`;
- `active_movement_command_id`.

Alternative: keep all movement lifecycle data in `movement_commands` and derive
current state from the active command. That is cleaner if the app will need
history and audits. `character_positions` can then stay focused on finalized
location plus a pointer to the active command.

Recommended map normalization:

- replace `map_tile_templates.zone` string with `zone_id`;
- update `TileResource`, `TileNpc`, and `TileBuilding` to use `zone_id` or a
  shared tile/location table;
- add a deterministic unique key on `[zone_id, x, y]`.

### Response Contract

Use JSON or Turbo Streams, but keep the Neverlands semantics:

```json
{
  "type": "GO",
  "from": {"x": 1019, "y": 1025},
  "to": {"x": 1018, "y": 1025},
  "travel_seconds": 30,
  "movement_ends_at": "2026-05-09T12:34:56Z",
  "next_tiles": [
    {"x": 1017, "y": 1025, "action_key": "..."}
  ],
  "buttons": [
    {"id": "inf", "label": "Character", "action_key": "..."},
    {"id": "inv", "label": "Inventory", "action_key": "..."},
    {"id": "look", "label": "Look around", "action_key": "..."}
  ],
  "map": {
    "variant": "night",
    "message": null
  }
}
```

The client can still be Hotwire-first. The important part is that the data
contract is movement-centric, not partial-centric.

### UI Behavior

The rendered map should:

- render only server-offered destinations as clickable;
- include destination coordinate and action-key data attributes;
- submit target coordinate plus action key;
- begin animation only after an accepted response;
- clear clickable destinations during travel;
- disable gameplay buttons during travel;
- show countdown based on `movement_ends_at`, not `sessionStorage`;
- resume countdown/animation from server state on reload;
- rebuild tiles and buttons from server response after completion.

For the first implementation, full lazy tile loading can be deferred. It is
enough to implement correct accepted movement, countdown, resume, and completion
on a 5x5 or 7x7 map. The lazy loading/margin-shift behavior can follow after
the authoritative state model is correct.

### Travel-Time Formula

Define travel time in the GDD before coding:

```text
travel_seconds =
  base_zone_seconds
  * terrain_modifier(target tile)
  * diagonal_modifier(if diagonal)
  * encumbrance_modifier
  / mount_multiplier
  * skill_modifier
```

Use the observed `30` seconds as the starter-area reference value unless the
GDD chooses a faster local-dev value.

The formula should return the same value for:

- destination offers;
- accepted move validation;
- countdown display;
- server readiness/resume checks.

### Movement Completion Timing

Recommended behavior:

- On accepted movement, do not finalize `character_positions.x/y` immediately.
- Store active movement with `ends_at`.
- Finalize lazily on the next world request, next movement request, or a
  scheduled job.
- If `ends_at` has passed, completion updates `character_positions`, resolves
  encounters, and emits the next map state.

This gives correct reload behavior and keeps movement authoritative even if the
browser closes mid-travel.

## Implementation Plan

### Phase 0: Canonical Docs

- Keep `doc/design/gdd.md` as the entry point.
- Keep `doc/design/features/movement.md` and
  `doc/design/areas/cities_and_buildings.md` as the implementation targets.
- Keep the live observation files as reference material.
- Keep deleted legacy flow docs out of the canonical source tree unless they
  are rewritten against the GDD.
- Keep this document as the codebase gap analysis.

### Phase 1: Schema Reset

- Normalize map tiles and tile-local entities to `zone_id`.
- Rebuild `movement_commands` around accepted travel, not immediate processing.
- Add active movement state or active command pointer to `character_positions`.
- Seed a deterministic Neverlands-inspired starter map with stable coordinates
  near the observed `1019,1025` area.

### Phase 2: Server Services

- Build `MapState` for current position, current movement, destinations,
  buttons, and map metadata.
- Build destination action-key generation/verification.
- Replace direct `TurnProcessor` usage in `WorldController#move`.
- Split movement into accept and complete operations.
- Make passability use exactly one provider.

### Phase 3: Client Contract

- Change `_map.html.erb` to render server-supplied destinations and action
  keys.
- Change `nl_world_map_controller.js` to submit target/action key and wait for an
  accepted movement response.
- Replace `sessionStorage` cooldown authority with server `movement_ends_at`.
- Add reload resume behavior from server-rendered movement state.
- Keep only the `nl_world_map_controller.js` movement surface until the
  Neverlands-style movement state machine replaces it.

### Phase 4: Tests

Update or add tests for:

- server offers only passable destinations;
- each destination has an action key and expired/invalid keys fail;
- accepted movement does not immediately finalize `character_positions.x/y`;
- active movement resumes after reload;
- movement completes after `ends_at` and returns next destinations/buttons;
- action buttons are disabled while moving;
- diagonal policy is consistent across service, model, view, JS, and pathfinder;
- current tile and target tile travel-time formula is used consistently;
- map rendering and service passability agree for missing tile records.

### Phase 5: Visual And Map Polish

- Add smooth map shifting based on authoritative start/end timestamps.
- Add lazy row/column loading if large maps require it.
- Refresh local player list after movement completion.
- Add action response types equivalent to `MESS`, `RESO`, and `F5` once
  resource and tile action flows need them.

## Concrete Code Hotspots

- `app/controllers/world_controller.rb`
  - `move` is the immediate movement entry point.
  - `available_directions` checks bounds only.
  - `movement_cooldown` uses current tile metadata.
  - `nearby_tiles_with_features` has independent procedural passability.
- `app/services/game/movement/turn_processor.rb`
  - immediate final position mutation.
  - target tile cooldown calculation.
- `app/services/game/movement/command_queue.rb`
  - unused by runtime controller.
  - wraps immediate movement instead of travel lifecycle.
- `app/models/movement_command.rb`
  - cardinal-only validation.
  - lacks from/target lifecycle/timing/action-key fields.
- `app/models/character_position.rb`
  - no moving or locked state.
- `app/services/game/movement/tile_provider.rb`
  - missing tile fallback can disagree with rendered procedural terrain.
- `app/views/world/_map.html.erb`
  - calculates click availability in the view.
  - hidden movement form submits only direction.
- `app/javascript/controllers/nl_world_map_controller.js`
  - client-owned cooldown.
  - no target/action-key submission.
- `app/views/world/_actions.html.erb`
  - cardinal-only action pad.
- `app/javascript/controllers/nl_world_map_controller.js`
  - current movement controller to replace with the Neverlands-style state
    machine.

## Decision Needed Before Implementation

1. Should diagonal movement be part of the canonical GDD?
2. Should a move finalize only after `ends_at`, or should the position update
   immediately with a separate "busy until" lock? The Neverlands-like answer is
   finalize after `ends_at`.
3. Should the first canonical starter map use Neverlands-like global
   coordinates around `1019,1025`, or keep local coordinates and only copy the
   behavior?
4. Should the API stay Turbo Stream based, or should map movement become a JSON
   endpoint that updates a Stimulus state machine?

My recommendation is: allow diagonals only if the GDD explicitly wants them,
finalize after `ends_at`, seed a deterministic starter area around
`1019,1025`, and use JSON for movement state while keeping Turbo for the
surrounding page.
