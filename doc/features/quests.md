# frozen_string_literal: true
---
title: Quests Feature
description: NOT_IMPLEMENTED placeholder for source-backed Quest dialogue, journal, task, and resolution behavior.
status: NOT_IMPLEMENTED
updated: 2026-09-12
owners: NPCs and Quests domain
template: feature-gap-v2
---

# Quests

## 1. Evidence and design

For future implementation, read [NPC](../NPC.md) for existing NPC identities,
[ITEMS](../ITEMS.md) for possible authored item references and
[WORLD](../WORLD.md) for locations. Current catalog entries do not establish
Quest dialogue, tasks or rewards. Connect new verified behavior and update its
references under the [context/update map](../DOCUMENTATION.md#21-required-context-and-update-map).

Neverlands is the sole game-design authority.

- Domain: `doc/domains/npcs_quests.md`
- Source summary: `doc/design/reference/npcs_quests/README.md`
- Evidence gap: `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`
- Normalized design: `doc/design/features/npcs_quests.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: the general NPC Quest dialogue, journal/task, reward and
cancellation lifecycle is absent. The Shop-owned Merchant qualification below
is a bounded prerequisite and does not complete this broader contract.

No general Quest engine, NPC dialogue route or journal runtime is claimed here.

## 3. Existing related handoffs

World owns NPC placement and Arena Combat owns NPC fights. Their existing NPC
behavior does not create Quest eligibility, progress, dialogue, or rewards.

[Shop and Economy](shop_economy.md) owns the published Merchant license prerequisite:
Market acceptance, a 1,000-NV Shop receipt and Market completion. That bounded
persisted flow unlocks trading-license purchases; its temporary garment reward
and original quest presentation remain incomplete. The September 9 economy
observation owns its official-wiki evidence. This handoff does not supply a
general NPC quest system or other profession quests.

### Traumatologist quest TODO

**TODO (September 16 user scope):** implement Traumatologist as a complete
Neverlands-backed quest when its eligibility, dialogue/tasks, progress,
completion and qualification reward have been captured. It is deferred from
the current primary-list medical work. Do not auto-grant qualification or
remove Doctor-license prerequisites to substitute for the missing quest.
[MEDICAL](../MEDICAL.md#permissions-are-separate-from-proficiency) describes the current
qualification handoff; the [MVP scope](../design/launch_mvp_plan.md#september-16-primary-list-scope)
records this explicit deferral.

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
