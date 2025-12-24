# 0_technical.md — Rails Monolith Flow & Ownership
---
title: WEB-000 — Elselands Rails Monolith Technical Flow
description: Full-stack reference for the core Rails 8.1.1 monolith (auth, jobs, payments, game engine, Hotwire UI). Documents commands, data stores, responsibility map, determinism guarantees, and verification flows.
date: 2025-11-21
---

**Base URL (HTML):** `http://localhost:3000`
**Base URL (API/Hotwire endpoints):** `http://localhost:3000/` (Turbo/Stimulus served from same origin)
**Primary Stack:** Ruby 3.4.4 • Rails 8.1.1 • PostgreSQL 18 • Redis 7+ • Sidekiq 8 • Hotwire • Stripe Ruby 18.x
**Auth:** Devise (`User` model) + Pundit (`UserPolicy`) + Rolify (`Role`)
**UI Contract:** Server-rendered ERB + Turbo Streams + Stimulus controllers (importmap)

> **Implementation stage:** Core monolith foundation (auth, roles, Hotwire skeleton, Sidekiq, feature flags, payments scaffold, deterministic game engine under `app/lib/game/**`).

## Table of Contents
- [General Description](#general-description)
- [Vision & Objectives](#vision--objectives)
- [Rails Monolith Baseline](#rails-monolith-baseline)
- [Core Gems & Services](#core-gems--services)
- [Development & Tooling](#development--tooling)
- [Tech & Runtime Matrix](#tech--runtime-matrix)
- [Environment & Commands](#environment--commands)
- [Primary Flows](#primary-flows)
- [Sequence & Lifecycle Highlights](#sequence--lifecycle-highlights)
- [Environment Matrix](#environment-matrix)
- [Operational Runbook & Troubleshooting](#operational-runbook--troubleshooting)
- [Data Ownership & Migration Roadmap](#data-ownership--migration-roadmap)
- [Hotwire & Stimulus Conventions](#hotwire--stimulus-conventions)
- [Responsible for Implementation Files](#responsible-for-implementation-files)
- [Testing & QA](#testing--qa)
- [Deployment Considerations](#deployment-considerations)
- [Status Codes & Envelopes](#status-codes--envelopes)

---

## General Description
- **Monolith**: Single Rails app (`app/`) delivering HTML via Hotwire. Turbo handles navigation, Frames for partials, Streams for combat/chat/log updates. Stimulus controllers live under `app/javascript/controllers`.
- **Persistence**: PostgreSQL 18 (primary), Redis (cache + Action Cable + Sidekiq). All game state (characters, items, zones, battles) is modeled with ActiveRecord; deterministic calculations live in `app/lib/game/**`.
- **Authentication**: `Devise` handles sessions, password resets, and confirmations. `User` includes rolify for multi-role support; `Pundit` enforces authorization (`ApplicationController` includes `Pundit::Authorization`).
- **Background processing**: `Sidekiq 8` handles combat resolution, chat moderation, scheduled events. `Procfile.dev` runs `web`, `worker`, `cable` processes via `bin/dev` (foreman/overmind).
- **Feature Flags**: `Flipper` with ActiveRecord adapter; `config/initializers/flipper.rb` wires default adapter; flags can be toggled via console/UI to stage features (combat, guilds, housing, etc.).
- **Payments**: `Payments::StripeAdapter` (Stripe Ruby 18.x) scaffolds checkout session creation with `APP_URL` fallback for success/cancel URLs. Purchase ledger lives in `Purchase` model (`db/migrate/20251121084500_create_purchases.rb`).
- **Game Engine**: Deterministic POROs in `app/lib/game/` (systems, formulas, maps, utils) orchestrated by services in `app/services/game/**`. RNG is seeded via `Game::Utils::Rng` to ensure reproducible combat.

---

## Vision & Objectives
- Recreate the classic Elselands.ru gameplay experience while modernizing the Rails stack and operational tooling.
- Maintain authenticity, nostalgia, and community-first mechanics (guilds/clans, shared chat, turn-based combat).
- Target players who prefer strategic, social MMORPGs delivered via fast, reliable server-rendered Hotwire flows.
- Ship iteratively with feature flags so combat, economy, and housing systems can be toggled safely per environment.

---

## Rails Monolith Baseline
- Ruby 3.4.4 + Rails 8.1.1 monolith (no SPA). All gameplay/UI logic flows through the main app, respecting `AGENT.md`, `GUIDE.md`, and `MMO_*` guides.
- PostgreSQL 18 is the source of truth; Redis is used strictly for cache/Action Cable/Sidekiq (separate DBs to avoid contention).
- Hotwire (Turbo + Stimulus) powers every dynamic UI interaction; respond with Turbo Streams instead of custom JS fetch calls.
- Tailwind/utility CSS allowed for styling, but everything renders via ERB/ViewComponents for deterministic server behavior.

---

## Core Gems & Services
- **Authentication/Authorization**: `devise`, `pundit`, `rolify` (future expansions may add `cancancan` per feature spec).
- **Hotwire stack**: `turbo-rails`, `stimulus-rails`, `view_component` for composable server-side UI.
- **Background jobs**: `sidekiq` (8.x) for combat resolution, chat moderation, scheduled events.
- **Feature flags**: `flipper` + `flipper-active_record` ensuring gradual rollout control.
- **Payments**: `stripe` Ruby SDK (18.x) for checkout sessions; ledger recorded via `Purchase`.
- **Tooling & security**: `rubocop-rails-omakase`, `standard`, `brakeman`, `bundler-audit`, `vcr`, `webmock`.

---

## Development & Tooling
- `bin/dev` (foreman/overmind) runs `web`, `worker`, and `cable` processes defined in `Procfile.dev`.
- Linting: `bundle exec rubocop`, `bundle exec standardrb`; security: `bundle exec brakeman`, `bundle exec bundler-audit`.
- Testing stack: RSpec 8 + Capybara + FactoryBot + VCR/WebMock (Hotwire/system specs planned).
- Seeds (`db/seeds.rb`) populate default admin + feature flags; extend seeds when gameplay data lands (classes, items, NPCs, map tiles).
- Contract/Hotwire tests will validate Turbo Stream payloads once UI flows solidify, mirroring `doc/features/0_technical.md` expectations.

---

## Tech & Runtime Matrix
| Tier | Tooling | Notes |
| --- | --- | --- |
| Language | Ruby 3.4.4 | `.ruby-version` + Gemfile |
| Web Framework | Rails 8.1.1 | `config/application.rb` `config.load_defaults 8.1` |
| Database | PostgreSQL 18 | `config/database.yml` w/ `POSTGRES_*` env overrides |
| Cache / PubSub | Redis 7+ | `REDIS_CACHE_URL`, `REDIS_SIDEKIQ_URL`, `REDIS_CABLE_URL` |
| Queue | Sidekiq 8.0.9 | `config/sidekiq.yml` + `config/initializers/sidekiq.rb` |
| Auth | Devise 4.9+, Pundit 2.3+, Rolify 6.x | `User`, `Role`, `ApplicationController` |
| Feature Flags | Flipper 1.3+ | ActiveRecord adapter, `Flipper::UI` optional |
| Payments | Stripe Ruby 18.0.0 | `Payments::StripeAdapter`, `Purchase` |
| Front-end | Hotwire (Turbo 8, Stimulus 3) + Importmap | `app/javascript/application.js` |
| Lint | RuboCop (rails-omakase), StandardRB | `bundle exec rubocop`, `bundle exec standardrb` |
| Tests | RSpec 8.x, Capybara, FactoryBot, VCR/WebMock | `bundle exec rspec` |

---

## Environment & Commands
### Required Env Vars
| Key | Purpose | Default |
| --- | --- | --- |
| `REDIS_CACHE_URL` | Rails cache | `redis://localhost:6380/0` |
| `REDIS_SIDEKIQ_URL` | Sidekiq queues | `redis://localhost:6379/0` |
| `REDIS_CABLE_URL` | Action Cable pub/sub | `redis://localhost:6379/0` |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST` | DB auth | fallback `postgres` / blank / `localhost` |
| `APP_URL` | Base return URL for payments | `http://localhost:3000` |
| `STRIPE_SECRET_KEY` | Stripe API key | none (required for real processing) |
| `SIDEKIQ_CONCURRENCY` | Worker threads override | `5` |

### Setup & Runtime
```bash
bundle install
bin/rails db:prepare
gem install foreman   # if not already installed
bin/dev               # runs web + sidekiq + cable via Procfile.dev
```

### Verification Commands
```bash
bundle exec rspec
bundle exec rubocop
bundle exec standardrb
bundle exec brakeman      # optional security scan
bundle exec bundler-audit # optional CVE scan
```
*(Tests currently require a configured PostgreSQL user/password; without one, `bundle exec rspec` will fail with `fe_sendauth: no password supplied`.)*

---

## Primary Flows
### Authentication & Authorization
1. User hits Devise routes (`/users/sign_in`, `/users/sign_up`).
2. `ApplicationController` enforces `before_action :authenticate_user!`.
3. Authorization via `Pundit` policies (e.g., `UserPolicy#manage_primary_contacts?` for contact management, `Role` via Rolify).
4. Flash messages rendered in `app/views/layouts/application.html.erb` (Turbo-friendly notices/alerts).

### Background Job Flow
1. Controller/Service enqueues `BattleResolutionJob`, `ChatModerationJob`, or `ScheduledEventJob`.
2. Jobs run on Sidekiq 8 using Redis queue connection from `config/initializers/sidekiq.rb`.
3. Jobs log to Rails logger; future state updates will push Turbo Streams to connected clients.

### Payments Flow
1. `Purchase` created with `provider=stripe`, `status=pending`, `amount_cents`, etc.
2. `Payments::StripeAdapter#create_checkout_session` invoked to create Stripe Checkout session (using `APP_URL` for success/cancel).
3. `Purchase` `external_id` stores Stripe session/payment intent; status transitions managed via webhook processing (future work).
4. Ledger query via `Purchase` model; Stripe metadata includes `purchase_id` for traceability.

### Feature Flag Flow
1. `Flipper.add(:combat_system)` etc (seeded in `db/seeds.rb`).
2. Application code checks `Flipper.enabled?(:combat_system, current_user)` before rendering/processing gated features.
3. Flags persisted in DB via `flipper_features`/`flipper_gates` tables.

### Deterministic Combat Flow
1. Controllers/Channels call `Game::Combat::AttackService` or `Game::Combat::SkillExecutor`.
2. Service instantiates `Game::Combat::TurnResolver` with attacker/defender stat blocks.
3. Resolver delegates to `Game::Formulas::DamageFormula`, `CritFormula`, `Game::Systems::EffectStack`, etc., using seeded RNG.
4. Result structure includes `log`, `hp_changes`, `effects` and feeds into jobs/Turbo broadcasts.

---

## Sequence & Lifecycle Highlights
- **Login + Authorization**
  1. User hits Devise session endpoint → `Devise::SessionsController#create` authenticates.
  2. `ApplicationController` `before_action :authenticate_user!` guards downstream controllers.
  3. Pundit policy (e.g., `UserPolicy`) authorizes the requested action; failures handled by `user_not_authorized`.
  4. Successful HTML response renders via Turbo layout; Flash messages stream via `<turbo-frame id="flash">`.
- **Combat Turn Lifecycle**
  1. UI action (Turbo/Stimulus) posts to combat controller (future) → enqueues `BattleResolutionJob`.
  2. Job pulls combatants, instantiates `Game::Combat::AttackService` → `TurnResolver`.
  3. Resolver calculates deterministic damage/effects → persists results/logs.
  4. Turbo Stream broadcast pushes combat log + HP changes to subscribed frames.
- **Payment Checkout**
  1. Controller creates `Purchase` (`pending`) and calls `Payments::StripeAdapter#create_checkout_session`.
  2. Stripe session metadata stores `purchase_id`; response includes session URL.
  3. Webhook (future) updates `Purchase` status (`succeeded`, `failed`, `refunded`).
  4. Dashboard/UI reflects purchase state; feature flags can gate premium content.
- **Background Job & Stream Update**
  1. Domain event enqueues Sidekiq job (`chat`, `scheduled_event`, etc.).
  2. Job uses Redis connection per `config/initializers/sidekiq.rb` and logs to `$stdout`.
  3. On success, job triggers Turbo Stream broadcast or updates DB row consumed by UI.

---

## Environment Matrix
| Aspect | Dev | Staging | Production |
| --- | --- | --- | --- |
| Base URL | `http://localhost:3000` | `https://staging.elselands.example` | `https://play.elselands.example` |
| Rails env | `development` | `staging` | `production` |
| DB | local Postgres 18 (docker/local install) | managed Postgres 18 (shared) | managed Postgres 18 (HA) |
| Redis | single instance for cache/cable/sidekiq | dedicated cache vs queue vs cable URLs | dedicated cache vs queue vs cable URLs |
| Feature flags | mostly enabled for rapid iteration | gated via Flipper (QA toggles) | production toggles per rollout plan |
| Payments | Stripe test key | Stripe test key (per-env webhooks) | Stripe live key |
| Background workers | foreman/overmind via `bin/dev` | Sidekiq deployment (1–2 dynos) | Sidekiq autoscaled workers |
| Monitoring | Rails logs + Sidekiq Web (local) | Sidekiq Web, log drains, optional APM | Centralized logging, APM, alerting (PagerDuty) |

---

## Operational Runbook & Troubleshooting
- **Logs**
  - Rails/Puma: `log/development.log` locally, `$stdout` in containerized/staging/prod.
  - Sidekiq: `log/sidekiq.log` (local) or `$stdout` in deployments; monitor via `/sidekiq` UI (admin-only).
  - Action Cable: `log/cable.log` if `cable` server uses separate logger.
- **Common Issues**
  - `PG::ConnectionBad (no password)`: ensure `POSTGRES_USER/PASSWORD/HOST` env vars set before `db:prepare`/tests.
  - `Redis::CannotConnectError`: verify `REDIS_*_URL` env vars; for dev start `redis-server`.
  - Stripe errors: confirm `STRIPE_SECRET_KEY` present; use test keys outside prod.
  - Flipper mismatch: run `db:seed` or manually create flags via console.
- **Recovery Steps**
  - Restart Sidekiq worker (`bin/jobs`) if jobs stall.
  - Use Rails console to toggle feature flags or requeue stuck jobs (`Sidekiq::RetrySet`).
  - Clear cache with `bin/rails dev:cache` toggle or `Rails.cache.clear` for production incidents (use caution).

---

## Data Ownership & Migration Roadmap
- **Foundational Migrations**
  - `20251121084124_devise_create_users.rb` — base `users` table, Devise columns, primary contacts scaffold.
  - `20251121084129_rolify_create_roles.rb` — `roles` / `users_roles` join table for permissions.
  - `20251121084500_create_purchases.rb` — purchase ledger, provider/status enums, metadata.
- **Gameplay Migrations (planned)**
  - Characters (`characters`, stats JSON), Items (`items`, modifiers), Zones (`zones`, tiles), Battles (`battles`, participants).
  - Each system gets its own migration file per logical change; never combine features in one migration.
- **Data Ownership**
  - `User` team owns authentication/contact data.
  - Gameplay team owns `Character`, `Inventory`, `Battle`, `Zone` tables (future).
  - Economy team owns `Purchase`, `Loot` schemas.
  - When adding columns, update this doc + README to reflect new seeds/commands.

---

## Hotwire & Stimulus Conventions
- **Turbo**
  - Use `<turbo-frame id="resource_name">` around lists/forms; IDs should be predictable (`combat_log`, `flash`, `inventory`).
  - Turbo Stream responses live under `app/views/<resource>/*.turbo_stream.erb`.
- **Stimulus**
  - Controllers reside in `app/javascript/controllers`; naming `thing_controller.js`.
  - Register controllers via importmap `controllers/index.js`.
  - Use `data-controller="combat-log"` etc.; prefer targets/actions instead of manual DOM querying.
- **Components**
  - Shared UI extracted into ViewComponents (base class `ApplicationComponent`).
  - Partial naming: `_form`, `_list`, `_row` corresponding to Turbo frames for easy replacement.

---

## Responsible for Implementation Files
- config:
  - `config/application.rb`, `config/environments/*.rb`, `config/puma.rb`, `config/cable.yml`, `config/database.yml` — Rails defaults (8.1), environment-specific tuning, Puma server settings, Action Cable Redis endpoints, Postgres connection overrides.
- env/proc:
  - `Procfile.dev`, `bin/dev` — Defines `web`, `worker`, `cable` processes; wrappers for foreman/overmind to run full stack locally.
- auth & roles:
  - `app/models/user.rb`, `app/models/role.rb`, `db/migrate/20251121084124_devise_create_users.rb`, `db/migrate/20251121084129_rolify_create_roles.rb`, `app/policies/application_policy.rb`, `app/controllers/application_controller.rb` — Devise modules, rolify association, Pundit base policy, global `authenticate_user!` + `user_not_authorized` rescue.
- feature flags:
  - `config/initializers/flipper.rb`, Flipper migrations — ActiveRecord adapter wiring, seeds establishing default flags.
- background jobs:
  - `app/jobs/application_job.rb`, `app/jobs/battle_resolution_job.rb`, `app/jobs/chat_moderation_job.rb`, `app/jobs/scheduled_event_job.rb`, `config/sidekiq.yml`, `config/initializers/sidekiq.rb`, `bin/jobs` — Base job class, domain jobs, Sidekiq configuration (queues, concurrency), CLI entrypoint for worker process.
- payments:
  - `app/models/purchase.rb`, `db/migrate/20251121084500_create_purchases.rb`, `app/services/payments/stripe_adapter.rb`, `config/initializers/payments.rb` — Purchase ledger schema, status enums, Stripe adapter wiring (API key), checkout session builder.
- game engine (lib):
  - `app/lib/game/systems/*.rb`, `app/lib/game/formulas/*.rb`, `app/lib/game/maps/*.rb`, `app/lib/game/utils/rng.rb` — Deterministic stat/effect/turn systems, damage & crit formulas, grid/tile definitions, RNG seeding helper.
- game services:
  - `app/services/game/combat/*.rb`, `app/services/game/movement/*.rb`, `app/services/game/economy/loot_generator.rb` — Turn resolution, attack orchestration, skill execution, movement validation/pathfinding, loot generation.
  - `app/services/game/combat/skill_executor.rb` — Combat skill execution (damage, heal, buff, debuff, DOT, HOT, AOE, drain, shield).
  - `app/services/game/combat/turn_based_combat_service.rb` — Neverlands-inspired turn-based combat with body-part targeting, action points, and magic slots.
  - `app/services/game/npc/dialogue_service.rb` — NPC dialogue orchestration (quest_giver, vendor, trainer, innkeeper, banker, guard, hostile).
  - `app/services/game/quests/dynamic_quest_generator.rb` — Procedural quest generation (daily, zone, trigger-based).
- combat config:
  - `config/gameplay/combat_actions.yml` — Body-part definitions, attack costs, block costs, magic slots for Neverlands-inspired combat.
- combat ui:
  - `app/views/combat/_battle.html.erb`, `app/views/combat/_nl_*.html.erb` — Turn-based combat UI partials.
  - `app/javascript/controllers/turn_combat_controller.js` — Stimulus controller for combat interactions.
- chat services:
  - `app/services/chat/moderation_service.rb` — Chat moderation heuristics (profanity, spam, harassment detection, penalty escalation).
  - `app/channels/realtime_chat_channel.rb` — WebSocket chat with channel access control.
- hotwire ui:
  - `app/views/layouts/application.html.erb`, `app/assets/stylesheets/application.css`, `app/javascript/application.js`, `app/components/application_component.rb` — Layout with Turbo/Stimulus assets, flash rendering, base styles, ViewComponent base class.
- alignment & faction:
  - `app/models/character.rb` — `ALIGNMENT_TIERS`, `CHAOS_TIERS`, tier calculation methods, emoji accessors.
  - `app/helpers/alignment_helper.rb` — Faction/tier icons, alignment badges, trauma/timeout badges, character nameplates.
  - `app/helpers/arena_helper.rb` — Fight type/kind icons, room type badges, match status tags.
  - `db/migrate/20251127140000_add_chaos_score_to_characters.rb` — Adds `chaos_score` column.
- dashboard:
  - `app/controllers/dashboard_controller.rb`, `app/views/dashboard/show.html.erb` — Authenticated landing view summarizing feature flags and welcome copy.
- docs:
  - `README.md`, `doc/features/*.md`, `doc/flow/0_technical.md` — Tech stack overview, feature specs, monolith flow mapping.

---

## Testing & QA
- **RSpec 8.x**: Models (`spec/models/*.rb`), services (`spec/services/**`), requests/integration (future expansions). Current suite requires a reachable `postgres` user/password.
- **Factories**: `spec/factories/*.rb` (users, roles, purchases). Use `FactoryBot` syntax helpers (included via `spec/rails_helper.rb` + `spec/support/factory_bot.rb`).
- **Mocking HTTP**: `VCR` + `WebMock` preconfigured (`spec/support/vcr.rb`, `webmock.rb`).
- **Lint/Security**: `bundle exec rubocop`, `bundle exec standardrb`, optional `bundle exec brakeman`, `bundle exec bundler-audit`.
- **Seeds**: `db/seeds.rb` creates admin user + default flags; rerunnable/idempotent.
- **Hotwire/System Tests (roadmap)**:
  - Future `spec/system` tests will cover Turbo frame replacements, Stimulus interactions, and feature-flagged UI flows.
  - Use `Capybara`/`cuprite` (or Selenium) for end-to-end coverage once UI solidifies.
- **Combat/Engine Fixtures**:
  - Add factory traits for characters/NPCs when models land; seed deterministic stats to keep RNG reproducible.
  - Consider shared examples for `Game::Formulas` to ensure math parity between specs and production.

Known testing constraint (Nov 21, 2025): `bundle exec rspec` fails without `POSTGRES_PASSWORD` because Postgres auth rejects password-less connections. Provide credentials or set `POSTGRES_PASSWORD` before running specs/`db:prepare`.

---

## Deployment Considerations
- **Docker/Fly/Render** ready: `Dockerfile` + `Procfile` (non-dev) to be configured per target.
- **Logging**: Tagged logging to `$stdout` for container compatibility; `config.log_level` defaults to `ENV["RAILS_LOG_LEVEL"] || "info"`.
- **Action Cable**: Redis adapter across all environments (`config/cable.yml`) and mounted at `/cable` (`config/routes.rb`). Dev can run a separate `cable` process via `Procfile.dev` when desired.
- **Feature Gates**: Use Flipper CLI/UI to roll out combat/guild/housing features gradually; integrate with environment-specific seeds.

---

## Status Codes & Envelopes
- HTML controllers use standard Rails responses (302 on success, 422 on validation failure, 403 on unauthorized).
- JSON/Turbo Streams will follow the same envelope as existing patterns:
  ```json
  {
    "data": {...},
    "meta": {...optional...},
    "errors": {...only on failure...}
  }
  ```
- Validation failures should return HTTP 422 with `errors` keyed by attribute; `ApplicationController#user_not_authorized` renders `403` with `alert` flash for HTML or `{ error: "forbidden" }` JSON/Turbo responses.

---

This document should be updated whenever the core stack, key flows, or ownership map changes (new services, migrations, commands, or deployment targets). Add versions, commands, or responsible files here to keep the monolith reference current.
