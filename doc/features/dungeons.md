# frozen_string_literal: true
---
title: Dungeons Feature
description: NOT_IMPLEMENTED placeholder for dungeon lifecycles and the separate future mine underground travel contract.
status: NOT_IMPLEMENTED
updated: 2026-09-09
owners: Dungeons domain
template: feature-gap-v2
---

# Dungeons

## 1. Evidence and design

Neverlands is the sole game-design authority.

- Domain: `doc/domains/dungeons.md`
- Source summary: `doc/design/reference/dungeons/README.md`
- Evidence gap: `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`
- Mine underground gap: `doc/design/reference/dungeons/observations/evidence_needed_mine_underground_travel.md`
- Normalized design: `doc/design/features/dungeons.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: no dungeon entry, prerequisite, topology, encounter chain,
party state, reward, exit, failure, or resume lifecycle is shipped.

No dungeon route, authoritative run state, mutation, persistence,
feature-specific Turbo/Stimulus/CSS, or runtime spec is claimed.

The same runtime absence applies to the distinct mine underground path:
descent, underground cells/topology, movement, return and recovery are not
implemented. The source shows a separate descent action; missing source detail
does not turn that known local absence into a claim that no source evidence
exists.

## 3. Existing related handoffs

World owns linked locations and Arena Combat owns fights. A linked outdoor
location, City interior, or combat encounter does not constitute a dungeon run,
room graph, party, lockout, or dungeon reward lifecycle.

The [mine/exchange live capture](../design/reference/world/observations/2026-09-09_starter_landmarks_and_art.md)
and [wiki reference](../design/reference/world/observations/2026-09-09_mine_exchange_wiki.md)
are linked evidence, not dungeon implementation. World now ships the mine
lobby's exact-cell entry, read-only tabs, Nature return and login restoration.
The lobby's Descend controls remain disabled; its unavailable underground
counters are not locally authored dungeon content.

| Remaining work | Classification and owner |
|---|---|
| Mine descent, underground cells/movement, exit and resume | `[IMPL]` known runtime absence under this domain; `[EVIDENCE]` complete live travel, denial, timing/modifier and recovery contract still needed in the separate mine gap record. |
| Party/floor dungeon lifecycle | `[IMPL]` `NOT_IMPLEMENTED`; `[EVIDENCE]` complete dungeon capture remains in the original dungeon-flow gap record. Never apply these rules to mines without evidence. |
| Digging/extraction, tools, license use, yields and proficiency | [Professions](../domains/professions.md). An underground location alone does not perform a profession action. |
| Mine item/license purchase and resource exchange operations | [Economy](../domains/economy.md). Read-only lobby cards/tabs do not provide acquisition or settlement. |

This split records responsibility, not a new release commitment. The launch
plan keeps underground travel and successful professions outside the completed
starter-lobby scope.

## 4. Prerequisites for implementation

1. Select the intended flow family and capture its complete entry-to-exit
   behavior, including failures; keep mine travel separate from dungeon runs.
2. Normalize prerequisites, topology, encounters, parties, results, and resume.
3. Define stable run/room identities, ownership, persistence, locking, and
   retry-safe rewards.
4. Extend explicit World/Combat/Character/Inventory handoffs and add applicable
   content, transition, authorization, resume, and system coverage.
5. Promote this handbook only after the runtime is verified.

## 5. Responsible documentation and history

- `doc/features/dungeons.md`
- `doc/domains/dungeons.md`
- `doc/design/features/dungeons.md`
- `doc/design/reference/dungeons/README.md`
- `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`
- `doc/design/reference/dungeons/observations/evidence_needed_mine_underground_travel.md`

| Date | Change |
|---|---|
| 2026-07-29 | Recorded the audited `NOT_IMPLEMENTED` boundary. |
| 2026-08-26 | Migrated the gap record to the lean feature-gap-v2 contract. |
