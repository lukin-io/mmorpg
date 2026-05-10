# World Map Area

## Purpose

The world map is the outdoor exploration surface. It is where players travel
between coordinates, discover local actions, meet nearby players, encounter
hostile NPCs, gather resources, and enter cities or buildings offered by the
current tile.

## Neverlands Reference

Primary reference: `doc/flow/neverlands_live_movement.md`.

Observed Neverlands behavior:

- the main gameplay frame renders a grid of map tiles;
- only server-offered destination tiles are clickable;
- each destination has its own short-lived action key;
- movement has an accepted travel duration, observed as 30 seconds near Oktal;
- the browser shows a cursor animation and countdown during movement;
- local presence refreshes after movement completion;
- contextual buttons such as `Войти` appear from the current tile state.

## Screen Model

The world map screen is a compact game surface:

- top character/vitals/action bar;
- tile grid centered on the player;
- visible clickable movement markers;
- player cursor or travelling sprite;
- countdown overlay during movement;
- local player list/presence panel;
- chat frame or chat bar.

It should feel like a utilitarian MMORPG client, not a large marketing page.

## Entry And Exit

Players enter the world map after login/character selection, after leaving a
city, after respawn, or after completing travel. Login is a resume action: when
the account already has a character, the post-login entry point opens the world
screen and renders the character's persisted `character_positions` cell. A spawn
point is only used to bootstrap a character with no position row.

Players leave the world map by:

- entering a city through a contextual action;
- entering a tile building when offered;
- starting combat or another feature overlay;
- using teleport/respawn systems when available.

## Available Actions

The map can offer:

- movement to nearby tiles;
- character profile;
- inventory;
- enter city/building;
- look around;
- gather;
- fish;
- dig;
- drink/use terrain feature;
- quest interaction;
- hostile encounter or attack;
- local NPC dialogue.

The server decides which actions exist for the current finalized location.

## Rules

- Outdoor movement is coordinate-based.
- Destination availability is server-authored.
- Movement is accepted by the server before the UI enters travelling state.
- Movement completion updates the authoritative coordinate.
- Reload during travel resumes the travelling state from server time.
- The map does not invent passability in the browser.
- The local player list refreshes after movement completion.

## World State Persistence

The world map must be reproducible from database state on every request. The
browser may animate and submit choices, but it must not own world state.

Persistent state sources:

- `character_positions`: current finalized zone and coordinate.
- `movement_commands`: offered and active movement, including action key,
  source coordinate, target coordinate, and travel timestamps.
- `map_tile_templates`: terrain, passability, and static map metadata.
- `tile_resources`: resource node identity, quantity, depletion, respawn, and
  last harvester.
- `tile_npcs`: spawned NPC identity, HP, defeated state, respawn, and template.
- `tile_buildings`: city, castle, dungeon, shop, portal, or other enterable
  structures attached to a coordinate.

Player-facing persistence rule: closing and reopening the browser must never
reset the player to a default or browser-held position. The server reloads the
same `character_positions` row. If a movement was active while the browser was
closed, the server either resumes it or finalizes it from `movement_commands`.

## Current Parity

Implemented:

- post-login entry into the world screen for accounts with a character;
- movement position persistence through `character_positions`;
- movement offers and accepted travel through `movement_commands`;
- accepted movement cancels sibling destination offers in the database;
- reload/resume/finalize behavior through the movement state services;
- DB-backed resources, NPCs, and buildings for current-tile state;
- persisted action offers for gather, NPC attack/talk, and building entry;
- action-key validation against character, zone, coordinate, action type, and
  target before dispatch.

Not yet strict Neverlands-style:

- city image-map hotspots are not yet persisted as `WorldActionOffer` rows;
- local presence refresh is not yet split into a separate Neverlands-style
  refreshable frame.

## Technical Solution

The world map uses a single authoritative tile-state/action-offer layer.

Pipeline for every world map request:

1. Complete due movement.
2. Load current `character_positions`.
3. Resolve current tile state with `Game::World::TileStateResolver`.
4. Materialize any generated resource/NPC into `tile_resources` or `tile_npcs`
   before rendering it.
5. Build movement offers and contextual action offers.
6. Render only the action offers returned by the server.

Persistence model:

```text
world_action_offers
- character_id
- zone_id
- x
- y
- action_type
- target_type
- target_id
- action_key
- status
- expires_at
- accepted_at
- completed_at
- error_message
- metadata
```

Action examples:

| Action | Persistent Target | Handler |
| --- | --- | --- |
| Move | `MovementCommand` | `Game::Movement::AcceptMove` |
| Gather | `TileResource` | `Game::World::TileGatheringService` |
| Attack/Talk | `TileNpc` | combat or dialogue service |
| Enter city/building/dungeon | `TileBuilding` | building/city transition service |

Validation rules:

- action key must match current character, zone, coordinate, action type, and
  target;
- stale offers are rejected;
- offers are cancelled/reissued when the authoritative map state changes;
- generated NPC/resource state is materialized before any offer is issued;
- accepted actions write a result row or status update for audit and replay.

## Area Graph

The outdoor map is a coordinate graph. In the starter reference area:

```text
1019,1025 -> 1018,1025
1019,1025 -> Oktal city entry action
```

The graph may later expand to more coordinates, roads, terrain costs, and
encounter tables, but starter implementation should remain deterministic.

## Feature Hooks

- `features/movement.md`
- `features/social_chat_presence.md`
- `features/gathering_professions.md`
- `features/npcs_quests.md`
- `areas/cities_and_buildings.md`
- `features/combat.md`

## Out Of Scope

- Procedural world generation for the core map.
- Pathfinding across many tiles as the first movement experience.
- Decorative map layers that do not affect available actions.

## Related Implementation Files

Models:

- `app/models/character_position.rb`
- `app/models/zone.rb`
- `app/models/map_tile_template.rb`
- `app/models/tile_resource.rb`
- `app/models/tile_npc.rb`
- `app/models/tile_building.rb`
- `app/models/world_action_offer.rb`
- `app/models/spawn_point.rb`
- `app/models/spawn_schedule.rb`

Controller, services, and views:

- `app/controllers/application_controller.rb`
- `app/controllers/world_controller.rb`
- `app/services/game/movement/map_state.rb`
- `app/services/game/movement/accept_move.rb`
- `app/services/game/movement/complete_move.rb`
- `app/services/game/movement/travel_time.rb`
- `app/services/game/movement/tile_provider.rb`
- `app/services/game/movement/turn_processor.rb`
- `app/services/game/world/tile_gathering_service.rb`
- `app/services/game/world/tile_npc_service.rb`
- `app/services/game/world/tile_building_service.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `app/services/game/world/region_catalog.rb`
- `app/services/game/world/population_directory.rb`
- `app/views/world/show.html.erb`
- `app/views/world/_map.html.erb`
- `app/views/world/_actions.html.erb`
- `app/views/world/_location_info.html.erb`
- `app/views/world/_players_here.html.erb`
- `app/javascript/controllers/nl_world_map_controller.js`

Config and data:

- `config/gameplay/biomes.yml`
- `config/gameplay/terrain_modifiers.yml`
- `config/gameplay/world/regions.yml`
- `config/gameplay/world/resource_nodes.yml`
- `db/seeds.rb`

Specs:

- `spec/models/movement_command_spec.rb`
- `spec/requests/login_resume_spec.rb`
- `spec/requests/world_spec.rb`
- `spec/services/game/movement/map_state_spec.rb`
- `spec/services/game/movement/accept_move_spec.rb`
- `spec/services/game/movement/complete_move_spec.rb`
- `spec/services/game/movement/travel_time_spec.rb`
- `spec/system/world_map_spec.rb`
- `spec/system/world_interactions_spec.rb`
- `spec/views/world/_actions_spec.rb`
- `spec/views/world/_map_spec.rb`
- `spec/views/world/show_spec.rb`
- `spec/models/world_action_offer_spec.rb`
- `spec/services/game/world/action_offer_builder_spec.rb`
- `spec/services/game/world/accept_action_spec.rb`
- `spec/services/game/world/region_catalog_spec.rb`
- `spec/services/game/world/population_directory_spec.rb`
