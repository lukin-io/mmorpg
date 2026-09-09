# Change Note: [Short outcome]

> One consolidated changelog is mandatory for every session that changes
> repository files, finalized after all applicable verification passes.
> Update that same record for later verified work. Detailed workflow and final
> validation belong to [AGENTS.md](../AGENTS.md#mandatory-consolidated-session-changelog).

- Session started: [YYYY-MM-DD; if unknown, identify the earliest recorded work]
- Last updated: YYYY-MM-DD
- Scope: [whole-session topics and boundaries, including earlier verified work]
- Related issues/PRs/commits: [links covering the session, including multiple
  deliveries when applicable, or `Not applicable`]

## Summary

[Describe the player/engineer-visible outcome in a short paragraph. State
whether gameplay behavior changed.]

## Why

[Record the problem, Neverlands evidence or engineering constraint, and the
reason this change was chosen.]

## Changes

[Group changes by feature or outcome. Use subsections only when they help;
include a concrete before/after example when it clarifies the change.]

- [Outcome and material behavior, ownership, persistence or UI change.]
- [Intentional deletion or simplification and its reason.]

## Contracts and boundaries

- Game-design authority: [relevant Neverlands evidence/design, or `No gameplay
  design change`].
- Authoritative state: [database/config owner and transaction boundary, or
  `Not applicable`].
- Security/concurrency: [important rule or `Not applicable`].
- Compatibility/non-goals: [what deliberately remains unchanged or deferred].

## Rollout and recovery

[Include migration, deployment ordering, feature flags, backfill, rollback, or
operator recovery only when the change genuinely needs it. For seed/content
changes, distinguish initial bootstrap from reseeding an existing database:
state the command/order, records reconciled or overwritten, managed content and
player state preserved, and any required recovery procedure. Link the canonical
operator guide rather than copying it. Otherwise write
`No special rollout or recovery procedure.`]

## Verification

[Separate the sources below. Record the date/environment and tested commit or
working-tree checkpoint when needed to distinguish deliveries. Do not substitute
a later commit for an unknown tested revision. Mark an inapplicable source or an
unobserved CI result explicitly.]

- Local automated checks: `[exact command]` — [result and scope, including final
  documentation/link/diff validation].
- CI: [run/check link, revision and observed result; local success is not CI
  success].
- Manual local verification: [scenario, observed result and evidence link, or why
  not applicable]. Neverlands captures establish source behavior; they do not
  prove the local implementation works.

[Summarize material failures, corrections and passing reruns rather than every
attempt. Link detailed verification history where useful; clearly distinguish
earlier verified work from checks run for this follow-up.]

## Documentation

- [Canonical design/feature/guide updated, or why none changed.]

## Follow-up

[For each remaining item, provide its classification, canonical owner link and
agreed delivery stage, or `Not scheduled` when no stage was agreed. Distinguish
missing implementation from unknown source behavior; split mixed gaps when
needed. This section links the backlog, it does not create a delivery commitment.]

- `[IMPL]`, `[DOC]` or `[EVIDENCE]` — [specific gap]; owner: [canonical document
  link]; delivery: [agreed stage or `Not scheduled`].

[Write `None` when no follow-up remains.]
