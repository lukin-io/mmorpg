# Neverlands-Based Rails MMORPG

This is a server-rendered Rails MMORPG based on Neverlands. The project is in
active development. The target is the observed Neverlands browser-game loop:
compact UI, server-authoritative actions, tile-local context, movement timers,
chat/social presence, and tactical turn-based play.

## Source of truth

Neverlands live behavior and preserved Neverlands material are the only
game-design authority. Generic RPG conventions and engineering references from
other projects are not alternate product sources.

Start with `doc/DOCUMENTATION.md`, then follow its domain-first chain:

1. `doc/domains/README.md` selects the game domain.
2. `doc/design/reference/**` records sanitized Neverlands evidence and gaps.
3. `doc/design/gdd.md`, `doc/design/areas/**`, and
   `doc/design/features/**` normalize adopted design without claiming it ships.
4. `doc/design/launch_mvp_plan.md` owns the current MVP/parity boundary.
5. `doc/features/**` describes verified local behavior and responsible files,
   or an explicit `NOT_IMPLEMENTED` gap.
6. Code, configuration, schema, and specs show current runtime behavior.

When layers disagree, classify the mismatch as `[EVIDENCE]`, `[IMPL]`, or
`[DOC]` under `AGENTS.md` and correct the layer that owns the fact.

## Current movement direction

The target movement model is:

1. The server returns reachable destination tiles.
2. Each destination has target coordinates and a short-lived token.
3. The browser can click only server-offered destinations.
4. The move request submits target coordinates, expected travel time, and token.
5. The server accepts the move and stores in-progress travel state.
6. The UI disables movement/actions and shows a timer while travelling.
7. Reload resumes movement from server state.
8. Completion finalizes position and returns the next actions.

Continue movement work from the DB-backed movement command and world
action-offer model documented in `doc/design/features/movement.md`.

## Stack

- Ruby on Rails monolith
- Hotwire: Turbo + Stimulus
- PostgreSQL
- Redis / Sidekiq for background work
- Devise + Pundit + Rolify
- RSpec + Capybara

## Development

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Run a focused example:

```bash
bundle exec rspec spec/services/game/movement spec/requests/world_spec.rb spec/views/world
```

## Agentic engineering workflow

Every authorized implementation, bug fix, behavior change, refactor, migration,
or executable tooling change automatically follows the workflow in `AGENTS.md`.
No magic prompt, YAML receipt, profile list, or conversation changelog is
needed. A request such as “implement inventory sorting using `AGENTS.md`” is
enough.

The workflow connects four things:

```text
Neverlands evidence/design
  -> smallest Rails/Hotwire implementation
  -> applicable focused tests
  -> synchronized canonical docs + proportional verification
```

### What each file owns

| File or path | Responsibility |
|---|---|
| `AGENTS.md` | Normative workflow, authority, safety, testing, verification, and handoff rules. |
| `doc/DOCUMENTATION.md` | Documentation truth layers and evidence-to-runtime routing. |
| `doc/domains/**` | Domain-first map to evidence, design, MVP status, feature owner, and important code. |
| `doc/RUBY_ON_RAILS_GUIDE.md` | Technical guidance for Rails way, SRP/DI, PORO/KISS, justified services, Hotwire, persistence, async, security, and performance. |
| `doc/features/**` | Verified shipped contracts and explicit missing-runtime records. |
| `doc/features/FEATURE_TEMPLATE.md` | Lean eight-section template for a new shipped handbook. |
| `doc/features/NOT_IMPLEMENTED_TEMPLATE.md` | Lean evidence-backed record for a known runtime gap. |
| `bin/verify` | Read-only local verification profiles. |
| `bin/feature-doc-audit` | Objective feature metadata, ownership/path, template-placeholder, duplicate-title, and false-gap-claim checks. |
| `bin/documentation-architecture-audit` | Domain registry, canonical link/path, alias, and evidence-placeholder checks. |
| `.github/workflows/ci.yml` | Independent documentation, security, lint, non-system, and system-test jobs. |
| `changelogs/CHANGELOG_TEMPLATE.md` | Optional release/change/architecture note; never workflow state. |

### Automatic implementation flow

1. Read the relevant domain, Neverlands evidence, normalized design, MVP scope,
   current handbook, implementation owners, and specs.
2. Resolve `[EVIDENCE]` before inventing behavior; identify security,
   persistence, concurrency, Hotwire, and operational risks that actually apply.
3. Extend the smallest existing Rails/domain owner. Prefer Rails conventions,
   cohesive objects, practical dependency injection, PORO/KISS, and justified
   services.
4. Add applicable success, failure, edge/boundary, authorization, and
   retry/concurrency coverage while implementing.
5. Review the stable diff against the relevant Rails-guide questions.
6. Update only canonical documents whose owned truth changed.
7. Run proportional verification and report exact outcomes.

A planning-first request stops after evidence extraction, repository scan, and a
file-by-file plan. Once the user approves it, implementation continues without a
second planning ceremony.

### Verification commands

```bash
# Focused iteration
bundle exec rspec spec/path/to/changed_spec.rb
bin/rubocop app/path/to/changed.rb spec/path/to/changed_spec.rb

# Documentation integrity
bin/feature-doc-audit doc/features/world.md
bin/verify docs

# Ordinary runtime completion
bin/verify fast

# Arena/formula-focused work
bin/verify combat

# Broad/high-risk runtime, dependencies, material migrations, or release checks
bin/verify full
```

`bin/verify` is read-only and runs without editing metadata into a `ready` or
`complete` state. CI repeats the real verification layers independently.

### Examples

Feature implementation:

> “Implement the observed Neverlands chat event using `AGENTS.md`.”

The agent follows the Social domain chain, preserves server authority, extends
the existing chat/event owners, adds focused request/service/system coverage,
updates the shipped handbook after verification, then runs the proportional
completion profile.

High-value bug fix:

> “Fix partial inventory loot persistence using `AGENTS.md`.”

The agent identifies the transaction and capacity boundary, writes a regression
for partial fit and retry behavior, fixes the smallest authoritative service or
model owner, reviews atomicity, and uses `bin/verify full` when the final risk is
broad enough.

Evidence gap:

> “Add Neverlands quest behavior.”

If the source flow is not sufficiently observed, the agent reports
`[EVIDENCE]` and updates or follows the gap record instead of inventing generic
Quest rules.

Documentation/tooling:

> “Simplify the feature handbook template.”

The agent updates the canonical template, onboarding/architecture summaries,
objective audit and focused audit specs, then runs read-only lint and
`bin/verify docs`. A full application suite is not automatic unless the change
can affect runtime verification or the user requests it.

### Documentation synchronization

Documentation is part of implementation, but updates are ownership-based:

- evidence changes update the observation/source summary;
- game rules or MVP scope changes update design;
- verified runtime behavior/ownership changes update its feature handbook;
- workflow/tool changes update `AGENTS.md` and the directly affected onboarding;
- operational guides are added only for real cross-feature procedures.

Do not touch every document containing the same phrase. Historical records stay
historical, and optional change notes are created only when a release, rollout,
user request, or durable architectural decision benefits from one.

### Technical acceptance in one paragraph

Prefer conventional Rails and Hotwire boundaries. Keep controllers thin,
persistent invariants in models/database constraints, valuable multi-record
transitions atomic and retry-safe, authorization server-side, reads bounded, and
Stimulus presentation-only. Introduce a service, query, job, cache, or operator
tool only for a concrete responsibility. Tests are selected by changed behavior,
not by a requirement to create every possible spec layer.
