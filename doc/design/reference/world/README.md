# Neverlands Open World and Movement Source Summary

- Document type: neverlands-source-summary
- Domain: world
- Updated: 2026-07-29
- Evidence status: current for the bounded World implementation

## Current observations

| Flow/state | Observation | Status |
|---|---|---|
| Outdoor movement, map geometry, timing, village route | `doc/design/reference/world/observations/2026-05-09_overworld_movement.md` | current, with dated follow-ups |
| Local resource action, hostile interruption, combat return | `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md` | current |
| City gate handoff | `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md` | current cross-domain evidence |

## Current Neverlands behavior

- Outdoor cells use 100×100 presentation tiles and server-issued movement
  destinations/action keys.
- The desktop viewport shows a centered fixed cursor while terrain moves during
  a timed step.
- Current-cell context may expose buildings or local actions; hidden hostile
  NPC state can interrupt an outdoor action.
- Linked locations such as the observed village retain the authoritative
  outdoor coordinate through entry and return.

## Evidence gaps

- Mines, exchanges, other linked-location families, successful fishing,
  drinking, digging, and a complete profession yield loop remain unverified.

## Design linkage

- `doc/design/areas/world_map.md`
- `doc/design/features/movement.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/features/professions.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the declared World boundary
- Parity IDs: World rows in `doc/design/launch_mvp_plan.md` pending stable-ID migration
- Implementation handbook: `doc/features/world.md`

### Responsible implementation files

- `app/controllers/world_controller.rb`
- `app/services/game/world/tile_state_resolver.rb`
- `app/services/game/world/action_offer_builder.rb`
- `app/assets/stylesheets/world.css`

Local implementation linkage and responsive adaptation are local context, not
Neverlands evidence.
