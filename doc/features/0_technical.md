# 0. Technical Foundation

## Vision & Objectives
- Recreate the classic Neverlands.ru gameplay loop while modernizing the stack.
- Maintain authenticity, nostalgia, and strong community-driven systems.
- Target fans of traditional medieval MMORPGs seeking social, strategic play.

## Rails Monolith Baseline
- Ruby 3.x + Rails 7.x monolith as mandated by `AGENT.md` / `GUIDE.md`.
- Postgres as the primary datastore; Redis backing Action Cable, cache, and Sidekiq jobs.
- Hotwire (Turbo + Stimulus) for all reactive UI; no SPA framework.
- Tailwind- or Bootstrap-style utility classes allowed, but keep HTML server-rendered via Turbo Streams.

## Core Gems & Services
- `devise` for authentication (see `1_auth.md`), `pundit`/`cancancan` for authorization, `rolify` for roles.
- `stimulus-rails`, `turbo-rails`, `view_component` for composable UI.
- Background processing: `sidekiq` (battle resolution, chat moderation, scheduled events).
- Payments/premium items: integrate with Stripe or YooMoney adapters later, store purchase ledger in Postgres.

## Testing & QA
- RSpec + Capybara + FactoryBot for model, service, and system specs.
- Contract tests for Hotwire stream updates to ensure Turbo Frames broadcast expected payloads.
- VCR/webmock for external payment APIs.

## Development & Tooling
- Standard Rails bin/dev with foreman-style Procfile (web, worker, cable).
- RuboCop + StandardRB for linting; Brakeman for security scans.
- Seed data covering classes, items, NPCs, map tiles to speed iteration.

## Deployment Considerations
- Containerized via Dockerfile already present; target Fly.io/Render/Heroku-compatible release.
- Separate Redis instance for Action Cable vs Sidekiq to avoid noisy neighbors.
- Feature flags (Flipper) to gate incremental delivery of systems (combat, guilds, housing, etc.).
