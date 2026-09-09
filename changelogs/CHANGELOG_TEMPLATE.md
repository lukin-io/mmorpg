# Change Note: [Short outcome]

> Required for every session that changes repository files, including
> documentation-only work. Consolidate the whole session in one record, not one
> per turn, commit, or subtask. Finalize only after all applicable verification
> passes, including required manual checks; update the same record for later
> verified work in that session. Read-only conversations need no changelog.
> Follow `AGENTS.md` for final documentation/link/diff validation and honest
> reporting of failed or pending checks. Never use this record as a receipt or
> state machine to make verification pass.

- Date: YYYY-MM-DD
- Scope: [whole-session topics and boundaries, including earlier verified work]
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

- `[exact command]` — [passing result, scope, and date/environment when material]
- [Required manual check] — [observed result and evidence link, or why not applicable]
- [Earlier failed check, if any] — [failure, correction, and passing rerun]

[Include all applicable completion checks and final documentation/link/diff
validation. Distinguish earlier verified work from checks run in the current
follow-up; never imply an unrun check passed. A required failed or pending check
prevents finalizing this record and declaring completion.]

## Documentation

- [Canonical design/feature/guide updated, or why none changed.]

## Follow-up

- [Known evidence gap, deferred work, or `None`.]
