# Mine Underground Travel — Evidence Gaps

- Document type: neverlands-observation
- Domain: dungeons
- Captured at: underground flow not captured; lobby captured 2026-09-09
- Source type: authenticated-live required
- Evidence status: EVIDENCE_NEEDED for the complete underground flow
- Supersedes: none

## Scope and existing evidence

This record tracks the mine's separate descent, underground grid movement,
return and recovery contract. It is distinct from party/floor dungeon runs;
their lamp oil, keys, seals and party rules must not be applied to a mine by
analogy.

- [Live mine lobby](../../world/observations/2026-09-09_starter_landmarks_and_art.md)
  shows a separate Descend control and an entrance overview with live counters.
  Descent was not submitted. The captured above-ground entry and Nature return
  do not demonstrate an underground transition.
- [Official-wiki reference](../../world/observations/2026-09-09_mine_exchange_wiki.md)
  preserves stated descent/movement timing, torch wear and the distinction
  between entering without a license and extracting resources. These are
  documented inputs, not proof of a complete live or local underground loop.

## Required capture states

| Transition or state | Evidence still needed |
|---|---|
| Descend | Submit the separate action; record eligibility, equipment/resource requirements, timer/lock, failure/interruption, destination and resulting location label. Keep descent eligibility separate from extraction permission. |
| Underground cells and movement | Observe the actual grid/topology, coordinate/floor identity, allowed neighbors, blockers, loading/rendering, timers, equipment wear and relevant modifiers. Do not treat sampled lobby counters as local map dimensions or available content. |
| Return and failure | Observe the underground exit/ascend path, landing lobby/cell, blocking/combat/death behavior where encountered, and state retained after failure. Nature in the lobby only proves the lobby-to-outdoor return. |
| Reload/login and local audience | Verify persisted progress/location during descent and underground movement, login recovery, and actual room/cell chat/presence boundaries. The wiki's outdoor-cell treatment for transfers does not establish chat AOI. |

## Local boundary and responsible owners

Underground descent, cell topology, movement, exit and recovery are
`NOT_IMPLEMENTED`; no dungeon/mine-underground route, state record, renderer or
runtime spec is claimed. [Dungeons](../../../../features/dungeons.md) owns this
travel backlog while remaining `NOT_IMPLEMENTED` overall.

[World](../../../../features/world.md) already owns the above-ground mine
lobby, read-only sections, exact-cell Nature return and lobby resume.
[Professions](../../../../domains/professions.md) owns successful digging and
extraction, tools/license use, yields and proficiency. [Economy](../../../../domains/economy.md)
owns mine item/license acquisition and resource exchange operations.

Ownership here does not approve a new delivery stage. Keep the current
[MVP boundary](../../../../design/launch_mvp_plan.md): the completed starter
scope includes lobbies; underground travel and successful professions remain
later work.
