# Dungeons Domain

## Scope

Future source-backed dungeon entry, prerequisites, topology, encounters,
party state, rewards, exit, failure, and login resume. This domain also tracks
the separate future mine descent/underground-cell travel path; a mine does not
inherit dungeon party, floor, oil or reward rules by analogy.

## Documentation chain

- Neverlands source summary: `doc/design/reference/dungeons/README.md`
- Evidence gap:
  `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`
- Mine underground travel gap:
  [separate capture backlog](../design/reference/dungeons/observations/evidence_needed_mine_underground_travel.md)
- Normalized design: `doc/design/features/dungeons.md`
- Delivery ID: `DUNGEON-FLOW-001` in `doc/design/launch_mvp_plan.md`
- Implementation placeholder: `doc/features/dungeons.md`

## Current RPG status

`NOT_IMPLEMENTED`. No route, authoritative dungeon state, topology, mutation,
resume path, or runtime spec is claimed.

The implemented mine lobby belongs to [World](world.md): it has above-ground
entry, read-only sections, Nature return and lobby resume. Its disabled
Descend control is a known `[IMPL]` gap. No underground mine cells, movement,
exit or login recovery are shipped, and the complete source flow remains
`[EVIDENCE]` work.

## Important responsible implementation files

- Runtime implementation: `NOT_IMPLEMENTED`

## Evidence and implementation gaps

A complete dungeon flow is `EVIDENCE_NEEDED`. Do not repurpose City interiors,
linked outdoor locations, or generic RPG assumptions as dungeon design.

The [Dungeons handbook](../features/dungeons.md#3-existing-related-handoffs)
keeps mine underground travel distinct from that dungeon-flow backlog.
[Professions](professions.md) owns successful digging/extraction, tools,
license use and yields; [Economy](economy.md) owns mine item/license purchases
and resource exchange operations. These ownership links do not expand MVP.
