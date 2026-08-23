# Combat and Arena Domain

## Scope

Arena entry and matchmaking, active fights, action selection, authoritative
resolution, NPC/player participants, result finalization, public logs,
player-facing completion/loot fact handoff, and responsive fight presentation.

## Documentation chain

- Neverlands source summary: `doc/design/reference/combat/README.md`
- Composite observations indexed by that summary
- Cross-domain timeline observation:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Normalized designs: `doc/design/areas/arena.md` and
  `doc/design/features/combat.md`
- Delivery IDs: `COMBAT-ARENA-001`, `COMBAT-FIGHT-UI-001`, and
  `COMBAT-LOG-001` in `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/arena_combat.md`

## Current RPG status

Fully Implemented for the declared Arena Combat runtime contract. Broader
formula evidence and complete 1:1 fight-state visual parity remain partial.
Finalized participant/XP and successful NPC item/NV facts are handed to the
shell-owned durable timeline without replacing Combat's authoritative match,
reward, inventory, wallet, ledger, or log records.

## Important responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/arena/combat_resolver.rb`
- `app/services/chat/event_publisher.rb` (shell-owned presentation handoff)
- `app/controllers/arena_matches_controller.rb`
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Section 16 of `doc/features/arena_combat.md` is exhaustive.

## Evidence and implementation gaps

Waiting, timeout, surrender, result, multi-opponent, public-log, magic/status,
and remaining formula states require bounded comparison or evidence.
