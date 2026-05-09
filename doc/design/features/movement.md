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

## Persistence Contract

Neverlands-style movement is persistent server state, not browser state.

Authoritative state:

- `character_positions` stores the finalized coordinate and zone.
- `movement_commands` stores each offered, accepted, active, completed, failed,
  or cancelled movement.
- An accepted movement does not immediately change `character_positions`.
- Active movement stores source coordinate, target coordinate, start time,
  end time, travel duration, and action key.
- Reopening the browser must load from database state:
  - if no movement is active, the player appears at the finalized coordinate;
  - if movement is active and not due, the countdown resumes from `ends_at`;
  - if movement is due, the server finalizes it before rendering the map.
- Login with an existing character enters the world screen directly and uses the
  same persisted position/resume logic. It must not route the player to an
  unrelated dashboard before the game surface.

Expected player result: if a player walks in the open world, closes the browser,
and opens the game later, they are still at the same finalized cell or at the
completed destination if the travel timer elapsed while they were away.

## Current Implementation Status

Current movement implementation is close to the required persistence model:

- `Game::Movement::MapState` creates server-authored destination offers.
- `Game::Movement::AcceptMove` accepts an offer and starts timed travel.
- `Game::Movement::CompleteMove` finalizes due travel into
  `character_positions`.
- `movement_commands` now has source, target, action key, travel seconds,
  start time, end time, completion, and failure fields.
- The browser submits only server-issued `target_x`, `target_y`, and
  `action_key`.
- Accepting one movement offer cancels sibling destination offers for the same
  character and zone so stale movement choices do not remain live in the DB.

World-map contextual action parity now follows the same server-authored shape:

- `WorldActionOffer` stores short-lived action keys for gather, NPC, and
  building entry actions;
- `Game::World::TileStateResolver` materializes current-tile resource/NPC state
  before the action is rendered;
- `Game::World::ActionOfferBuilder` issues contextual action offers from the
  DB-backed tile state;
- `Game::World::AcceptAction` validates character, zone, coordinate, action
  type, target, and expiry before dispatching the action.

Remaining parity gaps:

- city image-map hotspots still use the city hotspot service and are not yet
  backed by `WorldActionOffer`;
- local presence refresh after movement completion is not yet a separate
  persisted/refreshable panel like Neverlands `ch_list`.

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

## Technical Direction

The open-world map uses one server-authored state-building pipeline:

1. Finalize due movement for the character.
2. Load `character_positions` as the current authoritative location.
3. Materialize tile context for the current location:
   - resource from `TileResource`;
   - NPC from `TileNpc`;
   - building/city/dungeon entrance from `TileBuilding`;
   - terrain/passability from `MapTileTemplate`.
4. Create short-lived action offers for everything the player can do:
   - movement offers;
   - gather offers;
   - attack/talk offers;
   - enter city/building/dungeon offers;
   - inspect/profile/inventory offers when needed by the UI.
5. Render only those offers to the browser.
6. Accept an action only when its action key still matches the current
   character, zone, coordinate, target, and action type.

Implementation objects:

- `Game::World::TileStateResolver`
  - returns stable DB-backed state for the current tile;
  - materializes generated NPC/resource records before showing them;
  - removes display-only procedural resource/NPC hints from map rendering.
- `WorldActionOffer`
  - stores `character_id`, `zone_id`, `x`, `y`, `action_type`, `target_type`,
    `target_id`, `action_key`, `expires_at`, `status`, and metadata;
  - replaces ad hoc action buttons without action-key persistence.
- `Game::World::ActionOfferBuilder`
  - creates movement and contextual action offers from tile state;
  - invalidates old offers on each authoritative map-state build.
- `Game::World::AcceptAction`
  - validates the action key and dispatches to movement, gathering, NPC,
    combat, or building-entry handlers.

Movement remains in `movement_commands`; non-movement tile actions are tracked
in `WorldActionOffer` so every current map action has a server-issued key and an
auditable result.

## Out Of Scope

- Long-distance pathfinding as the first movement interaction.
- Browser-only cooldowns.
- City travel countdowns for the starter city.

## Related Implementation Files

Current codebase movement uses the server-offered travel lifecycle described
above. The broader map-action parity gaps are tracked in this document and in
`doc/flow/neverlands_movement_codebase_analysis.md`.

Models:

- `app/models/character_position.rb`
- `app/models/movement_command.rb`
- `app/models/map_tile_template.rb`
- `app/models/zone.rb`
- `app/models/spawn_point.rb`
- `app/models/spawn_schedule.rb`
- `app/models/tile_building.rb`
- `app/models/tile_resource.rb`
- `app/models/tile_npc.rb`
- `app/models/world_action_offer.rb`

Controller and routes:

- `app/controllers/application_controller.rb`
- `app/controllers/world_controller.rb`
- `config/routes.rb`

Movement services:

- `app/services/game/movement/turn_processor.rb`
- `app/services/game/movement/map_state.rb`
- `app/services/game/movement/accept_move.rb`
- `app/services/game/movement/complete_move.rb`
- `app/services/game/movement/travel_time.rb`
- `app/services/game/movement/movement_validator.rb`
- `app/services/game/movement/tile_provider.rb`
- `app/services/game/movement/terrain_modifier.rb`
- `app/services/game/movement/pathfinder.rb`
- `app/services/game/movement/command_queue.rb`
- `app/services/game/movement/respawn_service.rb`
- `app/services/game/movement/teleport_service.rb`
- `app/services/game/exploration/encounter_resolver.rb`

World feature services connected to movement:

- `app/services/game/world/tile_building_service.rb`
- `app/services/game/world/tile_gathering_service.rb`
- `app/services/game/world/tile_npc_service.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `app/services/game/world/population_directory.rb`
- `app/services/game/world/region_catalog.rb`

Views:

- `app/views/world/show.html.erb`
- `app/views/world/_map.html.erb`
- `app/views/world/_actions.html.erb`
- `app/views/world/_location_info.html.erb`
- `app/views/world/_players_here.html.erb`
- `app/views/world/_quick_actions.html.erb`
- `app/views/world/_character_panel.html.erb`

JavaScript:

- `app/javascript/controllers/nl_world_map_controller.js`

Jobs:

- `app/jobs/game/movement_command_processor_job.rb`

Config, seeds, and migrations:

- `config/gameplay/terrain_modifiers.yml`
- `config/gameplay/biomes.yml`
- `config/gameplay/world/regions.yml`
- `db/migrate/20251121090004_create_map_tile_templates.rb`
- `db/migrate/20251122120000_create_world_navigation_systems.rb`
- `db/migrate/20251124130000_create_movement_commands.rb`
- `db/migrate/20260509210000_add_neverlands_travel_fields_to_movement_commands.rb`
- `db/migrate/20260509211000_create_world_action_offers.rb`
- `db/seeds.rb`

Specs:

- `spec/models/movement_command_spec.rb`
- `spec/requests/login_resume_spec.rb`
- `spec/services/game/movement/map_state_spec.rb`
- `spec/services/game/movement/accept_move_spec.rb`
- `spec/services/game/movement/complete_move_spec.rb`
- `spec/services/game/movement/travel_time_spec.rb`
- `spec/services/game/movement/turn_processor_spec.rb`
- `spec/services/game/movement/tile_provider_spec.rb`
- `spec/services/game/movement/command_queue_spec.rb`
- `spec/models/map_tile_template_spec.rb`
- `spec/models/tile_building_spec.rb`
- `spec/models/tile_resource_spec.rb`
- `spec/models/tile_npc_spec.rb`
- `spec/models/world_action_offer_spec.rb`
- `spec/services/game/world/action_offer_builder_spec.rb`
- `spec/services/game/world/accept_action_spec.rb`
- `spec/requests/world_spec.rb`
- `spec/system/world_map_spec.rb`
- `spec/system/world_interactions_spec.rb`
- `spec/views/world/_actions_spec.rb`
- `spec/views/world/_map_spec.rb`
- `spec/views/world/show_spec.rb`
