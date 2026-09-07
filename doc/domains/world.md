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

Partially Implemented for broader open-world parity. The declared eight-neighbor
movement, resolved-cell, Frontier Village/Shop, targetless passive/synchronous
NPC interruption, timed empty Look result, and City-handoff boundary is covered.
Movement reads eight adjacent coordinates or an exact target, and the nearby
map buffer remains bounded independently of region size. Passive delivery resolves only the
persisted source-backed same-cell hostile through a server-owned persisted due
time. A captured variable cell may select one complete validated roster sample
and one captured delay window; fixed anchors retain their explicit composition
and provisional delay. Neverlands observations confirm current-coordinate
availability, same-coordinate return, variable group size/identity/level, and
four completed same-cell sampled encounters plus three distinct interval
bounds. A sampled local anchor therefore remains eligible after victory and
Finish; a fixed anchor retains its defeated/respawn lifecycle. Neverlands'
internal storage, exact timing/probability distribution, complete eligible
group pool, and selection weights remain evidence gaps. Authored encounter
sides support `1..10` members; the capacity does not populate unobserved rosters.
Successful gathering is deferred by the user to the alchemy skill path. Other
linked-location and action families remain Not Done.

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
- `app/services/game/world/encounter_roster_selector.rb`
- `app/services/game/loot_entry.rb`
- `db/seeds.rb`

Section 16 of `doc/features/world.md` is exhaustive.

## Extension rule and gaps

The fresh grid/action audit is
`doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`.
Section 19 of `doc/features/world.md` records resolved implementation gaps and
the remaining regional-content and source-evidence limits. Current-cell/room
chat follows the confirmed Neverlands audience boundary; its session and
delivery owner is the shared-shell handbook.
`CharacterPosition.zone_id` already identifies a region; it must not be
duplicated with a competing position/region model.
Only Outpost Surroundings is populated. Equal coordinates in separate test
regions prove isolation; more populated regions and crossing gameplay remain
outside the current delivery scope. Actual world-position transitions clear
saved interior context atomically, while valid village/Shop/city/Arena-room
contexts can resume without changing the persisted coordinate.

Extend the existing persisted records and resolver/action-offer pipeline. Do
not add a parallel location catalog. Mines, exchanges, additional settlements,
and full profession yields require per-family evidence before implementation.
The authored Plague Rat item identity remains disabled at an explicit local
`0.0` evidence hold until its exact Neverlands probability is captured.
