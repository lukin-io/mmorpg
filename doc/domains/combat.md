# Combat and Arena Domain

## Scope

Arena entry and matchmaking, active fights, action selection, authoritative
resolution, NPC/player participants, result finalization, public logs, and
responsive fight presentation.

## Documentation chain

- Neverlands source summary: `doc/design/reference/combat/README.md`
- Composite observations indexed by that summary
- Normalized designs: `doc/design/areas/arena.md` and
  `doc/design/features/combat.md`
- Delivery IDs: `COMBAT-ARENA-001`, `COMBAT-FIGHT-UI-001`, and
  `COMBAT-LOG-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/arena_combat.md`

## Current RPG status

Fully Implemented for the declared Arena Combat runtime contract. Broader
formula evidence and complete 1:1 fight-state visual parity remain partial.

## Important responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_resolver.rb`
- `app/controllers/arena_matches_controller.rb`
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Section 16 of `doc/features/arena_combat.md` is exhaustive.

## Evidence and implementation gaps

Waiting, timeout, surrender, result, multi-opponent, public-log, magic/status,
and remaining formula states require bounded comparison or evidence.
