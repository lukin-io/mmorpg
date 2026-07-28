# AGENT.md — Neverlands-Based Rails MMORPG Engineering Contract

Contract metadata:

- updated_at: `2026-07-28`
- why_changed: "A substantive Codex session now owns one living changelog record, created with its first material edit and updated across every follow-up prompt until final handoff."

Why/Impact:

- Neverlands remains the only game-design authority; generic MMORPG conventions are not substitutes for observed behavior.
- A player-facing feature is not complete until implementation and applicable tests pass, then its canonical `doc/features/**` handbook is created or updated.
- Persistent gameplay mutations are server-authoritative, atomic where needed, safe against duplicate/concurrent execution, and covered at their behavioral boundaries.
- Verification is read-only, uses the repository's real RSpec/system/security split, and reports exact command outcomes.
- Process rules, design evidence, shipped feature contracts, and runtime code now have explicit ownership and conflict handling.
- `doc/RUBY_ON_RAILS_GUIDE.md` is the subordinate Ruby, Rails, and Hotwire implementation guide for new features, behavior changes, bug fixes, and refactors.
- A substantive Codex session maintains one auditable living record under
  `changelogs/`: create it with the session's first material repository change,
  update it across follow-up prompts, and finalize its verification evidence at
  handoff.

This document is the repository-wide engineering process contract. Sections are labeled:

- `[NORMATIVE]` — mandatory behavior.
- `[ILLUSTRATIVE]` — examples to adapt to the current task.

If two repository instructions at the same authority level conflict and the precedence rules below do not resolve them, stop and ask for clarification.

---

## 0. [NORMATIVE] Purpose and scope

This contract defines:

- game-design and implementation authority;
- execution and optional planning gates;
- Rails, Hotwire, game-domain, and security standards;
- required coverage and verification;
- post-implementation feature documentation;
- pre-final Rails-guide review and the living session-changelog lifecycle;
- discrepancy reporting and final handoff format.

It applies to all work in this Rails MMORPG repository. System, developer, and explicit user instructions remain higher authority than this file.

## 1. [NORMATIVE] Authority and precedence

### 1.1 Authority by concern

1. `AGENT.md` governs repository engineering process, verification, and documentation workflow.
2. Neverlands live behavior and preserved source material are the sole game-design authority.
3. `doc/design/**` records normalized Neverlands evidence, design decisions, and MVP scope.
4. `doc/features/**` describes verified, shipped implementation contracts.
5. `doc/RUBY_ON_RAILS_GUIDE.md` expands Ruby 4.0, Rails 8.1, Hotwire, Active Record, jobs, security, performance, and refactoring technique.
6. Code and tests show actual current runtime behavior.

No one layer silently overrides another layer outside its concern. In particular:

- passing code is not evidence that an invented game mechanic is valid;
- a feature document is not permission to ignore a newer verified Neverlands observation;
- a Neverlands observation is not proof that an unimplemented mechanic already exists locally;
- the Rails technical guide cannot invent game design, override this contract, or describe unverified behavior as shipped;
- generic RPG knowledge is never an alternate product source.

### 1.2 Guide routing

- Start with `doc/design/gdd.md` for the consolidated game-design model.
- Read the relevant documents under `doc/design/areas/` and `doc/design/features/`.
- Use `doc/design/reference/` for direct Neverlands evidence and observation gaps.
- Read `doc/design/launch_mvp_plan.md` for the current delivery boundary.
- Read the responsible document under `doc/features/` for shipped behavior and file ownership.
- For every Rails-backed new feature, behavior change, bug fix, or refactor, read the relevant sections of `doc/RUBY_ON_RAILS_GUIDE.md` for technical boundary selection and implementation guidance.
- Read `doc/features/README.md` before creating or materially restructuring a feature handbook.

### 1.3 Conflict protocol

Classify unresolved differences explicitly:

- `[IMPL]` — implementation or coverage does not satisfy the established design/feature contract.
- `[DOC]` — feature/design documentation no longer describes verified implementation.
- `[EVIDENCE]` — Neverlands behavior is ambiguous or insufficiently observed.

Fix in-scope `[IMPL]` gaps before completion. Correct in-scope `[DOC]` gaps only after behavior is verified. Do not invent a resolution for `[EVIDENCE]`; observe Neverlands or ask the user.

## 2. [NORMATIVE] Repository context

- Framework: Ruby on Rails monolith.
- Primary client: server-rendered HTML with Turbo and Stimulus.
- Authentication: Devise.
- Authorization: Pundit where record/action authorization applies.
- Test framework: RSpec, including request, view, and system specs.
- Game design: Neverlands-backed, English client for the current MVP.
- Feature contracts: `doc/features/**`.
- Canonical feature template: `doc/features/FEATURE_TEMPLATE.md`.
- Canonical session changelog template: `changelogs/CHANGELOG_TEMPLATE.md`.
- Feature document audit: `bin/feature-doc-audit`.
- Verification wrapper: `bin/verify`.
- Ruby/Rails/Hotwire implementation guide: `doc/RUBY_ON_RAILS_GUIDE.md`.
- Session history: one dated living Markdown record under `changelogs/` per
  substantive Codex session. Reuse the current session's record across all of
  its prompts; copy `changelogs/CHANGELOG_TEMPLATE.md` when a genuinely new
  session starts.

Blueprint, Swagger/rswag, and public JSON API requirements apply only when the repository actually introduces those surfaces. They are not defaults for HTML/Turbo features.

## 3. [NORMATIVE] Standard execution workflow

For an ordinary implementation task, follow this sequence:

1. **Orient** — read relevant design, feature, `doc/RUBY_ON_RAILS_GUIDE.md` sections, routes, models/services, UI, seeds/config, and specs.
2. **Resolve authority** — identify the Neverlands evidence and MVP boundary; report `[EVIDENCE]` before inventing behavior.
3. **Scan implementation** — locate existing ownership and preserve unrelated user changes.
4. **Open the session changelog** — with the first material repository edit,
   copy `changelogs/CHANGELOG_TEMPLATE.md` to the session's one dated record,
   or update the existing record when this is a follow-up prompt in the same
   session. Record work as in progress; do not claim unverified behavior as
   complete.
5. **Implement** — use minimal Rails-way changes, the technical boundaries in `doc/RUBY_ON_RAILS_GUIDE.md`, and explicit cross-feature boundaries.
6. **Add/update tests** — cover all applicable layers and required categories.
7. **Run focused verification** — run changed specs and targeted lint while iterating.
8. **Update the session changelog** — keep the same record current as scope,
   decisions, responsible files, checks, gaps, and follow-up prompts evolve.
9. **Run the pre-final technical review** — once the implementation diff is stable, review it against the applicable `doc/RUBY_ON_RAILS_GUIDE.md` sections, resolve concrete findings, and update tests when needed.
10. **Run alignment check** — compare verified behavior with design and the existing feature handbook; resolve `[IMPL]` gaps.
11. **Create/update the feature handbook** — only after implementation and applicable focused checks are green.
12. **Audit documentation** — run `bin/feature-doc-audit` for the responsible handbook.
13. **Run completion verification** — after the pre-final technical review, use the appropriate `bin/verify` profile and task-specific checks.
14. **Finalize the session changelog** — update that same record with exact
    final verification results and final Done/Not Done state, then perform
    read-only path/link/diff validation.
15. **Report** — include rationale, changed files/behavior, documentation and changelog status, discrepancies, and exact check results.

Do not create a gameplay feature handbook for infrastructure, process tooling, or a documentation-only task. Update the documentation system that owns that work instead.

## 4. [NORMATIVE] Optional planning-first gate

Use this stop-gate only when the user requests planning-first work or explicitly says `Execute per AGENT.md`.

### Phase 0 — contract and evidence extraction (no code)

- Read relevant Neverlands reference/design and existing feature handbook.
- Extract player behavior, authoritative state, routes/actions, persistence, authorization, UI, boundaries, and deferred behavior.
- Identify `[EVIDENCE]` gaps.

### Phase 1 — repository scan (no code)

- List existing controllers, models, services, policies, views, Stimulus/CSS/assets, config/seeds, factories, and specs.
- Summarize current behavior and discrepancies.
- Keep excerpts short and targeted.

### Phase 2 — implementation plan (no code; stop afterward)

- File-by-file actions: `NEW`, `MODIFY`, or `DELETE`.
- Responsibility and important transition for each file.
- Test mapping for success, failure, edge/null/boundary, and authorization.
- Up to five risks or `[IMPL]`/`[DOC]`/`[EVIDENCE]` discrepancies.
- Feature-document creation/update plan.

End with:

```text
CONFIRM_TO_IMPLEMENT? (yes/no)
```

Wait for explicit confirmation before implementation. Ordinary tasks that do not invoke this gate should proceed autonomously.

## 5. [NORMATIVE] Edit scope and safety

### 5.1 Allowed by default when required by the task

- `app/**`
- `config/**`
- `db/migrate/**`, `db/schema.rb`, and `db/seeds.rb`
- `lib/**`
- `spec/**`
- relevant `doc/features/**` after implementation verification
- relevant `doc/design/**` when verified Neverlands/design facts materially change
- `changelogs/**` for the one living record of a substantive change session
- `.env.example`

### 5.2 Requires explicit task scope

- `AGENT.md`
- `doc/features/FEATURE_TEMPLATE.md`
- repository-wide documentation structure
- CI/workflow files
- production/deployment configuration
- Docker/Kubernetes infrastructure
- secrets or credentials

Normal feature work must not modify the canonical template merely because one feature needs unusual content. Keep all 18 sections and explain non-applicable sections.

### 5.3 Safety

- Preserve unrelated dirty-worktree changes.
- Never expose, copy, or commit credentials.
- Never run destructive database or filesystem operations without resolving exact scope.
- Test-database preparation is allowed when needed; never mutate production data.
- Do not run `rails credentials` or change encrypted secrets unless explicitly requested.

## 6. [NORMATIVE] Engineering rules

Apply `doc/RUBY_ON_RAILS_GUIDE.md` to Rails implementation and refactoring decisions. This contract wins on conflict, and Neverlands evidence remains the only game-design authority.

1. Use conventional Rails patterns, clear names, and production-grade invariants.
2. Prefer Rails-way and KISS over speculative abstractions or mini-frameworks.
3. Respect existing HTML/Turbo/Stimulus architecture; do not introduce a SPA or custom AJAX without a demonstrated need.
4. Keep controllers focused on request orchestration and response selection.
5. Put associations, validations, scopes, and small domain rules in models.
6. Use services/queries for multi-model orchestration, state machines, external side effects, or materially clearer/testable flows.
7. Avoid N+1 queries with `includes`/`preload` and paginate genuinely large collections.
8. Prefer database constraints for persistent invariants: `NOT NULL`, foreign keys, and unique indexes.
9. Store time in UTC. Use ISO8601 for JSON integration responses.
10. Use strong parameters, retain CSRF protection, escape view output, and authorize mutations.
11. Minimize dependencies; prefer stable tools already in the stack.
12. Keep diffs scoped to the requested feature or bug.

## 7. [NORMATIVE] Game-domain rules

### 7.1 Server authority and persistent transitions

- The client expresses intent and displays results. The server alone decides and persists coordinates, location, availability, cooldowns, combat results, inventory, currency, ownership, rewards, and other gameplay state.
- Treat CSS geometry, Stimulus state, hidden inputs, labels, coordinates, record ids, prices, quantities, timers, and capability flags submitted by the client as untrusted input.
- Revalidate ownership, current position/location, target, status, availability, expiry, price/quantity, balance/capacity, and boundary conditions at mutation time.
- Never put authoritative game calculations in controllers, views, or browser code.

Every action that changes persistent gameplay state—including movement, location entry/exit, combat, inventory, currency, rewards, and resource collection—must have an identifiable transition contract in its service/model behavior and tests:

1. preconditions and authoritative input records;
2. successful state changes and side effects;
3. failure behavior, including which state remains unchanged;
4. transaction/locking boundary where multiple records or balances must change together;
5. resulting state returned or rendered to the client.

Use the simplest Rails/database mechanism that preserves the invariant. This may be a database transaction, constraint, row lock, uniqueness key, or command-specific idempotency guard; it does not imply a universal command bus or event-sourcing architecture.

### 7.2 Retry and concurrency safety

- A retried, double-clicked, replayed, or concurrent command must not duplicate rewards/items, spend currency twice, move twice, collect the same resource twice, or create incompatible/overlapping combat state.
- Mutations vulnerable to duplicate or concurrent execution require focused coverage for the realistic conflict path, not merely sequential success coverage.
- A rejected or failed transition must not leave partial multi-record state.
- Do not add universal idempotency tokens preemptively. Choose a scoped guard when the action and risk require one.

### 7.3 Game content and stable identity

- Neverlands-derived cells, locations, exits, NPCs, shops, resources, encounters, and balance values belong in explicit records, seeds, or existing gameplay configuration—not scattered across controllers, views, or Stimulus controllers.
- Persistent references and routing/lookup keys use stable identifiers that do not depend on translated or mutable display names.
- Content validation belongs at its loading/persistence boundary and requires focused config/seed/model coverage where invalid content could break gameplay.
- Do not add generic buildings, resources, rewards, professions, gates, travel rules, or combat behavior without Neverlands evidence.
- Keep observed but unimplemented behavior read-only, disabled, or explicitly deferred.

### 7.4 Determinism, time, and calculation boundaries

- Never access the database from pure formula/calculation classes.
- Inject or construct a seeded RNG for random combat, encounter, loot, spawn, and resource behavior so the same seed and inputs produce reproducible results.
- The server clock is authoritative for cooldowns, travel durations, expiry, and other time-gated behavior.
- Tests freeze/inject time and seed/inject randomness; they must not depend on wall-clock timing, uncontrolled randomness, execution order, or external Neverlands availability.
- Cover exact timing and numeric boundaries: immediately before, at, and after expiry/cooldown; zero/maximum capacity; insufficient/exact balance; and map/location edges where applicable.

### 7.5 MVP performance and traceability

- Keep rendered map, location, inventory, shop, and combat queries bounded; prevent N+1 queries and paginate only collections that can genuinely grow large.
- When high-value currency, inventory, reward, PvP, or administrative mutations are introduced, emit a structured audit/domain record or existing structured log sufficient to reconstruct who changed what and why. Do not introduce event sourcing solely to satisfy this rule.

## 8. [NORMATIVE] Hotwire and client behavior

- Prefer Turbo Drive for navigation and Turbo Frames/Streams for partial replacement.
- Use Stimulus controllers under `app/javascript/controllers/` for focused client enhancement.
- Do not use inline JavaScript in views.
- Prefer `data-controller`, `data-action`, values, and targets over global state or broad DOM querying.
- Client code may animate, submit, focus, announce, and display server state.
- Client code must not decide authoritative availability, finalize server transitions, mint capability keys, or bypass policy/service validation.
- UI changes require applicable view and system coverage, including keyboard/accessibility behavior when relevant.
- Preserve retained Neverlands-backed images and assets unless the user explicitly requests their replacement/removal.

## 9. [NORMATIVE] Controllers, models, policies, and services

### Controllers

- Prefer RESTful actions where the game interaction maps cleanly to resources.
- Use custom member/collection actions when they accurately represent a game command.
- Keep actions small and use strong parameters.
- Use `before_action` for obvious shared loading/authentication only.
- Support only response formats the feature genuinely uses.

### Models

- Own persistence invariants, associations, validations, enums, and reusable scopes.
- Pair application validation with database constraints where appropriate.
- Avoid callbacks for hidden multi-record orchestration.

### Policies

- Use Pundit for record/action authorization where applicable.
- Scope every mutation to the authenticated user's authoritative character/resource before domain execution.
- Add policy specs for permitted and forbidden ownership/role cases.

### Services and query objects

Create a service/query object only when it:

1. orchestrates multiple records;
2. owns a state transition or transaction;
3. performs external IO/side effects; or
4. materially improves clarity and testability.

When creating or materially changing a service/query object:

- document the class/module purpose;
- document each public entry point's inputs, output, and important side effects;
- document private methods only when they encode non-obvious rules, fallback resolution, caching, normalization, or external IO;
- explain intent rather than restating Ruby syntax.

## 10. [NORMATIVE] Migrations, schema, and seeds

- Use one migration per logical structural responsibility.
- Migrations must be reversible where practical.
- Never edit a committed migration unless the user explicitly authorizes a pre-release schema-history rewrite.
- Add indexes, foreign keys, null constraints, and uniqueness constraints that enforce the model contract.
- A migration or backfill that transforms persisted player state must document its legacy/null-row handling and safe rollback or recovery approach. Test representative existing-state boundaries where practical.
- Update `db/seeds.rb` or existing gameplay config for source-backed MVP content needed by the change.
- Keep seed execution idempotent.
- Do not invent representative game content when Neverlands-backed content is required.
- Schema/seed changes require test database preparation, seed/config coverage, and seed verification where applicable.

## 11. [NORMATIVE] Tests and required coverage

Every feature, bug fix, or refactor requires tests unless the change is documentation-only and has no executable behavior. Tooling/process changes require focused tooling tests where practical.

Required layers where applicable:

- model specs;
- request specs;
- policy specs;
- service/query specs;
- factories with edge traits;
- view/helper specs;
- system specs for Turbo/Stimulus/player interaction;
- routing specs for custom routes;
- seed/config/schema specs;
- asset specs when retained assets or rendering contracts matter.

Required categories:

- **success** — intended behavior and persisted/rendered result;
- **failure** — validation/service failures and safe response;
- **edge/null/boundary** — empty, nil, zero, maximum, negative/out-of-range, expiry, timing, and missing/sparse state;
- **authorization** — anonymous, foreign ownership, wrong role/context, and policy denial.

For a vulnerable persistent mutation, applicable service/request/model coverage must also exercise retry, duplicate submission, or concurrent execution and confirm there is no partial or duplicated state.

Maintain one focused system-spec path for the implemented MVP core loop:

```text
login -> restore persisted location -> travel -> enter city/building -> leave -> logout -> login -> restore the same authoritative location
```

Keep this as a thin cross-feature contract. Test detailed movement, location, persistence, failure, and authorization variants in the narrower model/service/request/policy layers rather than duplicating every combination in the browser.

Blueprint and Swagger/rswag specs are not required unless the feature actually introduces those surfaces.

Factories must include useful edge traits for statuses, ownership, expiry, active/inactive state, nullability, and boundary values exercised by specs.

## 12. [NORMATIVE] Verification contract

Verification must be read-only. Never use auto-fix flags such as `standardrb --fix` or `rubocop -a` as completion checks.

### 12.1 While implementing

Run the smallest useful checks repeatedly:

```bash
bin/rubocop path/to/changed_file.rb
bundle exec rspec spec/path/to/changed_spec.rb
bin/feature-doc-audit doc/features/<feature>.md
```

Run relevant system specs whenever UI, Turbo, Stimulus, keyboard behavior, or browser navigation changes.

### 12.2 Pre-final technical review

For every Rails-backed feature, behavior change, bug fix, or refactor, perform a
second, proportional review of the stabilized task diff against the applicable
sections of `doc/RUBY_ON_RAILS_GUIDE.md` before the completion verification
profile. This is distinct from reading the guide during orientation.

Check the concerns actually touched by the task, including where applicable:

- controller, model, policy, service/query, and transaction ownership;
- server authority, Pundit/ownership checks, untrusted input, and failure state;
- ERB/Turbo/Stimulus boundaries, including database work in views/helpers and
  broad DOM queries;
- bounded reads, preload reuse, N+1/query-per-row behavior, and unnecessary
  hydration;
- stable content/config/catalog ownership without duplicate pipelines or
  speculative abstractions;
- retry/concurrency, time/randomness, seed/persistence reconciliation, and
  required coverage.

Fix concrete in-scope findings, add or adjust focused coverage, and rerun the
affected focused checks. Focused specs may run earlier during iteration; the
point of this gate is that the **final** completion suite runs after the guide
review and therefore covers its resulting changes. Documentation-only work
uses this gate only when it changes Rails guidance, architecture, ownership,
or claims about runtime behavior.

### 12.3 Completion profiles

Default completion profile:

```bash
bin/verify fast
```

`fast` runs:

1. read-only RuboCop;
2. all non-system RSpec specs;
3. the feature-document audit.

Use the full profile when:

- the user requests full verification;
- process/verification tooling or `AGENT.md` changes;
- the change is broad or cross-feature;
- preparing a release/push where local full CI parity is required.

```bash
bin/verify full
```

`full` adds:

- system specs;
- Brakeman;
- Bundler Audit;
- Importmap audit.

For schema or seed changes, also run as applicable:

```bash
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test bin/rails db:seed:replant
```

Available focused profiles:

```bash
bin/verify lint
bin/verify docs
bin/verify combat
```

If a required command cannot run because of environment/dependency limitations, report the exact blocker and continue with safe checks that remain meaningful.

## 13. [NORMATIVE] Feature documentation completion contract

### 13.1 When a feature handbook is required

After implementation and applicable focused verification pass:

- create a handbook for every new player-facing feature;
- update the canonical handbook for material behavior, UI, topology/content, route, state, authorization, persistence, integration, or ownership changes;
- update a handbook for a bug fix/refactor only when the documented contract or responsible-file inventory changes;
- do not create gameplay handbooks for infrastructure/process-only work.

Feature documents describe verified implementation. They are not planning PRDs.

### 13.2 Structural authority

- Copy `doc/features/FEATURE_TEMPLATE.md` for a new handbook.
- New canonical docs declare `template: feature-v1` in frontmatter.
- Preserve all 18 numbered sections and their order.
- Keep non-applicable sections and explain why.
- Remove every template instruction and placeholder.
- Use a feature-owned lowercase `snake_case` filename, not a task id.
- Treat `doc/features/FEATURE_TEMPLATE.md` as structural authority.
- Treat `world.md` and `city.md` as detailed filled examples, not alternate templates.

### 13.3 Content requirements

Every handbook must explain:

- Neverlands evidence and related design documents;
- shipped goals and explicit non-goals;
- player experience and UI/CSS behavior;
- topology/authored content;
- authoritative data and state lifecycle;
- runtime and HTTP/Turbo flow;
- client/server ownership;
- persistence/login resume;
- authorization, trust boundaries, and concurrency;
- failure, null, edge, and boundary behavior;
- acceptance criteria;
- test strategy and focused commands;
- an exhaustive `Responsible for Implementation Files` section;
- reciprocal links to every directly related feature handbook with a consistent ownership/handoff boundary;
- safe extension rules and material version history.

Interactive, read-only captured, unavailable, and deferred behavior must be unambiguous.

### 13.4 Documentation order

Use this order for a feature change:

1. correct/capture Neverlands evidence when needed;
2. update relevant design decisions when verified facts change;
3. implement behavior and tests;
4. run focused implementation verification;
5. create/update the feature handbook;
6. run `bin/feature-doc-audit doc/features/<feature>.md`;
7. run the completion verification profile.

Never update a feature handbook first and then treat its unverified text as proof of implementation.

### 13.5 Canonical ownership and duplicate merge rules

Each player-facing feature has one primary canonical handbook.

Merge documents when:

- multiple documents claim primary ownership of the same player outcome/state lifecycle;
- behavior, authorization, persistence, or implementation history is split across duplicate primary docs.

Do not merge when one document merely records an explicit cross-feature dependency. In that case, state where ownership hands off.

Cross-feature references must be reciprocal and limited to direct runtime, persistence, authorization, presentation, or authored-content handoffs. When a boundary changes, update both canonical handbooks in the same change; do not create an all-to-all feature link graph.

When merging:

1. prefer the existing feature-owned filename;
2. migrate unique verified content and responsible files;
3. update inbound references;
4. delete the duplicate, or temporarily leave a short `Superseded by:` redirect with no independent contract narrative.

## 14. [NORMATIVE] Feature-document audit

Run:

```bash
bin/feature-doc-audit
```

to audit all completed feature handbooks, or:

```bash
bin/feature-doc-audit doc/features/<feature>.md
```

for a focused audit.

The audit checks:

- required metadata and allowed implementation status;
- exact canonical section ordering for `template: feature-v1` documents;
- unresolved template instructions/placeholders;
- the required cross-feature relationship subsection and reciprocal feature links;
- trailing whitespace;
- non-empty responsible-file inventory;
- existence of responsible repository paths;
- duplicate feature titles/canonical ownership.

Pre-template handbooks may pass with a migration warning. Migrate them to `feature-v1` on their next material update. `--strict` forces canonical structure for explicitly selected legacy documents.

## 15. [NORMATIVE] Alignment and discrepancy reporting

Before feature documentation:

1. re-read relevant Neverlands/design and existing feature acceptance criteria;
2. confirm routes/actions, authoritative state, validation, auth, UI, persistence, and deferred boundaries;
3. confirm every applicable coverage category exists;
4. fix `[IMPL]` discrepancies within scope.

After documentation:

1. confirm the handbook describes only verified behavior;
2. confirm all responsible paths and focused commands exist;
3. run the feature-document audit;
4. report remaining `[DOC]` or `[EVIDENCE]` items instead of concealing them.

Large features may include a local acceptance-criterion-to-spec matrix inside the feature handbook. Do not force API endpoint traceability artifacts onto non-API gameplay work.

## 16. [NORMATIVE] Session changelog contract

### 16.1 One living record per session

Create exactly one changelog record for a substantive Codex session that
changes runtime code, tests, persisted content, seeds/config, UI/CSS/UX,
process/tooling such as `AGENT.md`, or materially changes design/feature
documentation. Create it with the session's first material repository edit and
keep updating that same file until the session's final handoff.

For this contract, a session is the continuous task conversation/thread, not
an individual user prompt or implementation subtask. A follow-up prompt,
approval, correction, review request, CI failure, or newly added work area in
the same ongoing conversation continues the same session and must update its
existing record. It must not create another changelog file. A new record is
appropriate only for a genuinely new Codex session/thread or when the user
explicitly declares that the previous session is closed and a new one begins.

A changelog is not required for answer-only, read-only investigation,
abandoned/no-change, or planning-only work. If such a prompt follows material
work in the same open session, the existing record remains the sole session
record; update it only when there is new material progress worth recording.

### 16.2 Location, name, and template

- Store records under `changelogs/` at the repository root.
- `changelogs/CHANGELOG_TEMPLATE.md` is the canonical layout. It is a template,
  not a session record, and does not count toward the one-record-per-session
  limit.
- Use `YYYY-MM-DD-short-kebab-case-description.md` for a genuinely new session.
- Before creating a file, check whether the current session already has a
  record. If it does, update that file regardless of how many prompts, fixes,
  approvals, or work areas have followed.
- If no current record exists, copy `changelogs/CHANGELOG_TEMPLATE.md`, replace
  all placeholders, remove its template instructions, and retain every
  applicable core section. A completed historical changelog is evidence of its
  own session, not the generation template.
- Choose a broad initial description suitable for the session. Do not create a
  second file merely because later prompts expand the scope, and do not rename
  the active file solely to mirror every scope change; reflect expansion in its
  title, metadata, outcome, or sections when useful.
- If multiple records were accidentally created for one session, consolidate
  their unique history, decisions, checks, gaps, and outcomes into the original
  or broadest session record, then delete the redundant fragments.
- Keep completeness proportional to the change. The existing detailed session
  record is a structural example, not a minimum word count.

### 16.3 Required content

Record, as applicable:

- date, branch/baseline or other useful scope metadata;
- outcome and task boundary;
- Neverlands/design/reference-copy boundary and important trade-offs;
- architecture and maintainability decisions;
- player/runtime behavior, UI/CSS/UX, data/cell/seed/persistence, and
  under-the-hood Rails changes;
- the pre-final `RUBY_ON_RAILS_GUIDE.md` review findings and resulting fixes;
- documentation created or updated;
- coherent implementation/responsible-file groups;
- exact verification commands/results, including pending/skipped checks;
- explicit `[IMPL]`, `[DOC]`, and `[EVIDENCE]` gaps, Not Done states,
  migrations/operational cautions, and new dependencies.

Never place credentials, cookies, tokens, private live-session data, or other
secrets in a changelog.

### 16.4 Lifecycle, truthfulness, and final validation

The changelog is a living session artifact:

1. Create it alongside the first material repository change.
2. Update it after meaningful progress and every later prompt that materially
   changes scope, decisions, implementation, documentation, checks, or gaps.
3. Label incomplete or unverified work accurately; never write a planned or
   running check as passed.
4. After completion verification, finalize the same record with exact command
   results and final Done/Not Done state.
5. Run read-only final checks such as `git diff --check` and path/link/document
   validation appropriate to the record.

If final validation requires a changelog-only correction, update the same file
and revalidate. If implementation or other material artifacts change after the
recorded completion suite, rerun the applicable verification, replace the
stale result in the same record, and revalidate. Never create a prompt-level,
progress-fragment, review-only, guide-only, or CI-fix changelog for work that
belongs to the current session record.

## 17. [NORMATIVE] Final response format

Every completed task returns these headings:

### RATIONALE

- Three to five bullets describing approach, important trade-offs, and Neverlands/architecture reasoning.

### CHANGES

- Files or coherent file groups changed.
- Player/runtime behavior changed.
- Feature handbook created/updated, including its path, or why no gameplay handbook applies.
- Current session changelog path, confirming that follow-up prompts updated the
  same record, or why a changelog was not applicable.
- Remaining `[IMPL]`, `[DOC]`, or `[EVIDENCE]` discrepancies, if any.
- New dependencies, if any.

### CHECKS

- Every command attempted.
- Final exit code, or an explicit environment/not-applicable reason.
- Exact `bin/verify` profile used.
- Exact feature-document audit command when a handbook changed.

Do not claim a check passed when it did not run.

## 18. [NORMATIVE] Never list

- Never use non-Neverlands material as alternate game-design authority.
- Never document planned behavior as shipped.
- Never finish a new player-facing feature without creating/updating its canonical handbook after verification.
- Never close a substantive repository change session without its one dated
  `changelogs/` record.
- Never create multiple changelog files for prompts, subtasks, reviews, guide
  updates, CI fixes, or corrections within one continuous session.
- Never generate a new session changelog from an older completed record when
  `changelogs/CHANGELOG_TEMPLATE.md` is available.
- Never invent an alternate feature-document structure.
- Never edit `FEATURE_TEMPLATE.md` during normal feature work.
- Never create duplicate primary feature handbooks.
- Never leave responsible implementation/spec paths knowingly stale.
- Never require blueprint/rswag coverage for an HTML/Turbo feature that has no such surface.
- Never use nonexistent `parallel_test` commands.
- Never use auto-fix linters as verification.
- Never bypass Pundit/current-character ownership where authorization applies.
- Never put authoritative game state in the browser.
- Never trust client-provided coordinates, prices, timers, quantities, capability flags, or computed outcomes as authoritative.
- Never permit retries or concurrent execution to duplicate valuable state or leave a partial transition.
- Never key persistent gameplay relationships by translated or mutable display text.
- Never ship known N+1 behavior in rendered hot paths.
- Never edit committed migrations without explicit authorization.
- Never remove retained source-backed images as incidental cleanup.
- Never commit secrets or credentials.

## 19. [NORMATIVE] Completion checklist

Before closing a task, confirm:

- relevant authority/design/feature docs were read;
- relevant `doc/RUBY_ON_RAILS_GUIDE.md` guidance was applied for Rails code changes;
- the stabilized diff received its proportional pre-final Rails-guide review before completion verification;
- optional planning gate was respected when invoked;
- implementation is minimal and Rails/Hotwire-aligned;
- persistent gameplay transitions define preconditions, atomicity/failure behavior, and resulting authoritative state;
- retry/concurrency safety, deterministic time/randomness, and stable content identity were considered where applicable;
- success, failure, edge/null/boundary, and authorization coverage exists where applicable;
- focused checks passed;
- implementation alignment was rechecked;
- feature handbook was created/updated after verification when required;
- responsible files and focused spec paths are current;
- `bin/feature-doc-audit` passed when applicable;
- the correct `bin/verify` profile completed or its blocker is reported;
- exactly one dated record exists for the session; it was created with the
  first material edit, updated across follow-up prompts, finalized after
  verification, and passed final read-only validation;
- final output contains `RATIONALE`, `CHANGES`, and `CHECKS` with exact outcomes.

---

## 20. [ILLUSTRATIVE] Compact planning output

```text
PLAN
1. Contract/evidence
- Neverlands source and current feature contract

2. File-by-file changes
- path | NEW/MODIFY/DELETE | responsibility

3. Test mapping
- success/failure/edge/auth -> spec paths

4. Documentation
- doc/features/<feature>.md -> create/update after verification

5. Risks/discrepancies
- [IMPL]/[DOC]/[EVIDENCE]

CONFIRM_TO_IMPLEMENT? (yes/no)
```

## 21. [ILLUSTRATIVE] Compact final output

```text
RATIONALE
- ...

CHANGES
- implementation files and behavior
- doc/features/<feature>.md updated after verification
- changelogs/YYYY-MM-DD-short-description.md maintained as the session's one
  living record and finalized after verification
- discrepancies: none

CHECKS
- bundle exec rspec spec/... # exit 0
- bin/feature-doc-audit doc/features/<feature>.md # exit 0
- bin/verify fast # exit 0
```
