# frozen_string_literal: true
---
title: Professions Feature
description: NOT_IMPLEMENTED placeholder for source-backed gathering and production profession behavior.
status: NOT_IMPLEMENTED
updated: 2026-09-15
owners: Professions domain
template: feature-gap-v2
---

# Professions

## 1. Evidence and design

For future implementation, read [ITEMS](../ITEMS.md) for existing tools/licenses,
[WORLD](../WORLD.md#4-npc-habitats-and-resources) for cell-action boundaries and
[FORMULAS](../FORMULAS.md#11-compatibility-and-absent-formulas) for active versus
absent calculations. These are adjacent context, not a profession runtime.
Connect new verified behavior and update its references under the
[context/update map](../DOCUMENTATION.md#21-required-context-and-update-map).

Neverlands is the sole game-design authority.

- Domain: `doc/domains/professions.md`
- Source summary: `doc/design/reference/professions/README.md`
- Evidence gap: `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`
- Normalized design: `doc/design/features/professions.md`
- MVP boundary: `doc/design/launch_mvp_plan.md`

## 2. Missing runtime contract

`NOT_IMPLEMENTED`: no complete profession eligibility, tool, timer, yield,
counter, failure, interruption, or production loop is shipped.

No gathering/production route, state, mutation or runtime spec is claimed here.
The bounded Doctor injury-treatment workflow is documented under
[Medical Care](medical_care.md), separate from crafting and profession
progression. Medical Care enforces effective Doctor bag thresholds; automatic
Doctor growth, quests and crafting remain absent. Its handbook owns the
qualification checks and current acceptance.

The remaining categories belong to this domain, even though World links them
from its map/cell gap matrix:

| Missing category | Confirmed contract and unresolved scope |
|---|---|
| Successful fishing and counter growth | No initial skill/perk gate; growth on successful fishing is user-confirmed. Casting, catches, exact gain, probabilities, timing/modifiers and failure/interruption remain unimplemented. |
| Plant gathering / herbalism | Successful discovery/harvest, exact requirements, yields and counter changes are missing. Naturalist/Herbalist and Observation inputs are separate from Alchemy. |
| Alchemy production | Recipe/ingredient/tool requirements, consumption, timing, outputs and progression need a complete separate flow. |
| Digging / extraction | Skill dependence is confirmed; exact skill/license/tool, timer, outcomes, interruption and repeatability remain unresolved. Mine lobby and read-only shop sections do not implement extraction. |
| Equipment, bait and inventory settlement | Rod/bait requirements are confirmed direction; complete item identities, equip checks, bait use/expiry, durability, material grants, capacity failures and retry-safe settlement are missing. |

## 3. Existing related handoffs

World owns immediate empty Look with a persisted 28-second lock, immediate
normal Drink recovery of two fatigue points with a 60-second lock, and the
no-bait Fish result with a 30-second lock. No fish/herb award or profession
growth is performed by those actions. Digging's identifier can be authored but
does not produce an implemented action offer. Fishing and drinking have no
initial skill/perk gate; a nonzero displayed proficiency is not an entry rule.

Inventory owns carried/equipped items and capacity. Character Progression is
the adjacent owner for future profession-counter persistence. World owns
cell eligibility, offers, action locking and hostile interruption. The mine's
outdoor entrance/read-only lobby belongs to World; descent/underground travel
belongs to Dungeons. Professions owns mining-license use/effects; Economy owns
purchase/payment of mine items/licenses and exchange queries, listings,
transactions and storage. Those surfaces do not constitute successful
extraction or production.

Successful profession work remains deferred from the starter-map task. The
earlier user shorthand grouped gathering with alchemy; the source-backed
design now distinguishes plant discovery/harvest from potion production.
The owning categories above and their capture checklist are canonical here;
the World matrix is a cross-domain summary.

## 4. Prerequisites for implementation

1. Follow the linked activity-specific capture checklist for one complete
   Neverlands profession flow, including failure/interruption and inventory.
2. Normalize exact eligibility, tools/bait, timers, yields and counter changes
   without reopening the settled no-gate fishing/drinking decision.
3. Define server-owned timing and current-cell/equipment validation, plus the
   atomic locking boundary for proven consumption, durability, rewards and
   counter growth. Cover capacity failure, duplicate completion and restoration.
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
