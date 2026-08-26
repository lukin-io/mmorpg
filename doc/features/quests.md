# frozen_string_literal: true
---
title: Quests Feature
description: NOT_IMPLEMENTED placeholder for source-backed Quest dialogue, journal, task, and resolution behavior.
status: NOT_IMPLEMENTED
updated: 2026-08-26
owners: NPCs and Quests domain
template: feature-gap-v2
---

# Quests

## 1. Evidence and design

Neverlands is the sole game-design authority.

- Domain: `doc/domains/npcs_quests.md`
- Source summary: `doc/design/reference/npcs_quests/README.md`
- Evidence gap: `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`
- Normalized design: `doc/design/features/npcs_quests.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: no local Quest entry, dialogue, journal/task state,
turn-in, reward, cancellation, or completion lifecycle is shipped.

No Quest route, authoritative Quest state, mutation, persistence,
feature-specific Turbo/Stimulus/CSS, or runtime spec is claimed.

## 3. Existing related handoffs

World owns NPC placement and Arena Combat owns NPC fights. Their existing NPC
behavior does not create Quest eligibility, progress, dialogue, or rewards.

## 4. Prerequisites for implementation

1. Capture a complete Neverlands Quest flow, including failures and completion.
2. Normalize entry, task gates, progress, cancellation, turn-in, and rewards.
3. Define stable Quest/step identities, ownership, persistence, and retry-safe
   reward transitions.
4. Extend existing NPC/World/Inventory owners where evidence establishes a
   handoff; add applicable request, policy, service/model, and system coverage.
5. Promote this handbook only after the runtime is verified.

## 5. Responsible documentation and history

- `doc/features/quests.md`
- `doc/domains/npcs_quests.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/reference/npcs_quests/README.md`
- `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`

| Date | Change |
|---|---|
| 2026-07-29 | Recorded the audited `NOT_IMPLEMENTED` boundary. |
| 2026-08-26 | Migrated the gap record to the lean feature-gap-v2 contract. |
