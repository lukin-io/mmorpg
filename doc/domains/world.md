# Open World and Movement Domain

## Scope

Outdoor coordinates, fixed-cell map presentation, movement, timers, fatigue,
current-cell composition, local actions, hidden hostile interruption/passive
delivery, NPC/resource/building presence, linked locations, login resume, and
City handoff.

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
Frontier-Village, targetless passive/synchronous NPC interruption,
resource-action, and City-handoff boundary. Passive delivery resolves only the
persisted source-backed same-cell hostile through a server-owned persisted due
time. Neverlands observations confirm current-coordinate encounter
availability and same-coordinate return; its internal storage, exact
timing/probability distribution, complete eligible group pool, and selection
weights remain evidence gaps. Variable same-context group size/identity/level
output itself is now confirmed. Other linked-location and action families
remain Not Done.

## Important responsible implementation files

- `app/models/map_tile_template.rb`
- `app/models/tile_building.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `app/services/game/world/outdoor_npc_config.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/loot_entry.rb`
- `db/seeds.rb`

Section 16 of `doc/features/world.md` is exhaustive.

## Extension rule and gaps

Extend the existing persisted records and resolver/action-offer pipeline. Do
not add a parallel location catalog. Mines, exchanges, additional settlements,
and full profession yields require per-family evidence before implementation.
The authored Plague Rat item identity remains disabled at an explicit local
`0.0` evidence hold until its exact Neverlands probability is captured.
