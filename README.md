# Neverlands-Inspired Rails MMORPG

This is a server-rendered Rails MMORPG inspired by Neverlands. The project is in
active development, and the design target is the Neverlands-style browser game
loop: compact UI, server-authoritative actions, tile-local context, movement
timers, chat/social presence, and tactical turn-based play.

## Source Of Truth

Use these files first:

- `doc/design/gdd.md` - product and mechanics source of truth.
- `doc/engineering/rails_guide.md` - active Rails engineering guide.
- `doc/engineering/gameplay_architecture.md` - active gameplay architecture guide.
- `doc/flow/neverlands_live_movement.md` - live Neverlands movement observation
  from 2026-05-09.
- `doc/flow/neverlands_movement_codebase_analysis.md` - current movement gaps
  and implementation plan.

Older feature lists and generated planning docs are not canonical. If they
conflict with the GDD or the live movement observation, update or delete them.

## Current Movement Direction

The target movement model is:

1. Server returns reachable destination tiles.
2. Each destination has target coordinates and a short-lived token.
3. Browser can click only server-offered destinations.
4. Move request submits target coordinates, expected travel time, and token.
5. Server accepts the move and stores an in-progress travel state.
6. UI disables movement/actions and shows a timer while travelling.
7. Reload resumes movement from server state.
8. Completion finalizes position and returns next tiles/buttons.

Current movement work should continue from the DB-backed movement command and
world action-offer model documented in `doc/design/features/movement.md` and
`doc/engineering/gameplay_architecture.md`.

## Stack

- Ruby on Rails monolith
- Hotwire: Turbo + Stimulus
- PostgreSQL
- Redis / Sidekiq for background work
- Devise + Pundit + Rolify
- RSpec + Capybara

## Development

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Run the app:

```bash
bin/dev
```

Run focused tests:

```bash
bundle exec rspec spec/services/game/movement spec/requests/world_spec.rb spec/views/world
```

## Documentation Rule

Do not add broad roadmap docs or feature lists unless they directly support the
Neverlands-style GDD. Prefer one canonical design doc plus small implementation
notes tied to code that exists.
