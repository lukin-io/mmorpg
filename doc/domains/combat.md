# Combat and Arena Domain

Fresh evidence: [September14 human unarmed Duel](../design/reference/combat/observations/2026-09-14_arena_fist_duel.md) — accepted
application, applicant Start/refusal, six exchanges including opponent magic,
loss XP, public log/profile location, Finish and recovery. September12 absence
of a live human fight below is historical, superseded for this Duel scope.

Current September12 work: the user authorized pragmatic completion of the22-fight
observations. [Combat calibration](../design/features/combat_calibration.md)
owns fitted coefficients and placement; [Medical Care](../features/medical_care.md)
owns injury/treatment. Earlier exact-formula evidence holds below no longer
mean these features must remain disabled. The bounded scope passed
[final local acceptance](../features/arena_combat.md#september-12-final-calibrated-acceptance).


## Scope

Arena entry and matchmaking, active fights, action selection, authoritative
resolution, NPC/player participants, result finalization, public logs,
player-facing completion/loot fact handoff, and responsive fight presentation.

## Documentation chain

- [Required working context and update rules](../DOCUMENTATION.md#21-required-context-and-update-map)
- Build/aftermath guides: [CHARACTER](../CHARACTER.md) explains effective inputs
  and progression; [MEDICAL](../MEDICAL.md) explains injury penalties, supplies
  and treatment after defeat.
- Arena area guide: [ARENA](../ARENA.md) for halls, applications, training,
  admission/assembly, presentation, recovery and editing.
- General feature guide: [COMBAT](../COMBAT.md); targeted entry guide:
  [SCROLLS](../SCROLLS.md). Read these for the complete local flow and editing map.
- Game reference books: [NPC catalog and editing](../NPC.md),
  [formulas and tuning](../FORMULAS.md)
- Related inputs and outputs: [item properties](../ITEMS.md#3-fields-slots-and-effective-properties),
  [world return context](../WORLD.md#5-travel-context-and-return-behavior),
  [event/log catalog](../features/game_shell.md#gameplay-event-catalog)

- Neverlands source summary: [doc/design/reference/combat/README.md](../design/reference/combat/README.md)
- Current concrete flows:
  [doc/design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md](../design/reference/combat/observations/2026-08-26_wilderness_shield_npc_fight.md),
  [doc/design/reference/combat/observations/2026-08-26_wilderness_two_orc_group_fight.md](../design/reference/combat/observations/2026-08-26_wilderness_two_orc_group_fight.md),
  and
  [doc/design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md](../design/reference/combat/observations/2026-08-26_wilderness_passive_goblin_fight.md),
  plus the current variable-group/magic chain in
  [doc/design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md](../design/reference/combat/observations/2026-09-01_wilderness_bandit_group_variation_and_magic.md)
  and the current large-roster/search/timeout chain in
  [doc/design/reference/combat/observations/2026-09-02_swamp_passive_rosters_search_and_timeout.md](../design/reference/combat/observations/2026-09-02_swamp_passive_rosters_search_and_timeout.md)
- Composite observations indexed by the source summary
- Cross-domain timeline observation:
  [doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md](../design/reference/social/observations/2026-08-23_chat_game_event_timeline.md)
- Normalized designs: [doc/design/areas/arena.md](../design/areas/arena.md) and
  [doc/design/features/combat.md](../design/features/combat.md)
- Canonical delivery status: Combat Completion Matrix under Pillar 3 in
  [doc/design/launch_mvp_plan.md](../design/launch_mvp_plan.md)
- Current implementation: `doc/features/arena_combat.md` ([handbook](../features/arena_combat.md))

## Current RPG status

Canonical roll-up: bounded physical MVP is `DONE`; full
Neverlands Combat is `EVIDENCE_NEEDED`. The mechanic-level status, scope, and
exact next gate live only in the Combat Completion Matrix in
`doc/design/launch_mvp_plan.md`.

Within that roll-up, `COMBAT-ARENA-001`, `COMBAT-PVP-PHYSICAL`, and
`COMBAT-PVE-PHYSICAL`, `COMBAT-TEAM-TURNS`, `COMBAT-FIGHT-UI-001`, and
`COMBAT-LOG-001` are `DONE` for their declared bounded runtime contracts.
Finalized participant/XP and
successful NPC item/NV facts are handed to the shell-owned durable timeline
without replacing Combat's authoritative match, reward, inventory, wallet,
ledger, or log records.

The shared Arena, PvP, team, and wilderness path now snapshots the exact
level/Extra-AP budget, filters source-injected actions, validates the normal
and shield `40/70/90` selector tables, preserves source turn-package/no-op
semantics, uses the captured paired-rat encounter XP total, and applies exact
result-based wear including Careful Fighter. The active surface displays the
profile's `5..N` magic-hit ceiling independently from current MP, as the live
level-17 shield flow confirmed. The World entry now uses the same path for
fixed or complete sampled mixed rosters, persists member level/HP and
encounter XP/risk, preserves sampled-cell eligibility after full victory and
Finish, and enforces the explicit five-minute World-fight deadline. Fixed
anchors retain their defeated/respawn lifecycle.

Actual Arena HTML room selection persists and resumes after current City,
room activity, level/alignment, and optional city-binding checks. JSON previews
do not select a room; entering another city clears stale selection. Shared
ordinary chat and presence use the selected room rather than all city players.
World-authored encounter capacity is `1..10`, with eleven rejected before
partial fight creation; this does not add uncaptured opponents to seeded cells.

## Important responsible implementation files

- `app/services/arena/combat_processor.rb`
- `app/services/arena/combat_profile.rb`
- `app/lib/game/combat/action_catalog.rb`
- `app/services/arena/experience_awarder.rb`
- `app/services/arena/equipment_wear_resolver.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/game/loot_entry.rb`
- `app/services/arena/combat_resolver.rb`
- `app/services/chat/event_publisher.rb` (shell-owned presentation handoff)
- `app/controllers/arena_matches_controller.rb`
- `app/controllers/world_encounter_checks_controller.rb`
- `app/services/game/world/passive_encounter_check.rb`
- `app/services/game/world/encounter_roster_selector.rb`
- `app/views/arena_matches/show.html.erb`
- `app/assets/stylesheets/arena.css`

Section 16 of `doc/features/arena_combat.md` is exhaustive.

## Evidence and implementation gaps

The final September11 Ogre cycle is
`doc/design/reference/combat/observations/2026-09-11_ogre_combat_cycle.md`.
It completes the 10+10+2 observed fights and supplied the damage-parity
anchors used by the now-active [calibration](../design/features/combat_calibration.md).
Exact source coefficients and uncaptured Arena behavior remain evidence gaps;
they do not reopen the completed calibrated scope. Terminal defeat
now excludes recovered participants as well as zero-HP participants from all
later active exchanges; already committed returns remain separately eligible.

The canonical matrix distinguishes the completed bounded physical runtime from
the remaining `EVIDENCE_NEEDED` formula/selection gaps. Physical `1x1` PvP has
completed its two-seeded-player browser gate. Physical PvE has completed its
seeded Arena `1x1` and City-exit/walk/passive-wait wilderness `1x2` gates. A
disposable six-player `3x3` browser run plus deterministic request/system
coverage closes team synchronization, the captured fight-state UI, and public
log/statistics/pagination states. Exact Neverlands passive timing/probability,
per-cell roster pools/weights, general XP inputs, and player-group reward
distribution remain separate evidence rows; they do not reopen the bounded
physical fight lifecycle. The current source now confirms variable
same-return-context `1x3 -> 1x1 -> 1x1 -> 1x2` output, a later no-coordinate
`1x7 -> 1x3` chain, and approximately `230..278`, `127..187`, and
`4..64`-second passive interval bounds. The mapped local cell now replays its
four exact-coordinate roster samples and two captured windows and can schedule
another sample after victory/Finish, but those samples cannot supply the
source's complete pool, weights, or timing distribution. The current
`150 mastery -> -10 AP` and
`130 mastery -> -8 AP` observations support the authorized local fit
`floor(mastery / 15)`, now implemented and indexed in
[FORMULAS.md](../FORMULAS.md). It remains a calibrated coefficient rather than
a recovered source equation.

## September 12 Arena extension

[Fresh Duel/Group observations](../design/reference/combat/observations/2026-09-12_arena_duels_and_groups.md) feed [Arena design](../design/areas/arena.md), [FORMULAS](../FORMULAS.md) and `doc/features/arena_combat.md`. Physical player applications and persisted group assembly use the existing shared fight pipeline. No new source player fight was possible; local multiplayer acceptance is separate evidence.

Scroll admission uses the same owners: [normalized scroll rules](../design/features/scrolls.md),
[Inventory runtime](../features/player_inventory.md#september-14-attack-scrolls),
[entry formulas](../FORMULAS.md#scroll-01--attack-entry) and
[location context](../WORLD.md). New scroll fights are physical; Permit
intervention preserves the receiving fight's rules and living roster.
