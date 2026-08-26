# Game Design Document

Domain-first navigation: `doc/domains/README.md`.

This is the design source of truth for the project. The game is a
Neverlands-based browser MMORPG, not a one-to-one asset or content clone.
When implementation docs, tests, or code disagree with this file, this file wins
and the derived material should be updated.

## Reference Hierarchy

1. This GDD defines intended game behavior.
2. `doc/design/features/*` and `doc/design/areas/*` break the GDD into
   buildable feature and area documents.
3. `doc/design/reference/neverlands.md` explains how Neverlands observations
   should be translated into this project's design language.
4. `doc/design/reference/*` holds Neverlands observations and source-material
   mapping. Reference notes explain provenance, but they do not override this
   GDD.

Non-Neverlands docs are not part of the design hierarchy and should be removed
instead of preserved as alternate guidance.

## Design Library

Use these documents when implementing or extending the game design:

Launch scope:

- `doc/design/launch_mvp_plan.md`

Areas:

- `doc/design/areas/world_map.md`
- `doc/design/areas/game_client_layout.md`
- `doc/design/areas/cities_and_buildings.md`
- `doc/design/areas/arena.md`

Features:

- `doc/design/features/movement.md`
- `doc/design/features/character_vitals.md`
- `doc/design/features/progression_stats_skills.md`
- `doc/design/features/combat.md`
- `doc/design/features/items_inventory_equipment.md`
- `doc/design/features/economy_trading_shops.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/social_chat_presence.md`
- `doc/design/features/dungeons.md`

Documentation process:

- `doc/README.md`
- `doc/design/README.md`
- `doc/design/launch_mvp_plan.md`
- `doc/design/reference/neverlands.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/source_material.md`

## Vision

Build a classic, persistent, browser-first Neverlands-based MMORPG with slow,
deliberate map movement, tile-local actions, social presence, tactical combat,
character growth, and player economy.

The intended feel is:

- compact game UI instead of a landing-page style app;
- server-authoritative actions;
- readable location state and visible nearby player presence;
- movement that has weight, travel time, and contextual consequences;
- deterministic world data suitable for testing and iteration;
- mechanics that follow observed Neverlands behavior and are implemented with clean Rails
  implementation.

## Core Loop

1. Player logs in and enters the world at the last persisted cell. A spawn point
   is used only when the character has no saved position yet.
2. The world view shows the current location, map tiles, nearby players, and
   tile-local actions.
3. Player chooses a server-offered destination or local action.
4. Movement/actions lock relevant buttons and show a timer when they take time.
5. Completion refreshes current location, available movement, visible tile
   actions/buildings, hidden NPC encounter state, and nearby player list.
6. Player gains combat progress, skill growth, or economy opportunities.

## Movement GDD

Movement follows the Neverlands-style contract:

- the server decides which nearby destinations are reachable;
- each destination offer includes target coordinates and a short-lived action key;
- the browser renders only server-offered destinations as clickable;
- movement request submits target coordinates, expected travel time, and action
  key;
- the server validates the action key, passability, character state, and travel
  cost;
- accepted movement creates an in-progress travel state with an end timestamp;
- gameplay buttons and movement destinations are disabled while travelling;
- the browser shows a countdown and local map/cursor animation;
- reload during travel resumes from server state;
- completion updates authoritative position and returns the next map state;
- completion also refreshes context buttons such as character, inventory,
  enter, and other source-backed local actions; hidden NPC state is not a
  rendered button.

The first implementation does not need to copy Neverlands' exact `GO@...`
string protocol. JSON or Turbo Streams are acceptable if they preserve the same
semantic contract.

### City Movement

City movement follows a separate Neverlands-style contract from wilderness
movement:

- city entry is a contextual action offered by the outside tile;
- entering the city immediately loads a city node page;
- a city node is an illustrated scene with clickable hotspots;
- hotspots lead to other city nodes, buildings, or the outside map;
- city node transitions do not use the wilderness movement countdown;
- every city page refreshes the available outgoing actions;
- entering a building immediately loads a building page;
- building pages provide feature-specific UI and a `City` return action;
- returning from a building goes back to its parent city node;
- local player/location presence refreshes after city navigation.

The target high-level flow is:

```text
outside tile -> city node -> building -> city node -> outside tile
```

### Movement State

Movement is not just a cooldown. It is an accepted travel lifecycle:

```text
idle -> accepted/moving -> completed
idle -> accepted/moving -> failed/cancelled
idle -> locked by work/action timer -> idle
```

The authoritative server state must be able to answer:

- current finalized coordinate;
- active source coordinate, if moving;
- active target coordinate, if moving;
- movement start time;
- movement end time;
- remaining seconds;
- available destinations when idle;
- available action buttons when idle;
- disabled/locked reason when not idle.

Wilderness movement also owns persisted fatigue. Each completed step adds a
snapshotted `1..2`, one point recovers every three minutes, and effective
fatigue `86%+` removes Move, Look, and Enter until recovery. This is an action
gate, not an invented travel-time or combat-penalty formula.

### Travel Time

Travel time is a GDD-level value, not a browser-only cooldown. The same formula
must be used for destination offers, accepted movement validation, countdown
display, and action readiness.

The clean starter reference is `30` seconds. The MVP applies the confirmed
Wanderer relationship as a bounded whole-second reduction:

```text
wanderer = clamp(effective_wanderer_level, 0, 100)
reduction_seconds = floor(wanderer * 5 / 100)
travel_seconds = clamp(30 - reduction_seconds, 25, 30)
```

The observed Neverlands reference move from `1019,1025` to `1018,1025` used
`30` seconds. A later character with Wanderer `100` received server values of
`32` and then `49`, proving that the full source formula also has unisolated
inputs. Do not add terrain, diagonal, encumbrance, fatigue, effect, profession,
or other skill modifiers until they are source-captured.

### Direction Policy

The GDD must explicitly choose one policy:

- cardinal-only movement; or
- eight-direction movement with diagonals.

Until changed, the target policy is eight-direction movement. All layers must
follow the same policy: movement rules, persistence validation, pathfinding, map
rendering, client controls, and tests.

### Passability Policy

One authoritative movement rule owns passability. Views and browser controllers
do not invent movement availability. Missing tile data must have a
deterministic rule and must render the same way it validates.

### Movement Completion

Position should finalize after travel ends, not immediately on click. The
server may finalize lazily on the next request or through a background job, but
the completed state must be authoritative and reproducible after reload.

## World Design

The world is a tile grid split into zones or regions. Zones define:

- stable name and key;
- dimensions or coordinate bounds;
- visual map variant;
- base travel seconds;
- location type (`city` or `outdoor`);
- explicit outdoor NPC/resource records;
- spawn points;
- tile templates;
- allowed local action types.

Login is an exact resume operation. The finalized `CharacterPosition` remains
authoritative for outdoor cells and city nodes across logout, browser closure,
and later login. A separate allowlisted gameplay context records whether the
character last occupied the world/city surface or an implemented city interior
such as Shop. Shop mode, category, and numeric filters may resume; arbitrary
URLs or unrecognized context data must never be followed. If the remembered
interior is no longer accessible, login falls back to the persisted world/city
position without moving the character.

The launch MVP contains exactly one outdoor region with a logical size of
`1000 x 1000` cells. More regions are post-MVP content, but region identity and
coordinate bounds must remain first-class so the world can expand without
rewriting character positions or movement commands. The implementation should
store sparse authored tile overrides rather than eagerly create one million
database rows.

Starter world data is deterministic. The west-gate source observation
`m_1019_1025` is mapped to local cell `7,0`, while the outdoor NPC/resource
observation `m_1001_999` is mapped to local cell `7,7`. The original map ids and
coordinates remain metadata, not executable local coordinates. The exact
source-coordinate/region-origin formula still needs capture; these two starter
mappings do not imply a general offset.

## Tile-Local Actions

Movement completion is the refresh boundary for tile-local actions. A map state
may offer buttons for:

- character/profile;
- inventory;
- enter/exit building or location;
- future captured quest interaction.

An outdoor cell is a composition, not one generic `feature` record. Its current
state can combine:

- sparse authored terrain/passability metadata;
- an optional validated source-backed `100 x 100` cell-art slice;
- one materialized hostile NPC;
- one enterable city gate, outdoor building, or special-location entrance;
- zero or more source-backed local actions.

The hostile NPC layer is server-only until it interrupts an action; the outdoor
map does not render the NPC name, marker, or a manual Attack control. The
captured Neverlands local-action identifiers are `look` (search for herbs
or local resources), `fis` (fishing), `dri` (drink), and `dig` (dig). Launch
implements the captured `look` offer/accept/refresh contract. The other action
types may be represented by authored cell data, but their rewards, skill checks,
equipment requirements, timers, and depletion rules remain unavailable until a
successful live flow is captured.

Missing sparse tile rows use the same deterministic outdoor default for both
rendering and movement validation. A tile row is required only for an authored
override or local action; the `1000 x 1000` region must not create one million
records.

Each action that mutates state should be server-authored, persisted, and
validated against the current tile. The map renders action offers issued by the
server; each offer has a short-lived action key tied to character, zone,
coordinate, action type, and target.

There is no arbitrary location-name entry route. City, building, and special
location entry is accepted only through an entrance offered by the character's
current outdoor cell.

## Combat

Combat is turn-based and tactical. Core expectations:

- PvE encounters can trigger from map movement or tile-local hostile actions;
- player, team, and NPC fights support Neverlands-style arena duels, group
  fights, and room-based applications;
- the same side model renders and resolves 1x1, 1xMany, and ManyxMany PvP/PvE
  rosters; repeated NPC templates remain distinct fight participants;
- surrender defeats one participant and produces a fight result only when the
  conceding participant's entire side has no survivor;
- combat uses explicit turns, action points, body-part targeting, blocks,
  skills, logs, rewards, and death/respawn consequences;
- combat state must be resumable and auditable.
- outdoor result finish uses a server-allowlisted return context and never an
  arbitrary submitted URL.

## Dungeons

Dungeons are deferred until after the launch MVP, but their design target is
defined by the Neverlands wiki and forum sources listed in
`doc/design/features/dungeons.md`.

Core expectations:

- a leader starts a solo or party run with a source-style key/unlock;
- eligible players can join another leader's application;
- entry requirements include source-style level, equipment, party, active-run,
  and cooldown restrictions;
- floors are generated room graphs with floor timers and finite depth;
- room movement spends lamp oil;
- hostile room NPCs block movement and object interaction until resolved;
- dungeon NPC and boss fights follow the source combat behavior;
- floor descent requires five activated seals and current wiki portal rules;
- hidden rooms create an individual risk/reward branch through a floor key,
  chest, or boss;
- dungeon inventory forbids equipment changes and exposes only allowed
  consumables;
- deepest-floor and weekly progress can feed ratings and specialist-shop
  rewards.

## Character Progression

Characters grow through:

- experience and levels;
- stat allocation;
- 0-100 numeric skills;
- separately allocated yes/no perks;
- Neverlands alignment/sign markers where source-backed;
- equipment and inventory growth.

New characters begin at level `0` with base primary stats of `1`, `15` stat
points, `10` combat-skill points, `2` peace-skill points, `1` perk point,
`5 HP`, `7 MP`, and `100` XP to level `1`. Thresholds, grants, fight-XP caps,
and source NPC-group limits come from the complete Neverlands table rows
`0..27`; later incomplete rows are not extrapolated.

Implemented exact derived rules are `Health × 5` base HP, `Knowledge × 7` base
MP, `Strength × 5 + Health × 10 + level × 10` carried mass, and More Strength
adding `floor(level / 2)` effective Strength.

Numeric skills and boolean perks must remain separate progression surfaces
with separate point pools. A captured perk can be owned before its mechanical
effect is wired; effect formulas must not be inferred from its label.

Professions are a third, separate development area: binary profession access
and use-grown counters. One gathering loop is a possible MVP extension only
after its tool, timer, yield, failure, counter-growth, and interruption flows
are captured end to end.

Movement-affecting progression, such as Wanderer skill, encumbrance, or terrain
mastery, must feed the canonical travel-time formula.

## Economy

The economy supports:

- normal shop currency;
- inventory weight/slots;
- city shop buy/sell flows;

Direct player trade exists in Neverlands, but it is deferred until its exact
flow and constraints are captured.

## Social Presence

The game should always feel populated when other players are nearby:

- location/player list;
- persistent chat and private messages;
- timestamped personal gameplay results in the same chronological history;
- game-wide announcements in that same history;
- local player refresh after movement completion.

The mixed history is a durable player-feedback surface, not a second gameplay
authority. Combat, inventory, economy, world, and later domain records own the
facts they produce; the social layer owns audience-safe history, delivery, and
presentation. Personal entries are selected by the server for one recipient,
while world announcements are server-authored for all players. Neither
audience may be chosen through browser parameters.

The launch subset includes recipient-only fight completion with awarded combat
experience, successfully awarded NPC-loot items, and successfully deposited
NPC-loot NV. Inventory rows and the NV wallet/ledger are authoritative; social
events are emitted only after those mutations succeed. The subset also
provides a narrow server-side boundary for future captured world announcements
without inventing announcement content or a player/admin authoring screen.
These rows stay in the persistent chat timeline across main-content transitions
and recent reloads; they must not be reduced to transient toast notifications.

## Rails-Friendly Design Principles

- The server is authoritative for movement, actions, inventory, combat, and
  rewards.
- Browser timers are display of server state, not source of truth.
- World-map buttons are persisted action offers, not ad hoc controller params.
- Deterministic seeds and fixtures are preferred over random map generation for
  core movement and combat flows.
- Data model changes are allowed while the app is in development. Prefer clean
  schema over backward-compatible workarounds when the old design blocks the
  GDD.
