# frozen_string_literal: true
---
title: [Feature Name] Feature
description: Implementation handbook for [one-sentence shipped feature contract].
status: Fully Implemented
updated: YYYY-MM-DD
owners: [Owning domain or subsystem]
template: feature-v3
---

# [Feature Name]

> Copy this file to `doc/features/<feature_name>.md`, replace every placeholder,
> and remove instruction blockquotes. This handbook describes verified current
> behavior, not a plan. If no runtime exists, use
> `doc/features/NOT_IMPLEMENTED_TEMPLATE.md`.

## 1. Authority and scope

Neverlands is the sole game-design authority. Record the relevant evidence,
normalized design, MVP boundary, and directly related feature handoffs.

- Evidence: `doc/design/reference/[domain]/README.md`
- Design: `doc/design/[area_or_feature].md`
- MVP scope: `doc/design/launch_mvp_plan.md`
- Related runtime: `doc/features/[related_feature].md`

State the exact shipped boundary and anything visible in evidence but outside
this implementation.

## 2. Player contract and non-goals

Describe, in player language:

- entry conditions and primary surface;
- available actions and success feedback;
- exit/resume behavior;
- exact implemented limits, states, timing, or content.

Non-goals:

- [Observed but deferred Neverlands behavior.]
- [Adjacent behavior owned elsewhere.]
- [Generic RPG convention that must not be inferred.]

## 3. Authoritative state and content

| Owner | Responsibility | Important invariant |
|---|---|---|
| `[ModelOrCatalog]` | [Authoritative state/content.] | [Validation, stable identity, or persistence rule.] |
| `[ServiceOrPolicy]` | [Transition or authorization.] | [Transaction, ownership, or retry rule.] |

Explain persisted state, config/seeds, stable identifiers, login/reload resume,
and which browser/catalog values are presentation only.

## 4. Rails and Hotwire flow

Describe the smallest useful end-to-end flow:

1. route/controller loads and authorizes authoritative state;
2. model/service/query validates or performs the transition;
3. transaction/after-commit boundary persists and publishes results;
4. ERB/Turbo renders the result;
5. Stimulus, if present, enhances presentation only.

List real routes and response formats only. Name frame/stream ownership,
reconnect behavior, and accessibility behavior when applicable.

## 5. Security, concurrency, and failure behavior

Document the applicable trust boundaries:

- authentication, Pundit/ownership scope, and untrusted parameters;
- transaction, locking, uniqueness, duplicate/retry handling;
- unchanged state after failure;
- timing/randomness boundaries;
- bounded query, async, cache, or operational risks when present.

## 6. Acceptance and tests

List concise, observable acceptance criteria and exact protecting spec paths.
Cover applicable success, failure, edge/boundary, authorization, and
retry/concurrency behavior.

For high-risk or cross-cutting gameplay only, an acceptance-to-spec table may be
useful:

| Criterion | Protecting specs |
|---|---|
| [Observable high-risk guarantee.] | `spec/[path]_spec.rb` |

Do not add a matrix when a short list is clearer.

## 7. Responsible files and operations

### Runtime

- `app/[responsible_path]`
- `config/[responsible_path]`

### Tests

- `spec/[responsible_spec]_spec.rb`

### Operations

Document migration, rollout, recovery, or content-management steps only when
needed. Otherwise state that no special operation is required.

## 8. Gaps and version history

Known evidence or implementation gaps:

- [Gap, deferred behavior, or `None`.]

| Date | Change |
|---|---|
| YYYY-MM-DD | Created the verified implementation handbook. |
