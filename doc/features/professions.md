# frozen_string_literal: true
---
title: Professions Feature
description: NOT_IMPLEMENTED placeholder for source-backed gathering and production profession behavior.
status: NOT_IMPLEMENTED
updated: 2026-07-29
owners: Professions domain
template: feature-v1
---

# Professions

## 1. Design authority and related documents

Neverlands is the sole game-design authority. Use
`doc/design/reference/professions/README.md`, the explicit evidence gap at
`doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`,
`doc/design/features/professions.md`, and `doc/domains/professions.md`.

### 1.1 Cross-feature relationships

No shipped cross-feature runtime relationship exists because Professions are
`NOT_IMPLEMENTED`. Existing World resource actions, Inventory items, and
progression labels remain owned by their current contracts.

## 2. Feature summary

`NOT_IMPLEMENTED`: no complete local profession eligibility, tool, timer,
yield, counter, failure, or interruption loop is shipped.

## 3. MVP goals and non-goals

### Goals

- Capture one complete Neverlands profession loop.
- Preserve World cell authority, Inventory capacity, and server-controlled
  timing when implementation becomes justified.

### Non-goals

- Resource nodes, skill labels, and generic crafting conventions do not prove
  a profession system.
- No speculative recipes, tools, yields, XP, or cooldowns are permitted.

## 4. Player experience

### 4.1 Entry conditions

`NOT_IMPLEMENTED`.

### 4.2 Primary surface

`NOT_IMPLEMENTED`.

### 4.3 Player actions and feedback

`NOT_IMPLEMENTED`.

### 4.4 Exit and integration behavior

`NOT_IMPLEMENTED`.

## 5. Feature topology and authored content

`NOT_IMPLEMENTED`: no profession definitions, tools, resource bindings,
yields, recipes, or progression tables are authoritative runtime content.

### 5.1 Coordinate, key, or identity terminology

`NOT_IMPLEMENTED`: future cell/resource and profession identities must be
stable and explicit rather than inferred from labels.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Eligibility and tools | None | `NOT_IMPLEMENTED` | None |
| Timed profession action | None | `NOT_IMPLEMENTED` | None |
| Yield and counter update | None | `NOT_IMPLEMENTED` | None |

### 6.2 Deferred behavior boundary

No profession-specific action, timer, yield, recipe, or persisted counter is
exposed.

## 7. Authoritative data and presentation model

`NOT_IMPLEMENTED`: no profession-specific runtime source of truth exists.

### 7.1 Source of truth

Evidence and design documents are inputs for future work only.

### 7.2 Validation and state lifecycle

`NOT_IMPLEMENTED`.

### 7.3 Presentation versus authority

A visible resource, item, or skill name does not authorize a profession action.

## 8. Runtime architecture

`NOT_IMPLEMENTED`: no profession request, validation, timer, persistence, or
response lifecycle exists.

### 8.1 Load and render

`NOT_IMPLEMENTED`.

### 8.2 Accept or execute action

`NOT_IMPLEMENTED`.

### 8.3 Complete, redirect, or hand off

`NOT_IMPLEMENTED`.

### 8.4 Concurrency behavior

Not applicable until a persistent, retry-safe yield transition is designed.

## 9. HTTP and Turbo contract

`NOT_IMPLEMENTED`: no profession route, Turbo endpoint, or public API exists.

## 10. Client-side and CSS ownership

`NOT_IMPLEMENTED`: no profession-specific Stimulus, CSS, or runtime asset
owner exists.

## 11. Persistence and login resume

`NOT_IMPLEMENTED`: no profession timer, counter, or progress is persisted.

## 12. Authorization, trust boundaries, and concurrency

`NOT_IMPLEMENTED`: current cell, tool ownership, eligibility, availability,
expiry, capacity, duplicate completion, and interruption must be server-owned.

## 13. Failure and boundary behavior

| Condition | Required current behavior |
|---|---|
| Player sees an adjacent resource action | It remains the owning World action, not a profession mutation. |
| Evidence is incomplete | Preserve `NOT_IMPLEMENTED`; do not infer yields or timing. |
| Client invents a tool/resource id | No profession endpoint exists to accept it. |

## 14. Acceptance criteria

- One complete source flow is captured and normalized.
- Existing World and Inventory pipelines are extended instead of duplicated.
- Timing, interruption, capacity, reward idempotency, responsive UI, and tests
  are verified before promotion.

## 15. Test strategy and required coverage

`NOT_IMPLEMENTED`: no profession runtime specs are claimed. Future coverage
must include content validation, cell/tool eligibility, timing boundaries,
interruptions, capacity, duplicate completion, requests/policies, persistence,
and responsive system behavior.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/features/professions.md`
- `doc/domains/professions.md`
- `doc/design/features/professions.md`
- `doc/design/reference/professions/README.md`
- `doc/design/reference/professions/observations/evidence_needed_complete_profession_flow.md`

### Runtime implementation

`NOT_IMPLEMENTED`: no profession runtime files exist.

### Specs

`NOT_IMPLEMENTED`: no profession runtime specs exist.

## 17. Safe extension checklist

1. Capture the complete source action and its failure/interruption states.
2. Normalize exact tools, timers, yields, counters, and prerequisites.
3. Extend the existing World cell/action and Inventory pipelines.
4. Add server-owned timing, locks, and idempotent completion.
5. Add responsive presentation using project-owned CSS/text primitives.
6. Promote only after all applicable checks pass.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-29 | Created the audited `NOT_IMPLEMENTED` implementation placeholder. |
