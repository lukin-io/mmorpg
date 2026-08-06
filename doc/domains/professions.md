# Professions Domain

## Scope

Future source-backed profession eligibility, tools, current-cell actions,
timers, interruption, resource yield, progression counters, failure behavior,
and Inventory handoff.

## Documentation chain

- Neverlands source summary: `doc/design/reference/professions/README.md`
- Evidence gap:
  `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`
- Normalized design: `doc/design/features/professions.md`
- Delivery ID: `PROFESSION-FLOW-001` in `doc/design/launch_mvp_plan.md`
- Implementation placeholder: `doc/features/professions.md`

## Current RPG status

`NOT_IMPLEMENTED`. Existing resource actions and skill labels are adjacent
evidence; they do not constitute a complete profession system.

## Important responsible implementation files

- Runtime implementation: `NOT_IMPLEMENTED`
- Existing adjacent cell ownership:
  `app/services/game/world/tile_state_resolver.rb`
- Existing adjacent inventory ownership:
  `app/services/game/inventory/manager.rb`

## Evidence and implementation gaps

Capture one complete tool/timer/yield/counter/failure/interruption loop. Then
extend the existing World and Inventory owners or justify any new owner in the
design before implementation.
