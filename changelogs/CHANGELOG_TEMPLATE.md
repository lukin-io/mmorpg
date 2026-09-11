# Change Note: [Short outcome]

> Use this optional template for a release/rollout, a user-requested change
> record, or a durable architectural decision that would otherwise be hard to
> discover. Ordinary implementation work does not require a changelog, and this
> file is never workflow state or a verification gate.

- Date: YYYY-MM-DD
- Scope: [feature, release, migration, or architecture boundary]
- Related issue/PR: [link or `Not applicable`]

## Summary

[Describe the player/engineer-visible outcome in a short paragraph. State
whether gameplay behavior changed.]

## Why

[Record the problem, Neverlands evidence or engineering constraint, and the
reason this change was chosen.]

## Changes

- [Important behavior or ownership change.]
- [Important persistence/UI/operational change.]
- [Intentional deletion or simplification.]

## Contracts and boundaries

- Game-design authority: [relevant Neverlands evidence/design, or `No gameplay
  design change`].
- Authoritative state: [database/config owner and transaction boundary, or
  `Not applicable`].
- Security/concurrency: [important rule or `Not applicable`].
- Compatibility/non-goals: [what deliberately remains unchanged or deferred].

## Rollout and recovery

[Include migration, deployment ordering, feature flags, backfill, rollback, or
operator recovery only when the change genuinely needs it. Otherwise write
`No special rollout or recovery procedure.`]

## Verification

- `[exact command]` — [passed/failed and concise result]
- `[exact command]` — [passed/failed and concise result]

## Documentation

- [Canonical design/feature/guide updated, or why none changed.]

## Follow-up

- [Known evidence gap, deferred work, or `None`.]
