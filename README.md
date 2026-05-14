# Neverlands-Inspired Rails MMORPG

This is a server-rendered Rails MMORPG inspired by Neverlands. The project is in
active development, and the design target is the Neverlands-style browser game
loop: compact UI, server-authoritative actions, tile-local context, movement
timers, chat/social presence, and tactical turn-based play.

## Source Of Truth

Use these files first:

- `doc/design/gdd.md` - product and mechanics source of truth.
- `doc/design/launch_mvp_plan.md` - active launch scope.
- `doc/design/features/` and `doc/design/areas/` - canonical mechanics and
  play spaces.
- `doc/design/reference/neverlands.md` - how live Neverlands observations map
  into this game's design language.
- `doc/flow/neverlands_live_movement.md` - live Neverlands movement observation
  from 2026-05-09.
- `doc/flow/neverlands_movement_codebase_analysis.md` - current movement gaps
  and implementation plan.

Non-Neverlands docs are legacy and should be removed, not treated as alternate
guidance.

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
world action-offer model documented in `doc/design/features/movement.md`.

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
