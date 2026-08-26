# frozen_string_literal: true
---
title: Professions Feature
description: NOT_IMPLEMENTED placeholder for source-backed gathering and production profession behavior.
status: NOT_IMPLEMENTED
updated: 2026-08-26
owners: Professions domain
template: feature-gap-v2
---

# Professions

## 1. Evidence and design

Neverlands is the sole game-design authority.

- Domain: `doc/domains/professions.md`
- Source summary: `doc/design/reference/professions/README.md`
- Evidence gap: `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`
- Normalized design: `doc/design/features/professions.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: no complete profession eligibility, tool, timer, yield,
counter, failure, interruption, or production loop is shipped.

No profession route, authoritative profession state, mutation, persistence,
feature-specific Turbo/Stimulus/CSS, or runtime spec is claimed.

## 3. Existing related handoffs

World owns current cell/resource actions and Inventory owns carried items and
capacity. Those surfaces do not imply a profession, recipe, tool, yield, XP, or
cooldown system.

## 4. Prerequisites for implementation

1. Capture one complete Neverlands profession flow and its failure/interruption
   states.
2. Normalize exact eligibility, tools, timers, yields, counters, and content.
3. Define server-owned timing, cell/tool validation, capacity, locking, and
   retry-safe completion.
4. Extend World and Inventory pipelines rather than creating duplicates; add
   applicable content, service, request/policy, timing, and system coverage.
5. Promote this handbook only after the runtime is verified.

## 5. Responsible documentation and history

- `doc/features/professions.md`
- `doc/domains/professions.md`
- `doc/design/features/professions.md`
- `doc/design/reference/professions/README.md`
- `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`

| Date | Change |
|---|---|
| 2026-07-29 | Recorded the audited `NOT_IMPLEMENTED` boundary. |
| 2026-08-26 | Migrated the gap record to the lean feature-gap-v2 contract. |
