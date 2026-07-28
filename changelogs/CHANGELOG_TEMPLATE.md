# [Session Title]

> Template instruction: for a genuinely new substantive Codex session, copy
> this file to `changelogs/YYYY-MM-DD-short-kebab-case-description.md` with the
> first material repository edit. Replace every bracketed placeholder and
> remove all template-instruction blockquotes. Keep updating that one copied
> file across every prompt in the session; never edit this template as the
> session record and never create prompt-level changelog fragments.

- Record type: [implementation, bug-fix, documentation, process, or mixed session changelog]
- Date: YYYY-MM-DD
- Branch: `[branch]`
- Baseline: `[commit, branch, or useful starting state]`
- Session status: In Progress
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`
- Changelog lifecycle: one living record for this complete Codex session

## Outcome

[Lead with the result and current task boundary. While work is incomplete,
state what is in progress and do not claim planned behavior or running checks
as complete. At final handoff, summarize the verified outcome and distinguish
Done from Not Done.]

> Template instruction: update this section whenever later prompts materially
> expand or correct the session. Do not append a second “outcome” for each
> prompt.

## Authority and reference boundary

[Identify the Neverlands/design/reference evidence that governed player-facing
or gameplay work. State what may be reproduced and what must not be copied. For
non-gameplay work, explain the relevant process or technical authority.]

- [Important authority or evidence boundary.]
- [Important product/reference-copy trade-off.]
- [Explicit uncertainty or Not Done boundary, if applicable.]

> Template instruction: do not invent Neverlands behavior. Never include
> credentials, cookies, tokens, private live-session data, or copied identity
> assets/text in this record.

## Architecture and maintainability

[Record the important ownership, SRP/domain boundary, reuse, dependency, and
trade-off decisions. Explain why the implementation extends an existing
pipeline instead of creating a duplicate one.]

- [Decision and responsible boundary.]
- [Decision and maintainability impact.]
- New dependencies: [none, or exact dependency and reason].

## Player/runtime behavior

### [Feature or work area]

- [Verified player-visible or runtime change.]
- [Authoritative state and important success/failure behavior.]
- [Responsive/accessibility/integration behavior, where applicable.]
- [Explicit deferred state or Not Done behavior.]

### [Additional feature or work area]

- [Add coherent subsections as the same session expands across later prompts.]

> Template instruction: omit this section only when the session has no runtime
> or player-facing effect, and then replace it with one explicit sentence that
> runtime behavior did not change.

## UI, CSS, and UX

- [Layout, dimensions, density, hierarchy, and interaction changes.]
- [Hover, focus, keyboard, touch, mobile, tablet, and desktop behavior.]
- [CSS module/asset ownership and reuse.]
- [Reference images/text intentionally excluded or replaced with CSS/plain
  text, where applicable.]

> Template instruction: preserve the reference-design versus local-asset
> boundary and identify the owning domain stylesheet. Do not describe planned
> visual parity as complete.

## Data, content, cells, seeds, and persistence

| Concern | Declaration/configuration | Persisted state | Runtime owner |
|---|---|---|---|
| [Content or state] | `[seed/config/catalog]` | `[model/table or none]` | `[resolver/service]` |

- [Migration, seed idempotency, reconciliation, resume, or cleanup behavior.]
- [How to add, move, disable, or remove relevant persisted content.]
- [Concurrency, stale-state, or operational caution.]

> Template instruction: if no persisted content changed, retain the section
> with a concise “Not applicable” explanation. Never imply that deleting a
> seed/config declaration automatically removes an already-persisted row.

## Under-the-hood Rails and Hotwire work

- [Controller/model/service/query/policy ownership change.]
- [Turbo frame/stream, Stimulus, Action Cable, or server-rendering boundary.]
- [Authorization, transaction, query/preload, lifecycle, or DOM-safety change.]
- [Explicitly rejected duplicate abstraction or client-authority path.]

> Template instruction: include only changes actually made. Do not copy generic
> guide advice into an unrelated record.

## Pre-final Rails-guide review

The stabilized session diff was reviewed against the applicable sections of
`doc/RUBY_ON_RAILS_GUIDE.md`:

- [Sections/concerns reviewed and why they apply.]
- [Concrete finding and resulting correction.]
- [Focused coverage rerun after the correction.]

[If no correction was needed, state that explicitly. If verification has not
yet run, label it pending rather than passed.]

## Documentation updated

- `[path]` — [what was added or corrected].
- Feature handbook: [created/updated path, or why none applies].
- Design/reference evidence: [created/updated path, or not applicable].

## Implementation and responsible paths

| Responsibility | Paths |
|---|---|
| [Runtime/CSS/docs/specs/config] | `[exact/path]`, `[exact/path]` |

> Template instruction: group coherent responsible files. Keep paths current as
> later prompts extend the same session; do not create a parallel ownership map
> when a canonical feature handbook already owns the detailed inventory.

## Verification evidence

- `[focused command]`: [exit code and exact examples/offenses/result].
- `git diff --check`: [passed/pending with exit code].
- `bin/feature-doc-audit [path]`: [exact result, or not applicable].
- `bin/verify [fast|full]`: [passed/pending/blocked with exit code].
  - RuboCop: [file count and offenses].
  - Non-system RSpec: [examples and failures].
  - System RSpec: [examples, failures, and pending], or [not run and why].
  - Security/dependency audits: [exact result], when using `full`.
  - Feature-document audit: [document count, warnings, and result].

> Template instruction: add results as checks run, but never write “passed” in
> advance. After the completion profile, replace stale/pending entries with the
> final exact outcomes. If implementation changes afterward, rerun applicable
> verification and update this same section.

## Explicit remaining gaps and operational cautions

- `[IMPL]` [Known implementation gap or “none introduced by this session.”]
- `[DOC]` [Known documentation gap or “none.”]
- `[EVIDENCE]` [Missing/ambiguous Neverlands evidence or “none.”]
- Not Done: [deferred states from the authoritative MVP matrix, if applicable].
- Migration/operations: [required action or “none.”]
- Pending/skipped checks: [exact checks and reasons, or “none.”]

> Template instruction: at final handoff change `Session status` to `Complete`
> only when the requested outcome is genuinely complete. Preserve explicit
> gaps and pending checks; do not hide them to make the session appear green.
