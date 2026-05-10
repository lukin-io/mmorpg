# Rails Engineering Guide

This is the active engineering guide for the Rails application.

Game design still starts in `doc/design/gdd.md`. This guide explains how to
implement that design in Rails without drifting into speculative architecture.

## Authority

Use this order when documents disagree:

1. `doc/design/gdd.md` and the feature/area design docs define player-facing
   behavior.
2. `doc/engineering/gameplay_architecture.md` defines gameplay code structure.
3. This guide defines general Rails implementation standards.
4. `doc/flow/*` and `doc/features/*` are supporting references only.

## Core Rules

- Prefer Rails conventions before custom framework code.
- Keep implementation simple until real complexity appears.
- Do not add speculative systems, flags, tables, or abstractions.
- Keep controllers thin: authentication, authorization, parameter handling,
  orchestration, and response rendering.
- Put gameplay rules in small PORO services under `app/services/game/` or pure
  helpers under `app/lib/game/` when they do not need persistence.
- Keep models responsible for persistence invariants, associations, scopes, and
  small domain helpers.
- Use dependency injection for services that need time, randomness, or external
  collaborators in specs.
- Add comments only where code is not self-explanatory.

## Project Layout

Use standard Rails layout unless a feature already has a local convention:

```text
app/models/                  ActiveRecord state and invariants
app/controllers/             HTTP orchestration
app/views/                   Server-rendered UI
app/javascript/controllers/  Stimulus behavior
app/services/                Application and domain services
app/services/game/           Gameplay orchestration and commands
app/lib/game/                Pure formulas and small deterministic helpers
app/jobs/                    Async work
spec/                        RSpec coverage
doc/design/                  Game design source of truth
doc/engineering/             Current implementation guidance
```

## Rails Style

- Use `# frozen_string_literal: true` in Ruby files.
- Prefer clear method names and short methods over premature abstraction.
- Use guard clauses to reduce nesting.
- Prefer Rails helpers and path helpers in views.
- Avoid raw SQL unless ActiveRecord cannot express the query clearly.
- Add database constraints for hard invariants: `null: false`, foreign keys,
  unique indexes, and useful composite indexes.
- Keep migrations reversible where practical.

## Hotwire And Frontend

- Build HTML-first views.
- Use Turbo Frames and Turbo Streams for server-driven updates.
- Use Stimulus for local behavior, not as a separate application layer.
- Keep browser state presentational. The server decides available gameplay
  actions, destinations, and mutating commands.
- Avoid inline scripts. Put behavior in `app/javascript/controllers`.

## Services And POROs

Introduce a service object when the behavior spans multiple models, commands,
or side effects. A good service has:

- one public entry point, usually `.call(...)` or an explicit instance method;
- narrow constructor dependencies;
- explicit return values or documented raised errors;
- focused specs.

Do not create a service just to move one obvious ActiveRecord call out of a
controller or model.

## Background Jobs

- Jobs must be idempotent.
- Pass IDs, not loaded records.
- Re-check current DB state inside the job before mutating anything.
- Keep retry behavior explicit for player-visible actions.

## Testing

This project uses RSpec.

Cover new behavior at the lowest useful layer:

| Change | Required Coverage |
| --- | --- |
| Model invariant | model spec |
| Service/game rule | service spec with deterministic inputs |
| Controller/route behavior | request spec |
| Turbo/Stimulus/player workflow | system spec |
| Authorization rule | request or policy spec |

Every meaningful feature should cover:

- success path;
- invalid input or unavailable action;
- edge case or nil/boundary state;
- authorization or ownership case where relevant.

Use `ActiveSupport::Testing::TimeHelpers` for timers and expiry. Seed randomness
where a rule depends on RNG. Never let CI hit real external services.

## Verification

Run the smallest useful subset while developing, then run the broader checks
before handing off a larger change.

Current CI style gate:

```bash
bin/rubocop -f simple
```

Focused specs:

```bash
bundle exec rspec spec/path/to/file_spec.rb
```

Parallel non-system specs:

```bash
RAILS_ENV=test bundle exec rake "parallel:create[4]"
RAILS_ENV=test bundle exec rake "parallel:load_schema[4]"
bundle exec parallel_test spec/ -n 4 --type rspec --exclude-pattern "spec/system/**/*_spec.rb"
```

System specs:

```bash
bundle exec rspec spec/system
```

Security checks:

```bash
bundle exec brakeman --quiet --no-pager
bin/bundler-audit check --update
bin/importmap audit
```

StandardRB remains in the bundle for historical/local use, but CI's canonical
style gate is RuboCop Omakase through `bin/rubocop`. Do not document StandardRB
as the primary linter unless CI is changed at the same time.

## Definition Of Done

A change is done when:

- implementation follows the current GDD and feature/area docs;
- code is Rails-way, small, and easy to test;
- player actions that mutate world state are server-authoritative;
- relevant specs pass;
- lint and security checks have been run as appropriate;
- affected design or engineering docs are updated.
