# frozen_string_literal: true
---
title: Dungeons Feature
description: NOT_IMPLEMENTED placeholder for source-backed dungeon entry, topology, encounters, rewards, and resume behavior.
status: NOT_IMPLEMENTED
updated: 2026-08-26
owners: Dungeons domain
template: feature-gap-v2
---

# Dungeons

## 1. Evidence and design

Neverlands is the sole game-design authority.

- Domain: `doc/domains/dungeons.md`
- Source summary: `doc/design/reference/dungeons/README.md`
- Evidence gap: `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`
- Normalized design: `doc/design/features/dungeons.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: no dungeon entry, prerequisite, topology, encounter chain,
party state, reward, exit, failure, or resume lifecycle is shipped.

No dungeon route, authoritative run state, mutation, persistence,
feature-specific Turbo/Stimulus/CSS, or runtime spec is claimed.

## 3. Existing related handoffs

World owns linked locations and Arena Combat owns fights. A linked outdoor
location, City interior, or combat encounter does not constitute a dungeon run,
room graph, party, lockout, or dungeon reward lifecycle.

## 4. Prerequisites for implementation

1. Capture a complete Neverlands entry-to-exit dungeon flow, including failures.
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

| Date | Change |
|---|---|
| 2026-07-29 | Recorded the audited `NOT_IMPLEMENTED` boundary. |
| 2026-08-26 | Migrated the gap record to the lean feature-gap-v2 contract. |
