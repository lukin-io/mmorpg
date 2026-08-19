# frozen_string_literal: true
---
title: Quests Feature
description: NOT_IMPLEMENTED placeholder for source-backed Quest dialogue, journal, task, and resolution behavior.
status: NOT_IMPLEMENTED
updated: 2026-07-29
owners: NPCs and Quests domain
template: feature-v1
---

# Quests

## 1. Design authority and related documents

Neverlands is the sole game-design authority. The evidence registry is
`doc/design/reference/npcs_quests/README.md`; the explicit capture gap is
`doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`;
normalized design is `doc/design/features/npcs_quests.md`; and domain
navigation is `doc/domains/npcs_quests.md`.

### 1.1 Cross-feature relationships

No shipped cross-feature runtime relationship exists because Quests are
`NOT_IMPLEMENTED`. Existing NPC combat remains owned by the World and Arena
Combat contracts and is not a Quest implementation.

## 2. Feature summary

`NOT_IMPLEMENTED`: no local Quest entry, dialogue, journal/task state,
turn-in, reward, cancellation, or completion lifecycle is shipped.

## 3. MVP goals and non-goals

### Goals

- Capture a complete Neverlands Quest flow before defining local behavior.
- Implement server-authoritative task state, transitions, and rewards only
  after evidence and design are sufficient.

### Non-goals

- Generic dialogue trees, exclamation markers, journals, rewards, or daily
  Quest conventions are not evidence.
- Existing NPC placement or combat does not imply Quest functionality.

## 4. Player experience

### 4.1 Entry conditions

`NOT_IMPLEMENTED`.

### 4.2 Primary surface

`NOT_IMPLEMENTED`. The observed Quest-shaped modal is evidence only.

### 4.3 Player actions and feedback

`NOT_IMPLEMENTED`.

### 4.4 Exit and integration behavior

`NOT_IMPLEMENTED`.

## 5. Feature topology and authored content

`NOT_IMPLEMENTED`: no Quest definitions, steps, gates, NPC bindings, rewards,
or journal entries are stored locally.

### 5.1 Coordinate, key, or identity terminology

`NOT_IMPLEMENTED`: future stable identifiers must not depend on mutable names.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Quest entry and dialogue | None | `NOT_IMPLEMENTED` | None |
| Journal and task progress | None | `NOT_IMPLEMENTED` | None |
| Turn-in and reward | None | `NOT_IMPLEMENTED` | None |

### 6.2 Deferred behavior boundary

No interactive Quest control, mutation, reward, or persisted progress exists.

## 7. Authoritative data and presentation model

`NOT_IMPLEMENTED`: no Quest-specific authoritative runtime owner exists.

### 7.1 Source of truth

Evidence and design documents are planning inputs, not runtime state.

### 7.2 Validation and state lifecycle

`NOT_IMPLEMENTED`.

### 7.3 Presentation versus authority

Captured modal geometry or copy cannot create local task state or availability.

## 8. Runtime architecture

`NOT_IMPLEMENTED`: there is no Quest request, validation, persistence, or
response lifecycle.

### 8.1 Load and render

`NOT_IMPLEMENTED`.

### 8.2 Accept or execute action

`NOT_IMPLEMENTED`.

### 8.3 Complete, redirect, or hand off

`NOT_IMPLEMENTED`.

### 8.4 Concurrency behavior

Not applicable until a persistent Quest transition is designed.

## 9. HTTP and Turbo contract

`NOT_IMPLEMENTED`: no Quest route, Turbo endpoint, or public API exists.

## 10. Client-side and CSS ownership

`NOT_IMPLEMENTED`: no Quest-specific Stimulus, CSS, copied source image, or
runtime asset owner exists.

## 11. Persistence and login resume

`NOT_IMPLEMENTED`: no Quest progress is persisted or restored.

## 12. Authorization, trust boundaries, and concurrency

`NOT_IMPLEMENTED`: ownership, eligibility, step validation, reward
idempotency, and concurrency boundaries must be designed before adding routes.

## 13. Failure and boundary behavior

| Condition | Required current behavior |
|---|---|
| Player looks for a Quest action | No Quest route or actionable control is exposed. |
| Evidence is incomplete | Preserve `NOT_IMPLEMENTED`; do not infer behavior. |
| Existing NPC is present | NPC presence does not mint Quest capability. |

## 14. Acceptance criteria

- A full source flow is observed and normalized.
- Server authority, persistence, authorization, failures, responsive UI, and
  tests are implemented and verified before promotion.
- No source-specific brand copy or images are bundled.

## 15. Test strategy and required coverage

`NOT_IMPLEMENTED`: no Quest runtime specs are claimed. Future implementation
must cover models/content, transition services, requests/policies, retry-safe
rewards, login resume, and responsive system behavior.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/features/quests.md`
- `doc/domains/npcs_quests.md`
- `doc/design/features/npcs_quests.md`
- `doc/design/reference/npcs_quests/README.md`
- `doc/design/reference/npcs_quests/observations/evidence_needed_complete_quest_flow.md`

### Runtime implementation

`NOT_IMPLEMENTED`: no Quest runtime files exist.

### Specs

`NOT_IMPLEMENTED`: no Quest runtime specs exist.

## 17. Safe extension checklist

1. Replace the evidence gap with a complete source observation.
2. Normalize exact entry, task, gate, progress, result, and failure behavior.
3. Identify whether existing NPC/World owners can support the boundary.
4. Implement server-issued capabilities and retry-safe rewards.
5. Add responsive UI without copying source images or identity text.
6. Promote this handbook only after focused and completion checks pass.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-29 | Created the audited `NOT_IMPLEMENTED` implementation placeholder. |
