# Hotwire and Stimulus Application Guide

- Record type: technical-guidance session changelog
- Date: 2026-07-28
- Branch: `chore/ui_ux`
- Primary file: `doc/RUBY_ON_RAILS_GUIDE.md`
- Runtime behavior changed: no

## Outcome

The Rails technical guide now contains concrete Hotwire and Stimulus practices
derived from this application's active shell, World, City, linked-location,
Inventory, progression, chat/presence, Arena/Fight, and vitals surfaces.

The guidance remains subordinate to `AGENT.md` and does not create a second
gameplay-design authority. It explains how to maintain the existing Rails,
Turbo, Stimulus, and Action Cable boundaries without moving authoritative game
state into the browser.

## Guidance added

### Turbo navigation and frame ownership

- Stable, single-owner frame and DOM ids.
- Explicit ownership of shell frames such as `main_content`,
  `available-actions`, and the lazy `chat_messages` boundary.
- No duplicate shell-owned frames in child views.
- Frame endpoints avoid unrelated full-shell query preparation.
- Deliberate full-page handoff through redirects, Turbo visits, or `_top`.
- Direct/full-page fallback and secured lazy-frame endpoints.
- Frame-id changes treated as HTTP/UI contract changes requiring synchronized
  view, stream, Stimulus, and spec updates.

### Mutation and Turbo Stream contracts

- Native forms and `requestSubmit()` preferred over `form.submit()` or custom
  mutation fetches.
- Explicit success choices: `303 See Other`, bounded stream response, or
  `head :ok` only when an established after-commit broadcast owns the visible
  result.
- Failure responses preserve authoritative state and use a real error status.
- Practical `update`, `replace`, `append`/`prepend`, and `remove` selection
  rules, including controller reconnect and duplicate/retry implications.
- One coherent post-transition snapshot for multi-target World, Inventory, and
  progression stream updates.
- DOM target knowledge remains in controllers/views, never domain services.

### Stimulus scope and lifecycle

- Declared targets, typed values, and actions as the default integration
  contract.
- `this.element`-scoped querying instead of broad global selectors unless the
  interaction is genuinely global.
- Optional target guards and explicit support for an element shared by two
  namespaced controller targets.
- Datasets/values treated as serialized presentation or opaque intent, never
  trusted gameplay authority.
- Idempotent `connect()` and complete `disconnect()` cleanup for listeners,
  intervals, timeouts, animation frames, observers, subscriptions, and stale
  fetches.
- The exact bound-listener-reference rule, preventing ineffective
  `removeEventListener(...bind(this))` cleanup.
- `requestAnimationFrame` after insertion for the fixed-pixel World, City, and
  linked-location centering pattern.

### Server time, previews, and browser persistence

- Absolute server timestamps for reload-safe countdowns.
- Animation completion triggers reconciliation/navigation, not persistence.
- Vitals, AP, allocation, and turn-cost previews remain display-only; the
  server recomputes submissions and replaces stale previews.
- Sleeping-tab recovery derives from timestamps/snapshots rather than assuming
  every timer callback ran.
- `localStorage` is limited to namespaced, validated, non-authoritative UI
  preferences.

### DOM safety, fetch, and realtime ownership

- Action Cable, JSON, datasets, player/content strings, and error messages are
  untrusted presentation input.
- Plain text uses `textContent`/DOM APIs; structured dynamic HTML should be an
  escaped server partial rather than a JavaScript template string.
- Same-origin HTML replacement is allowed only when the server owns escaping
  and authorization and the client adds no untrusted markup.
- Custom fetch is limited to established partial, polling, beacon, or
  limited-JSON contracts with correct Accept/CSRF/status/stale-request handling.
- Turbo Stream broadcasts own escaped server fragments such as chat rows.
- Typed Action Cable events own focused high-frequency Arena updates.
- A visible transition has one realtime renderer unless it has an explicit
  deduplication contract.
- Authorized stream scope, after-commit broadcast, stable payload types, and
  authoritative reconnect snapshots are required.

### Application ownership and coverage

- Added a repository-specific ownership matrix for Shell, outdoor World,
  City/linked locations, Inventory/progression, chat/presence, Arena/Fight, and
  the vitals bar.
- Clarified that the matrix identifies intended seams rather than certifying
  every older controller as fully compliant.
- Expanded accessibility rules for native controls, focus, asynchronous status,
  and hover/focus/touch parity.
- Added view/request/service/job/channel/system coverage responsibilities for
  frames, stream targets, controller wiring, broadcasts, reconnect behavior,
  responsive panning, and HTML fallback.
- Expanded broadcast guidance, anti-patterns, the implementation checklist,
  and the guide's pre-final/changelog workflow to match `AGENT.md`.

## Pre-final review

The stabilized guide diff was checked against:

- `AGENT.md` authority, pre-final review, verification, feature-document, and
  changelog rules;
- the guide's controller, authorization, server-authority, broadcast, testing,
  anti-pattern, and completion sections;
- current frame ids, stream targets, controller names, Action Cable snapshot
  method, and `requestSubmit()` usage in `app/**`;
- current request/view/system/broadcast spec patterns.

The review added an explicit legacy-compliance qualifier and changed Action
Cable payload wording from an implied explicit schema version to a stable
internal contract. No runtime implementation was modified.

## Files and documentation

- Modified `doc/RUBY_ON_RAILS_GUIDE.md`.
- Added this record:
  `changelogs/2026-07-28-hotwire-stimulus-guide.md`.
- No `doc/features/**` handbook changed because this task changed technical
  implementation guidance, not shipped player behavior or ownership.
- No dependency, schema, seed, route, controller, view, JavaScript, CSS, or
  gameplay change was introduced by this task.

## Verification evidence

- `git diff --check`: passed before completion verification.
- Application-reference validation: every named frame/target/snapshot/form API
  example was found in current `app/**` paths.
- `bin/verify fast`: passed.
  - RuboCop: 375 files, 0 offenses.
  - Non-system RSpec: 1,580 examples, 0 failures.
  - Feature-document audit: passed for 7 documents, with the existing expected
    transitional warnings for partially implemented Game Shell and Shop
    Economy handbooks.

## Explicit follow-ups

These are existing implementation-audit candidates, not changes made or hidden
inside this documentation task:

- `[IMPL]` Review dynamic HTML construction in active Arena/Fight and chat
  controllers. Event/dataset values should move to escaped server partials or
  DOM construction with `textContent` where they can contain player/content
  data.
- `[IMPL]` Review older countdown timeout handles so all callbacks are cancelled
  or rendered harmless after Stimulus disconnect/reconnect.
- `[IMPL]` If `mobile_hud_controller.js` is mounted again, replace per-call
  `.bind(this)` listener registration with stored bound references and remove
  its touch listeners during disconnect.

No `[DOC]` or `[EVIDENCE]` discrepancy remains in the guide change itself. The
follow-ups require separately scoped runtime review and applicable browser/
security coverage; this record does not claim they are already implemented.
