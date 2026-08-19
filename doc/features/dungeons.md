# frozen_string_literal: true
---
title: Dungeons Feature
description: NOT_IMPLEMENTED placeholder for source-backed dungeon entry, topology, encounters, rewards, and resume behavior.
status: NOT_IMPLEMENTED
updated: 2026-07-29
owners: Dungeons domain
template: feature-v1
---

# Dungeons

## 1. Design authority and related documents

Neverlands is the sole game-design authority. Use
`doc/design/reference/dungeons/README.md`, the explicit evidence gap at
`doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`,
`doc/design/features/dungeons.md`, and `doc/domains/dungeons.md`.

### 1.1 Cross-feature relationships

No shipped cross-feature runtime relationship exists because Dungeons are
`NOT_IMPLEMENTED`. Existing World linked locations and Arena Combat do not
constitute a dungeon system.

## 2. Feature summary

`NOT_IMPLEMENTED`: no dungeon entry, prerequisite, topology, encounter chain,
party state, reward, exit, failure, or resume lifecycle is shipped.

## 3. MVP goals and non-goals

### Goals

- Capture a complete Neverlands dungeon flow before defining local behavior.
- Reuse verified World, Combat, Character, and Inventory handoffs only where
  source evidence establishes them.

### Non-goals

- Generic instances, rooms, bosses, keys, loot, parties, or lockouts are not
  Neverlands evidence.
- A linked outdoor location or City interior is not a dungeon by implication.

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

`NOT_IMPLEMENTED`: no dungeon definitions, rooms, connections, gates,
encounters, or reward tables exist.

### 5.1 Coordinate, key, or identity terminology

`NOT_IMPLEMENTED`: future entrance, dungeon, room, encounter, and run
identifiers must be explicit and stable.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Entry and prerequisites | None | `NOT_IMPLEMENTED` | None |
| Topology and encounters | None | `NOT_IMPLEMENTED` | None |
| Result, reward, and exit | None | `NOT_IMPLEMENTED` | None |

### 6.2 Deferred behavior boundary

No dungeon route, action, mutation, run state, or reward exists.

## 7. Authoritative data and presentation model

`NOT_IMPLEMENTED`: no dungeon-specific authoritative runtime owner exists.

### 7.1 Source of truth

Evidence and design documents are planning inputs only.

### 7.2 Validation and state lifecycle

`NOT_IMPLEMENTED`.

### 7.3 Presentation versus authority

A map, mockup, or linked-location scene cannot mint dungeon availability.

## 8. Runtime architecture

`NOT_IMPLEMENTED`: no dungeon request, validation, persistence, encounter, or
response lifecycle exists.

### 8.1 Load and render

`NOT_IMPLEMENTED`.

### 8.2 Accept or execute action

`NOT_IMPLEMENTED`.

### 8.3 Complete, redirect, or hand off

`NOT_IMPLEMENTED`.

### 8.4 Concurrency behavior

Not applicable until authoritative run and reward transitions are designed.

## 9. HTTP and Turbo contract

`NOT_IMPLEMENTED`: no dungeon route, Turbo endpoint, or public API exists.

## 10. Client-side and CSS ownership

`NOT_IMPLEMENTED`: no dungeon-specific Stimulus, CSS, or runtime asset owner
exists.

## 11. Persistence and login resume

`NOT_IMPLEMENTED`: no active run, room, encounter, or return context persists.

## 12. Authorization, trust boundaries, and concurrency

`NOT_IMPLEMENTED`: prerequisites, party membership, run ownership, encounter
state, reward idempotency, and safe resume must be designed before routes.

## 13. Failure and boundary behavior

| Condition | Required current behavior |
|---|---|
| Player looks for a dungeon route | No route or actionable control is exposed. |
| Evidence is incomplete | Preserve `NOT_IMPLEMENTED`; do not infer behavior. |
| Existing location resembles a dungeon | It remains owned by its current location contract. |

## 14. Acceptance criteria

- A complete source entry-to-exit flow is observed and normalized.
- Topology, encounters, persistence, authorization, failures, rewards,
  responsive UI, and tests are implemented and verified before promotion.
- Existing pipelines are extended at explicit handoffs rather than duplicated.

## 15. Test strategy and required coverage

`NOT_IMPLEMENTED`: no dungeon runtime specs are claimed. Future coverage must
include authored content, entry gates, topology boundaries, encounter handoffs,
party/ownership denial, retry-safe rewards, resume, exits, and responsive UI.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/features/dungeons.md`
- `doc/domains/dungeons.md`
- `doc/design/features/dungeons.md`
- `doc/design/reference/dungeons/README.md`
- `doc/design/reference/dungeons/observations/evidence_needed_dungeon_flow.md`

### Runtime implementation

`NOT_IMPLEMENTED`: no dungeon runtime files exist.

### Specs

`NOT_IMPLEMENTED`: no dungeon runtime specs exist.

## 17. Safe extension checklist

1. Capture complete source entry, topology, encounter, result, and exit states.
2. Normalize prerequisites, stable identities, persistence, and failures.
3. Define explicit handoffs to existing World, Combat, Character, and Inventory owners.
4. Add server-issued capabilities, locking, and retry-safe rewards.
5. Add responsive presentation using project-owned CSS/text primitives.
6. Promote only after all applicable checks pass.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-29 | Created the audited `NOT_IMPLEMENTED` implementation placeholder. |
