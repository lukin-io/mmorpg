# Open World and Movement Domain

## Scope

Outdoor coordinates, fixed-cell map presentation, movement, timers, fatigue,
current-cell composition, local actions, NPC/resource/building presence, linked
locations, login resume, and City handoff.

## Documentation chain

- Neverlands source summary: `doc/design/reference/world/README.md`
- Current observations: `doc/design/reference/world/observations/`
- Normalized area design: `doc/design/areas/world_map.md`
- Supporting designs: `doc/design/features/movement.md`,
  `doc/design/features/npcs_quests.md`, and
  `doc/design/features/professions.md`
- Delivery IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`, and
  `WORLD-LOCATION-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/world.md`
- Content operations: `doc/guides/managing_game_content.md`

## Current RPG status

Fully Implemented for the declared outdoor movement, resolved-cell,
Frontier-Village, NPC interruption, resource-action, and City-handoff boundary.
Other linked-location and action families remain Not Done.

## Important responsible implementation files

- `app/models/map_tile_template.rb`
- `app/models/tile_building.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `db/seeds.rb`

Section 16 of `doc/features/world.md` is exhaustive.

## Extension rule and gaps

Extend the existing persisted records and resolver/action-offer pipeline. Do
not add a parallel location catalog. Mines, exchanges, additional settlements,
and full profession yields require per-family evidence before implementation.
