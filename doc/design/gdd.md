# Game Design Document

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

- `doc/design/README.md`
- `doc/design/launch_mvp_plan.md`
- `doc/design/reference/neverlands.md`
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
5. Completion refreshes current location, available movement, tile actions,
   NPCs, buildings, encounters, and nearby player list.
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
  enter, NPC, building, or combat actions.

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

### Travel Time

Travel time is a GDD-level value, not a browser-only cooldown. The same formula
must be used for destination offers, accepted movement validation, countdown
display, and action readiness.

Captured starter formula:

```text
travel_seconds = 30
```

The observed Neverlands reference move from `1019,1025` to `1018,1025` used
`30` seconds. Use that as the initial starter-area reference unless a specific
developer-mode override is intentionally added. Do not add terrain, diagonal,
encumbrance, or skill timing modifiers until they are source-captured.

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

Starter world data should be deterministic. The first canonical movement test
area should use a Neverlands-based coordinate neighborhood around
`1019,1025` so docs, seeds, tests, and UI examples talk about the same place.

## Tile-Local Actions

Movement completion is the refresh boundary for tile-local actions. A map state
may offer buttons for:

- character/profile;
- inventory;
- enter/exit building or location;
- talk to NPC;
- attack hostile NPC;
- future captured quest interaction.

Each action that mutates state should be server-authored, persisted, and
validated against the current tile. The map renders action offers issued by the
server; each offer has a short-lived action key tied to character, zone,
coordinate, action type, and target.

## Combat

Combat is turn-based and tactical. Core expectations:

- PvE encounters can trigger from map movement or tile-local hostile actions;
- player, team, and NPC fights support Neverlands-style arena duels, group
  fights, and room-based applications;
- combat uses explicit turns, action points, body-part targeting, blocks,
  skills, logs, rewards, and death/respawn consequences;
- combat state must be resumable and auditable.

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
- passive skills;
- Neverlands alignment/sign markers where source-backed;
- equipment and inventory growth.

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
- chat;
- private messages;
- local player refresh after movement completion.

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
