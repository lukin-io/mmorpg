# Combat and Arena Domain

## Scope

Arena entry and matchmaking, active fights, action selection, authoritative
resolution, NPC/player participants, result finalization, public logs,
player-facing completion/loot fact handoff, and responsive fight presentation.

## Documentation chain

- Neverlands source summary: `doc/design/reference/combat/README.md`
- Current concrete flow:
  `doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md`
- Composite observations indexed by the source summary
- Cross-domain timeline observation:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Normalized designs: `doc/design/areas/arena.md` and
  `doc/design/features/combat.md`
- Canonical delivery status: Combat Completion Matrix under Pillar 3 in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/arena_combat.md`

## Current RPG status

Canonical roll-up: bounded physical MVP is `VERIFICATION_NEEDED`; full
Neverlands Combat is `EVIDENCE_NEEDED`. The mechanic-level status, scope, and
exact next gate live only in the Combat Completion Matrix in
`doc/design/launch_mvp_plan.md`.

Within that roll-up, `COMBAT-ARENA-001` and `COMBAT-PVP-PHYSICAL` are `DONE`
for their declared bounded runtime contracts. Finalized participant/XP and
successful NPC item/NV facts are handed to the shell-owned durable timeline
without replacing Combat's authoritative match, reward, inventory, wallet,
ledger, or log records.

The shared Arena, PvP, team, and wilderness path now snapshots the exact
level/Extra-AP budget, filters source-injected actions, validates the normal
and shield `40/70/90` selector tables, preserves source turn-package/no-op
semantics, uses the captured paired-rat encounter XP total, and applies exact
result-based wear including Careful Fighter. The active surface displays the
profile's `5..N` magic-hit ceiling independently from current MP, as the live
level-17 shield flow confirmed.

## Important responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_profile.rb`
- `app/lib/game/combat/action_catalog.rb`
- `app/services/arena/npc_experience_awarder.rb`
- `app/services/arena/equipment_wear_resolver.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/game/loot_entry.rb`
- `app/services/arena/combat_resolver.rb`
- `app/services/chat/event_publisher.rb` (shell-owned presentation handoff)
- `app/controllers/arena_matches_controller.rb`
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Section 16 of `doc/features/arena_combat.md` is exhaustive.

## Evidence and implementation gaps

The canonical matrix distinguishes `EVIDENCE_NEEDED` formula/mechanic gaps from
`VERIFICATION_NEEDED` PvE, team, fight-UI, and public-log checks. Physical
`1x1` PvP has completed its two-seeded-player browser gate. The
current `150 mastery -> -10 AP` and `130 mastery -> -8 AP` observations remain
insufficient to promote the fitting `floor(mastery / 15)` candidate into a
rule.
