# Linux World Viewport CI Fix

- Record type: UI/CSS bug-fix session changelog
- Date: 2026-07-28
- Branch: `chore/ui_ux`
- Primary file: `app/assets/stylesheets/world.css`
- Runtime behavior changed: responsive map geometry only

## Outcome

The outdoor World viewport now preserves its established 13-by-7 desktop
contract across scrollbar implementations. At the CI viewport, the visible map
is again 1,302 by 702 pixels over the existing 15-by-9 movement buffer, without
weakening the system assertion or changing map, movement, cell, or action
authority.

The failure was platform-specific. Linux Chrome reserves 15 pixels for the
outer page's classic vertical scrollbar, while the development browser uses an
overlay scrollbar. The previous `calc(100% - 24px)` fallback therefore reduced
the map viewport from 1,302 to 1,287 pixels only in CI.

## UI/CSS change

- Changed the desktop `.nl-map-viewport` fallback from `calc(100% - 24px)` to
  `100%`.
- Kept the preferred width derived from the existing 13 visible 100-pixel
  columns plus the two-pixel border.
- Kept the `@media (max-width: 940px)` rule unchanged, including its 12-pixel
  narrow-screen inset and 1,302-pixel maximum.
- Kept height, table buffer, cursor position, scrolling, and centering behavior
  unchanged.
- No Neverlands images, text, gameplay rules, JavaScript, dependencies, or
  persisted data were added or changed.

## Architecture and maintainability

The fix remains in the World domain stylesheet that owns map presentation. It
does not introduce a browser-specific rule or duplicate responsive pipeline.
CSS still controls presentation only; server-rendered movement offers and
persisted position remain authoritative.

The exact system-spec expectation remains the portability contract. The page
scrollbar may consume surrounding layout space, but it no longer consumes one
of the 13 intended map columns.

## Pre-final Rails-guide review

The stabilized diff was reviewed against the applicable
`doc/RUBY_ON_RAILS_GUIDE.md` sections 2, 9.10-9.12, 21-22, 23.5, 24, and 25.
The review confirmed:

- the change stays within CSS presentation ownership;
- no gameplay authority or Hotwire/Stimulus lifecycle changed;
- the existing narrow-screen behavior remains intact;
- focused system coverage is the correct public boundary; and
- no test relaxation, alternate frontend pipeline, or platform-specific
  workaround is needed.

No additional implementation finding resulted from the review.

## Files and documentation

- Modified `app/assets/stylesheets/world.css`.
- Added this record:
  `changelogs/2026-07-28-linux-world-viewport-ci.md`.
- No `doc/features/**` handbook changed because the player-facing World
  contract did not change; this fixes cross-platform conformance to the already
  documented responsive viewport.

## Verification evidence

- User-provided GitHub Actions log: isolated the failure to
  `spec/system/responsive_neverlands_ui_spec.rb:113`, with actual width 1,287
  versus expected width 1,302 and all other geometry exact.
- `gh --version`: could not run because GitHub CLI is not installed in the
  workspace; the supplied complete CI log was sufficient for diagnosis.
- `bundle exec rspec spec/system/responsive_neverlands_ui_spec.rb:113`: passed,
  1 example, 0 failures.
- `git diff --check`: passed before completion verification.
- `bin/verify full`: passed.
  - RuboCop: 375 files, 0 offenses.
  - Non-system RSpec: 1,580 examples, 0 failures.
  - System RSpec: 203 examples, 0 failures, 4 explicitly pending Arena
    examples.
  - Brakeman: 0 security warnings.
  - Bundler Audit: no vulnerabilities found.
  - Importmap audit: no vulnerable packages found.
  - Feature-document audit: passed for 7 documents, with the existing
    transitional warnings for partially implemented Game Shell and Shop
    Economy handbooks.

## Explicit follow-ups

- The four existing Arena system examples remain explicitly pending for their
  recorded reasons; this fix does not alter Arena behavior.
- No `[IMPL]`, `[DOC]`, or `[EVIDENCE]` discrepancy was introduced or remains
  for this viewport fix.
- No migration, operational action, or new dependency is required.
