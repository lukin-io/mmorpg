# Open World and Movement Domain

## Scope

Outdoor coordinates, fixed-cell map presentation, movement, timers, fatigue,
current-cell composition, local actions, hidden hostile interruption/passive
delivery, NPC/resource/building presence, linked locations, login resume, and
City handoff.

## Documentation chain

- Neverlands source summary: `doc/design/reference/world/README.md`
- Current observations: `doc/design/reference/world/observations/`
- Latest cell-content and water-action follow-up:
  `doc/design/reference/world/observations/2026-09-08_cell_content_and_world_rules.md`
- Normalized area design: `doc/design/areas/world_map.md`
- Supporting designs: `doc/design/features/movement.md`,
  `doc/design/features/npcs_quests.md`, and
  `doc/design/features/professions.md`
- Delivery IDs: `WORLD-UI-001`, `WORLD-MOVE-001`, `WORLD-CELL-001`, and
  `WORLD-LOCATION-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/world.md`; configured transport:
  `doc/features/airship_travel.md`
- Content operations: `doc/guides/managing_game_content.md`

## Current RPG status

Partially Implemented for broader open-world parity. The declared eight-neighbor
movement, resolved-cell, Frontier Village/Shop, targetless passive/synchronous
NPC interruption, timed empty Look, Drink, empty-bait fishing entry, and
City-handoff boundary is covered. Movement reads eight adjacent coordinates
or an exact target. Walking reuses unchanged overlapping cells and renders
only entering edges when the signed prior buffer is valid; fresh server offers
remain authoritative. Content changes, stale/invalid hints, or reload recover
through the full bounded buffer, independently of zone size.

Drink immediately recovers two fatigue points and keeps a 60-second lock.
The captured missing-bait fishing entry keeps a 30-second lock without a
catch, fatigue gain, or proficiency change. Neither action has a skill gate;
both require an active declaration on the exact current cell. Configurable
rules validate the existing Wanderer fallback, fatigue, Look/Fish/Drink timing,
and the explicit local presence policy. Their accepted action snapshots remain
durable across configuration changes. The complete Neverlands formulas remain
evidence gaps.

Passive delivery resolves only the
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
The content editor supports per-cell resource groups, action activation,
NPC activation, complete rosters, explicit weights, and member level ranges.
Those capacities do not populate unobserved groups or establish source
probabilities. Successful gathering is deferred to alchemy; successful fishing
equipment/bait/catch/proficiency flows, digging, and other linked-location
families remain Not Done.

## Important responsible implementation files

- `app/models/map_tile_template.rb`
- `app/models/tile_building.rb`
- `app/models/tile_npc.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/services/game/world/accept_action.rb`
- `app/services/game/world/perform_local_action.rb`
- `app/services/game/world/local_action_state.rb`
- `app/services/game/world/rules.rb`
- `app/queries/game/world/map_buffer.rb`
- `app/services/game/world/outdoor_npc_config.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/services/game/loot_entry.rb`
- `db/seeds.rb`

Section 16 of `doc/features/world.md` is exhaustive.

## Extension rule and gaps

The grid audit is
`doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`;
the September 8 follow-up above adds water actions and content organization.
Section 19 of `doc/features/world.md` records resolved implementation gaps and
the remaining regional-content and source-evidence limits. Current-cell/room
chat follows the confirmed Neverlands audience boundary; its session and
delivery owner is the shared-shell handbook.
`CharacterPosition.zone_id` already identifies the outdoor zone (region); it
must not be duplicated with a competing position/region model.
The MVP uses only Outpost Surroundings, with a sparse authored starter area.
Full zone population is Stage 2. Additional zones, enabled inter-zone routes,
and walking border mappings are explicit post-MVP TODOs. Equal coordinates in
separate test zones prove isolation. The completed Forpost-to-Oktal source journey is
recorded in
`doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`.
`doc/design/features/airship_travel.md` defines the configured transport
capability: paid boarding, bounded moving cells, server-clock zone progress,
and explicit destination landing. Normal routes remain unavailable until their
destination/path/schedule content exists; walking border mappings still need
source evidence before their later implementation. Actual world-position transitions clear
saved interior context atomically, while valid village/Shop/city/Arena-room
contexts can resume without changing the persisted coordinate.

Extend the existing persisted records and resolver/action-offer pipeline. Do
not add a parallel location catalog. Mines are planned as exact-cell
entrances using the existing position model; their interiors and actions,
exchanges, additional settlements, and full profession yields require
per-family evidence before implementation. Nature Child's known four-point
drinking recovery is configuration data for a future supported perk, not an
enabled perk feature.
The authored Plague Rat item identity remains disabled at an explicit local
`0.0` evidence hold until its exact Neverlands probability is captured.
