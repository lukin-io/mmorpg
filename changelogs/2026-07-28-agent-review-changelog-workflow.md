# Pre-Final Rails Review and Changelog Workflow

- Record type: process/documentation session changelog
- Date: 2026-07-28
- Branch: `chore/ui_ux`
- Baseline contract date: 2026-07-21
- Review authority: `doc/RUBY_ON_RAILS_GUIDE.md`

## Outcome

The repository engineering contract now makes two previously informal handoff
practices explicit:

1. a stabilized Rails implementation diff receives a proportional review
   against the applicable technical-guide sections before the final completion
   verification suite; and
2. a substantive change session finishes with one dated record under
   `changelogs/`, created after verification and based on the newest applicable
   record's layout.

The singular `changelog/` directory was renamed to `changelogs/`. The existing
UI/UX, City, and open-world session record moved with its content intact.

## Process contract changes

`AGENT.md` now defines:

- pre-final guide review as a separate gate from the initial orientation read;
- the relationship between iterative focused specs and the final verification
  suite: focused checks may run during implementation, while final completion
  verification must follow the stabilized-diff review;
- a proportional review checklist covering Rails ownership, authorization,
  server authority, ERB/Turbo/Stimulus boundaries, query shape, content/config
  ownership, persistence, concurrency, and coverage where applicable;
- when a changelog is required and when read-only/planning work is exempt;
- the `changelogs/YYYY-MM-DD-short-description.md` naming rule;
- use of the newest applicable changelog as a structural reference rather than
  a mandatory word-count target;
- required changelog content, including exact checks and explicit remaining
  gaps;
- changelog creation as the last material artifact after verification, followed
  by read-only diff/path validation;
- changelog status in the completion checklist and final response contract.

`changelogs/**` is also an allowed default edit scope when the workflow requires
a session record.

## Rails-guide pre-final review

The process diff was reviewed against the applicable guide sections: authority
and purpose, how to use the guide, testing policy, feature documentation and
verification, refactoring workflow, anti-patterns, and the implementation
checklist.

No runtime Rails behavior changed in this task, so controller/model/service,
database-query, authorization, Hotwire, persistence, and feature-handbook
changes were not applicable. The resulting contract remains consistent with
the guide's progressive focused checks and its requirement to use `bin/verify
full` for `AGENT.md` or other process-contract changes.

## Files and documentation

- Modified `AGENT.md` — process metadata, standard workflow, allowed scope,
  pre-final technical-review gate, changelog contract, handoff format, never
  list, and completion checklist.
- Moved
  `changelog/2026-07-28-ui-ux-world-parity-session.md` to
  `changelogs/2026-07-28-ui-ux-world-parity-session.md`.
- Added this record:
  `changelogs/2026-07-28-agent-review-changelog-workflow.md`.
- No gameplay feature handbook changed because this task changed repository
  process rather than shipped player behavior.
- No dependency, schema, seed, configuration, runtime UI, or gameplay change
  was introduced.

## Verification evidence

- Pre-final review: applicable sections of `doc/RUBY_ON_RAILS_GUIDE.md` read and
  the stabilized process diff inspected; no additional correction was needed.
- `bin/verify full`: passed.
  - RuboCop: 375 files, 0 offenses.
  - Non-system RSpec: 1,580 examples, 0 failures.
  - System RSpec: 203 examples, 0 failures, 4 explicit pending examples.
  - Brakeman: 0 errors and 0 security warnings.
  - Bundler Audit: no vulnerabilities.
  - Importmap audit: no vulnerable packages.
  - Feature-document audit: passed for 7 documents, with the existing expected
    transitional warnings for partially implemented Game Shell and Shop
    Economy handbooks.

## Remaining gaps and cautions

- No `[IMPL]`, `[DOC]`, or `[EVIDENCE]` discrepancy was introduced by this
  process-only change.
- The four pending system examples remain explicitly pending for their existing
  documented reasons; this task did not change their behavior.
- Changelog completeness is proportional. Future small changes should keep the
  same useful concerns without copying irrelevant sections from the detailed
  UI/UX session record.
