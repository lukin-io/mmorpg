# Game Design Document

This is the design source of truth for the project. The game is a
Neverlands-inspired browser MMORPG, not a one-to-one asset or content clone.
When implementation docs, tests, or code disagree with this file, this file
wins and the derived material should be updated.

## Reference Hierarchy

1. This GDD defines intended game behavior.
2. `doc/design/features/*` and `doc/design/areas/*` break the GDD into
   buildable feature and area documents.
3. `doc/design/reference/neverlands.md` explains how Neverlands observations
   should be translated into this project's design language.
4. `doc/flow/neverlands_live_movement.md` and
   `doc/flow/neverlands_live_city_movement.md` are the captured live references
   for movement and city movement feel.
5. Other `doc/flow/*`, `doc/features/*`, and root guide files are supporting or
   implementation notes. They are not allowed to override this GDD.

## Design Library

Use these documents when implementing or extending the game design:

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
- `doc/design/features/gathering_professions.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/social_chat_presence.md`

Documentation process:

- `doc/design/documentation_model.md`
- `doc/design/reference/neverlands.md`
- `doc/design/reference/source_material.md`

## Vision

Build a classic, persistent, browser-first fantasy MMORPG with slow, deliberate
map movement, tile-local actions, social presence, tactical combat, character
growth, player economy, and profession systems.

The intended feel is:

- compact game UI instead of a landing-page style app;
- server-authoritative actions;
- readable location state and visible nearby player presence;
- movement that has weight, travel time, and contextual consequences;
- deterministic world data suitable for testing and iteration;
- mechanics that are inspired by Neverlands but adapted for this codebase.

## Core Loop

1. Player logs in and enters the world at a known spawn point.
2. The world view shows the current location, map tiles, nearby players, and
   tile-local actions.
3. Player chooses a server-offered destination or local action.
4. Movement/actions lock relevant buttons and show a timer when they take time.
5. Completion refreshes current location, available movement, tile actions,
   resources, NPCs, buildings, encounters, and nearby player list.
6. Player gains resources, combat progress, quest progress, reputation, skill
   growth, or economy opportunities.

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
  enter, look around, gather, fish, dig, drink, quest, or combat actions.

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
- building pages provide feature-specific UI and a `Город` return action;
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

Baseline formula:

```text
travel_seconds =
  base_zone_seconds
  * terrain_modifier(target tile)
  * diagonal_modifier
  * encumbrance_modifier
  / mount_multiplier
  * skill_modifier
```

The observed Neverlands reference move from `1019,1025` to `1018,1025` used
`30` seconds. Use that as the initial starter-area reference unless a specific
developer-mode override is intentionally added.

### Direction Policy

The GDD must explicitly choose one policy:

- cardinal-only movement; or
- eight-direction movement with diagonals.

Until changed, the target policy is eight-direction movement because the current
map and `TurnProcessor` already expose diagonals. All layers must follow the
same policy: service, model validation, pathfinding, map rendering, JS, action
buttons, and tests.

### Passability Policy

One server service owns passability. Views and browser controllers do not invent
movement availability. Missing tile data must have a deterministic rule and
must render the same way it validates.

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
- biome;
- encounter table;
- spawn points;
- tile templates;
- allowed local action types.

Starter world data should be deterministic. The first canonical movement test
area should use a Neverlands-inspired coordinate neighborhood around
`1019,1025` so docs, seeds, tests, and UI examples talk about the same place.

## Tile-Local Actions

Movement completion is the refresh boundary for tile-local actions. A map state
may offer buttons for:

- character/profile;
- inventory;
- enter/exit building or location;
- look around;
- gather resource;
- fish;
- dig;
- drink/use terrain feature;
- talk to NPC;
- attack hostile NPC;
- quest interaction.

Each action that mutates state should be server-authoritative and validated
against the current tile.

## Combat

Combat is turn-based and tactical. Core expectations:

- PvE encounters can trigger from map movement or tile-local hostile actions;
- PvP supports duels, group battles, arena rooms, and clan conflict;
- combat uses explicit turns, action points, body-part targeting, blocks,
  skills, logs, rewards, and death/respawn consequences;
- combat state must be resumable and auditable.

## Character Progression

Characters grow through:

- experience and levels;
- stat allocation;
- passive skills;
- class or specialization choices;
- profession progress;
- reputation and alignment;
- equipment and inventory growth.

Movement-affecting progression, such as Wanderer skill, mounts, encumbrance, or
terrain mastery, must feed the canonical travel-time formula.

## Economy And Professions

The economy supports:

- gold and premium currency;
- inventory weight/slots;
- marketplace and auction flows;
- direct trade;
- crafting professions;
- gathering and resource respawn;
- equipment upgrades and item sinks.

Profession actions may lock movement with timers, matching the same lock/resume
model as movement.

## Social Presence

The game should always feel populated when other players are nearby:

- location/player list;
- chat;
- private messages;
- friends;
- guilds/clans;
- moderation tools;
- local player refresh after movement completion.

## Technical Design Principles

- Rails monolith with Hotwire/Stimulus remains the default architecture.
- The server is authoritative for movement, actions, inventory, combat, and
  rewards.
- Browser timers are display of server state, not source of truth.
- Deterministic seeds and fixtures are preferred over random map generation for
  core movement and combat flows.
- Data model changes are allowed while the app is in development. Prefer clean
  schema over backward-compatible workarounds when the old design blocks the
  GDD.
