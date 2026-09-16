# Neverlands Dungeons Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Dungeons domain](../../../domains/dungeons.md).

- Document type: neverlands-source-summary
- Domain: dungeons
- Updated: 2026-09-09
- Evidence status: EVIDENCE_NEEDED for complete dungeon and mine underground flows

## Evidence gap

- `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`
- [Separate mine underground travel gap](observations/evidence_needed_mine_underground_travel.md)

No complete Neverlands dungeon entry, topology, encounter, reward, exit, or
resume flow is currently documented.

## Adjacent mine evidence and boundary

The [World live capture](../world/observations/2026-09-09_starter_landmarks_and_art.md)
confirms an above-ground mine lobby with a separate Descend control; descent
was not exercised. The [wiki reference](../world/observations/2026-09-09_mine_exchange_wiki.md)
preserves stated travel inputs and the distinction between descent and licensed
extraction. These known observations narrow the mine backlog but do not prove
its full underground cell, movement, return, presence or recovery contract.

Mine underground travel is tracked in this domain separately from dungeon
party/floor runs. World owns the shipped lobby handoff; Professions owns
digging/extraction and license use; Economy owns mine acquisition and resource
exchange operations. Do not import dungeon mechanics into a mine by analogy.

## Design linkage

- `doc/design/features/dungeons.md`

## Local Implementation Linkage

- Local status: `NOT_IMPLEMENTED`
- Implementation placeholder: `doc/features/dungeons.md`
- The World mine lobby remains a related implemented location, not dungeon
  runtime. Mine descent, underground cells/movement, exit and resume are also
  unimplemented.

### Responsible implementation files

- `NOT_IMPLEMENTED`

Local implementation linkage is context, not Neverlands evidence.
