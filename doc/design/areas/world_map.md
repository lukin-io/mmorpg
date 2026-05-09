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
city, after respawn, or after completing travel.

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
- `app/models/spawn_point.rb`
- `app/models/spawn_schedule.rb`

Controller, services, and views:

- `app/controllers/world_controller.rb`
- `app/services/game/movement/tile_provider.rb`
- `app/services/game/movement/turn_processor.rb`
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

- `spec/requests/world_spec.rb`
- `spec/system/world_map_spec.rb`
- `spec/system/world_interactions_spec.rb`
- `spec/views/world/_map_spec.rb`
- `spec/views/world/show_spec.rb`
- `spec/services/game/world/region_catalog_spec.rb`
- `spec/services/game/world/population_directory_spec.rb`
