# AGENTS.md — Neverlands-Based Rails MMORPG Engineering Contract

Contract metadata:

- updated_at: `2026-09-14`
- why_changed: "Make area changes trigger mandatory review and same-task synchronization of related game books, feature handbooks and directly affected documentation."

This file is the repository entry point for engineering work. It tells an agent
what to read, which rules are mandatory, what to verify, and what to report.
`doc/RUBY_ON_RAILS_GUIDE.md` supplies deeper Ruby, Rails, and Hotwire guidance;
it does not duplicate this workflow or define game design.

Sections marked `[NORMATIVE]` are mandatory. Examples are proportional: apply a
boundary only when the changed behavior needs it.

## 1. [NORMATIVE] Authority and truth layers

Authority is split by concern:

1. System, developer, and explicit user instructions outrank repository files.
2. Neverlands live behavior and preserved Neverlands evidence are the sole
   game-design authority. Generic RPG conventions are never a substitute.
3. `doc/design/**` owns captured evidence, normalized design, and MVP scope.
4. `doc/features/**` describes verified local runtime behavior or an explicit
   audited `NOT_IMPLEMENTED` absence.
5. `AGENTS.md` owns engineering workflow and acceptance gates.
6. `doc/RUBY_ON_RAILS_GUIDE.md` owns technical implementation guidance.
7. Code, tests, schema, and gameplay configuration show current runtime state.

No layer silently overrides another outside its concern. Passing code does not
validate an invented mechanic, evidence does not prove local implementation,
and a feature handbook must not claim behavior that code and tests do not
provide.

Start every gameplay task at `doc/DOCUMENTATION.md`, then follow:

- `doc/domains/README.md` and the relevant domain page;
- the relevant source summary and observations under `doc/design/reference/`;
- `doc/design/gdd.md` plus applicable area/mechanic documents;
- `doc/design/launch_mvp_plan.md` for the current delivery boundary;
- the responsible handbook under `doc/features/`;
- the applicable game books and direct consumers in the
  [documentation context/update map](doc/DOCUMENTATION.md#21-required-context-and-update-map);
- applicable sections of `doc/RUBY_ON_RAILS_GUIDE.md`.

Classify mismatches explicitly:

- `[IMPL]` — runtime or coverage differs from established design/contract;
- `[DOC]` — documentation differs from verified runtime;
- `[EVIDENCE]` — Neverlands behavior is missing or ambiguous.

Fix in-scope `[IMPL]` and `[DOC]` gaps. Never invent a resolution for an
`[EVIDENCE]` gap; observe Neverlands or ask the user.

## 2. [NORMATIVE] Standard engineering workflow

Every implementation, bug fix, behavior change, refactor, migration, or
executable process-tooling change automatically follows this workflow. No
special prompt phrase, YAML receipt, profile declaration, or per-conversation
changelog is required.

Read-only explanation, review, diagnosis, and planning do not authorize edits.

1. **Orient** — read the relevant truth layers, routes, owners, UI, config,
   schema, and existing specs.
2. **Resolve scope** — state the intended behavior and important evidence,
   security, persistence, concurrency, Hotwire, or operational risks.
3. **Inspect ownership** — extend the smallest existing Rails/domain owner;
   preserve unrelated user changes and avoid parallel pipelines.
4. **Implement** — use the smallest clear Rails-native solution that preserves
   server authority and Neverlands behavior.
5. **Test while working** — add applicable focused coverage and run the
   smallest useful specs/lint after coherent slices.
6. **Review the stable diff** — apply the risk-based questions in
   `doc/RUBY_ON_RAILS_GUIDE.md`; correct concrete findings before completion.
7. **Synchronize documentation** — update each canonical document whose owned
   truth changed. Do not edit unrelated documents merely to create ceremony.
8. **Verify** — run the proportional completion command from section 8.
9. **Manual browser acceptance** — after automated checks pass, personally
   exercise the changed local UI and flow in a real browser as required by
   [section 8](#manual-browser-acceptance).
10. **Report** — summarize rationale, behavior/files, documentation, exact check
   outcomes, and any remaining `[EVIDENCE]` or deferred risk.

### Optional planning-first gate

Use a stop-gate only when the user asks for a plan before implementation or
asks to work per `AGENTS.md` without yet authorizing changes:

1. extract evidence and the player/server contract;
2. scan current implementation and tests;
3. propose `NEW`, `MODIFY`, and `DELETE` actions, coverage, and up to five
   risks;
4. end with `CONFIRM_TO_IMPLEMENT? (yes/no)` and wait.

After approval, continue at step 4 of the standard workflow without repeating
the plan or asking for a second confirmation.

## 3. [NORMATIVE] Scope, safety, and repository care

Normal implementation scope may include `app/**`, applicable `config/**`,
`db/**`, `lib/**`, `spec/**`, relevant design/feature documents, and
`.env.example`.

Editing `AGENTS.md`, canonical templates, repository-wide documentation
structure, CI, production/deployment configuration, or secrets requires
explicit task scope. The current task must not expand into those areas by
implication.

- Preserve unrelated dirty-worktree changes.
- Never expose, copy, log, or commit credentials, cookies, or tokens.
- Never mutate production data while testing.
- Resolve exact targets before destructive filesystem or database actions.
- Do not edit committed migrations unless the user explicitly authorizes a
  pre-release schema-history rewrite.
- Verification commands must not rewrite source files; never use lint auto-fix
  as a completion check. Browser acceptance may perform bounded, authorized
  gameplay mutations on local development test data; preserve unrelated data.

## 4. [NORMATIVE] Implementation approach

Every approach must satisfy these criteria proportionally:

- **Rails way** — prefer framework conventions and existing repository
  capabilities over custom frameworks or dependencies.
- **SRP/cohesion** — an object owns one cohesive reason to change; this does not
  mean one class per method.
- **Practical DI** — make meaningful collaborators, clocks, RNGs, catalogs, and
  side effects explicit where substitution improves clarity or determinism;
  do not add a DI container by default.
- **PORO/KISS** — choose the smallest clear object boundary and remove wrappers
  whose only rationale is style or hypothetical reuse.
- **Justified services** — introduce a service/query only for multi-record
  orchestration, a state transition/transaction, external IO/side effects, or
  a material clarity/testability improvement.
- **Hotwire fit** — keep HTML/server state primary, Turbo fragment ownership
  stable, and Stimulus narrowly focused on client enhancement.

Prefer conventional Rails ownership:

- controllers orchestrate requests, strong parameters, authorization, and
  response selection;
- models own associations, validations, scopes, enums, and small domain rules;
- database constraints protect durable invariants;
- policies own record/action authorization;
- services own justified workflows and transactions, not simple model proxies;
- query objects own materially complex/reused bounded reads;
- ERB renders state; helpers/presenters format it without hidden database work;
- Stimulus manages focused browser behavior, never authoritative game rules.

Document a new or materially changed service/query object's purpose and public
entry-point inputs, output, and important side effects. Explain non-obvious
private rules, not Ruby syntax.

## 5. [NORMATIVE] Gameplay correctness

The client expresses intent and displays results. The server alone decides and
persists coordinates, locations, availability, cooldowns, combat outcomes,
inventory, equipment, currency, ownership, rewards, and other gameplay state.

Treat submitted ids, prices, quantities, coordinates, timers, labels, CSS
geometry, hidden values, and capability flags as untrusted. At mutation time,
revalidate authentication, authorization, ownership, current state, target,
availability, expiry, balance/capacity, and boundary conditions.

Every persistent gameplay transition must make these facts identifiable in
implementation and tests:

1. authoritative records, inputs, and preconditions;
2. successful state changes and side effects;
3. failure behavior and state that remains unchanged;
4. transaction/locking/constraint boundary where correctness needs one;
5. retry, duplicate, or concurrent behavior where realistic;
6. resulting authoritative state rendered or returned.

Use the simplest sufficient transaction, lock, unique key, database constraint,
or scoped idempotency guard. A failed valuable transition must not leave
partial state, and a retry/double click must not duplicate rewards, items,
money, movement, collection, or combat state. Do not add a universal command
bus, event store, or idempotency framework.

Additional invariants:

- authored cells, NPCs, shops, resources, encounters, rewards, and balance
  values use stable ids and Neverlands-backed config/seeds/records;
- content validation happens at its loading or persistence boundary;
- pure calculations do not query the database;
- random behavior accepts/constructs a seeded RNG at a testable boundary;
- the server clock owns expiry/cooldowns, and tests cover before/at/after where
  timing matters;
- valuable currency/inventory/reward/PvP/admin changes leave a bounded,
  secret-safe audit record or structured log when reconstruction matters.

## 6. [NORMATIVE] Hotwire, async, performance, and operations

### Hotwire and client behavior

- Prefer Turbo Drive, Frames, and Streams for server-rendered interaction.
- Use Stimulus targets, values, and actions instead of global state or broad DOM
  queries; clean up timers/listeners on disconnect.
- Keep frame ids and stream targets stable and single-owned.
- Publish realtime presentation only after committed authoritative state.
- Make reconnect/reload recover from persisted state; broadcast order is not
  gameplay authority.
- Escape dynamic output and add applicable keyboard/accessibility coverage.

### Deferred work and broadcasts

For important jobs or external/realtime side effects, define retryability,
idempotency, missing/stale records, after-commit timing, and a bounded recovery
path. Queue telemetry is not automatically durable application intent. Add a
ledger/reconciler only when losing work cannot be recovered safely from current
authoritative state.

### Reads, caches, and operational tools

- Prevent N+1 and query-per-row behavior; preload and bound collections/batches
  that can grow.
- A cache/projection is derived state. Define complete keys/version, freshness,
  invalidation, malformed/unavailable fallback, publication safety, and
  targeted recovery only when such a component exists.
- Separate structural query/row/batch budgets from measured latency claims.
  Benchmarks state environment, workload, sample size, percentiles, and errors.
- Risky operator mutations are exact-target, fail closed, observable, and
  post-verified; status output is bounded and secret-safe.

These are review questions, not instructions to add caches, jobs, ledgers,
metrics, runbooks, or abstractions to a feature that does not need them.

## 7. [NORMATIVE] Tests and coverage

Every executable feature, bug fix, behavior change, or refactor requires tests.
Process tooling requires focused tests where practical. Documentation-only
copy changes do not require invented runtime specs.

Choose layers by changed behavior, not by a universal checklist:

- model specs for model rules and persistence invariants;
- service/query specs for public workflow/query boundaries;
- request/policy specs for HTTP, ownership, and authorization;
- view/helper specs for rendering contracts;
- system specs for meaningful Turbo/Stimulus/browser interaction;
- job/config/cache/task specs for their actual lifecycle and failure modes;
- seed/config/schema specs when malformed content or migration boundaries can
  break gameplay.

Cover the applicable categories:

- **success** — intended persisted and rendered result;
- **failure** — safe rejection and unchanged authoritative state;
- **edge/null/boundary** — empty/nil/zero/max/out-of-range/time/capacity cases;
- **authorization** — anonymous, foreign owner, role/context denial;
- **retry/concurrency** — for vulnerable valuable mutations.

An inapplicable category needs no fake spec or metadata declaration. Do not
require model, policy, request, or system coverage when that layer was not
touched and another public boundary proves the behavior more directly.

Keep one thin system-spec path for the MVP core loop:

```text
login -> restore location -> travel -> enter/leave -> logout -> login -> restore
```

Test detailed variants at narrower layers. Blueprint and rswag specs apply only
if those surfaces actually exist.

## 8. [NORMATIVE] Documentation and verification

### Documentation synchronization

**Changing an area automatically triggers a documentation impact review; no
separate user request to update docs is needed.** Before editing, identify the
related documentation owners and direct consumers through
[DOCUMENTATION.md's change-trigger rules](doc/DOCUMENTATION.md#22-change-triggered-documentation-updates).
This includes game books, feature handbooks, `ARTWORK.md`, evidence/design and
applicable technical, process or operational guides, including future documents.
Apply this to additions, fixes, removals, refactors and content/configuration
changes, including changes made only in seeds, numerical tables or artwork.
Before completion, synchronize every affected description in the same task.
Updating a global book does not replace updating its runtime handbook, or vice
versa. The context map guides discovery; it is not an exhaustive list of docs.

Documentation must reflect changed truth in the same task:

- evidence changes update the relevant observation/source summary;
- normalized game behavior changes update design/MVP scope;
- shipped runtime behavior or ownership changes update its feature handbook;
- content, formula, rule or editing changes update the affected global game
  books and their directly affected examples, tables and cross-references;
- process/tool behavior changes update its canonical process/onboarding docs;
- cross-feature operational procedures use `doc/guides/**` only when one real
  workflow spans several owners.

Do not update every document that mentions a topic. Update the canonical owner
and any directly contradicted summaries/links. Historical changelogs remain
historical.

New shipped handbooks use the eight-section `feature-v3` template in
`doc/features/FEATURE_TEMPLATE.md`. Existing `feature-v1`/`feature-v2`
handbooks may remain until a material rewrite is useful. Acceptance-to-spec
tables are optional and reserved for high-risk or cross-cutting gameplay where
they materially improve traceability.

`NOT_IMPLEMENTED` documents must not invent runtime files, routes, specs, or
state. Use the lean gap template.

Changelogs/change notes are optional. Create one when the user requests it, a
release/rollout needs it, or a durable architectural decision is otherwise hard
to discover. They are not workflow state and do not gate verification.

### Verification commands

During implementation, run focused checks such as:

```bash
bundle exec rspec spec/path/to/changed_spec.rb
bin/rubocop path/to/changed.rb spec/path/to/changed_spec.rb
bin/feature-doc-audit doc/features/<feature>.md
```

Completion profiles:

- `bin/verify fast` — default for ordinary runtime changes: read-only lint,
  non-system specs, and documentation audits;
- `bin/verify combat` — focused arena/formula work plus lint/docs;
- `bin/verify full` — broad/high-risk runtime changes, dependencies, migrations
  with material data risk, release readiness, or explicit user request;
- `bin/verify docs` — documentation architecture/templates only;
- process/verification changes — run focused script/audit specs, read-only lint,
  and `bin/verify docs`; add `fast`/`full` when their behavior or risk warrants
  the broader suite.

CI independently runs security, lint, non-system specs, system specs, and
documentation audits. Local verification never requires editing a receipt or
changelog into a special state.

The documentation audits intentionally enforce a small set of objective facts:
resolving canonical links/paths, required ownership/navigation, unresolved
template placeholders, duplicate handbook ownership, and false
`NOT_IMPLEMENTED` runtime claims. They do not enforce README prose, a fixed
document inventory, or universal acceptance matrices.

### Manual browser acceptance

For any change affecting a browser-visible surface or player flow, the agent
must personally verify the final local implementation through browser tools
**after the required automated checks pass and before reporting completion**.
This includes artwork, CSS, Hotwire interactions, and server changes behind a
UI flow. Earlier exploratory checks are useful but do not replace this final
acceptance pass. Automated system specs, HTTP requests, DOM inspection, or
screenshots alone do not establish that the flow works through the UI.

- Use the running local app with the final code/assets and an authorized local
  session or development test player. Exercise actual links, buttons, forms,
  tabs, and hotspots involved in the change; do not bypass the UI action with
  direct requests or database writes and call that manual acceptance.
- Follow the affected flow from entry through its action, visible result, and
  return/navigation. For persisted state, revisit or reload to confirm it
  survives. Include relevant empty/error states and recovery. A Shop flow may
  require buy → Inventory → find item → equip → confirm on player → unequip →
  confirm in Inventory; merely opening Shop is insufficient for that scope.
- Inspect the rendered result as well as behavior: artwork/composition,
  clipping, labels, feedback, overlays, and reachable controls. For changed
  layout or controls, apply the relevant viewport, keyboard/pointer, zoom, and
  hotspot checks from
  [adaptive UI acceptance](doc/design/areas/game_client_layout.md#adaptive-ui-acceptance).
  Restore temporary browser settings after checking.
- If a check fails, fix the issue, rerun the affected automated checks and the
  required completion profile, then repeat the affected final browser flow on
  the corrected version. Evidence-only documentation updates afterward require
  the relevant documentation audit, not another unchanged browser run.
- Record the actual browser, viewport/input mode, steps, observed results, and
  remaining gaps in the responsible handbook or task handoff; attach useful
  screenshots for visual changes without secrets. Distinguish manual evidence
  from automated tests, CI, and Neverlands observations.
- If the local app, browser, or required test state is unavailable, report the
  blocker and unverified flow explicitly; do not mark that UI scope Done.
  Documentation-only changes and backend work with no browser-visible effect
  may report manual browser acceptance as not applicable, with a brief reason.

## 9. [NORMATIVE] Final review and handoff

Before reporting completion:

- inspect the final diff and `git status`;
- confirm no generic RPG behavior or prohibited Neverlands identity/assets
  entered runtime;
- review applicable server authority, SRP/DI/PORO/KISS/service, Hotwire,
  atomicity/retry, query, async/cache, and operational risks;
- review the final diff against the triggered documentation owners and ensure
  their affected sections describe verified behavior; unresolved stale guidance
  is a `[DOC]` gap, even when tests and link audits pass;
- confirm final [manual browser acceptance](#manual-browser-acceptance) passed
  for the changed UI scope, or explicitly report why it is blocked/not applicable;
- report exact checks and honest pending/pre-existing failures.

Use these headings:

```markdown
### RATIONALE

### CHANGES

### CHECKS
```

Keep the handoff concise, include clickable file paths where useful, and call
out remaining `[EVIDENCE]`, `[IMPL]`, or `[DOC]` gaps explicitly.
