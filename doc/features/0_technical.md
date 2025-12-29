# 0. Technical Foundation

## Stack Baseline
- Ruby **3.4.4** + Rails **8.1.1** monolith configured in `config/application.rb`, `.ruby-version`, and the `Gemfile`. Hotwire (`turbo-rails`, `stimulus-rails`) powers every interactive screen; no SPA layer.
- PostgreSQL 18 is the source of truth (`config/database.yml`). Redis backs cache, Action Cable, and Sidekiq queues; Action Cable is mounted at `/cable` (`config/routes.rb`) and env vars such as `REDIS_CACHE_URL`/`REDIS_SIDEKIQ_URL` are documented in the README.
- Processes are orchestrated via `Procfile.dev` + `bin/dev`, which boot Puma (`web`), Sidekiq (`worker`), and Action Cable (`cable`) together.

## Core Services & Libraries
- **Authentication/Authorization:** Devise + Pundit + Rolify (`app/models/user.rb`, `app/policies/**/*`). Rack::Attack (`config/initializers/rack_attack.rb`) protects login/password endpoints.
- **Realtime/UI:** Turbo Streams and Stimulus controllers live in `app/javascript/controllers`; server-side rendering uses ERB and ViewComponent.
- **Background jobs:** Sidekiq is configured via `config/sidekiq.yml` and `config/initializers/sidekiq.rb`; domain jobs (combat, crafting, economy analytics) live under `app/jobs`.
- **Payments/Premium:** Stripe integration (`app/services/payments/stripe_adapter.rb`) and the premium token ledger (`Payments::PremiumTokenLedger`) ensure purchases stay auditable.
- **Feature Flags:** Flipper (`config/initializers/flipper.rb`) gates combat, housing, and event systems.

## Testing & QA
- RSpec 8 (`spec/**/*`) with FactoryBot + Faker for fixtures, WebMock/VCR for HTTP isolation, and Capybara for Hotwire UI specs. Test helpers live in `spec/rails_helper.rb`, `spec/spec_helper.rb`, and `spec/support/**/*`.
- Contract coverage for deterministic gameplay exists in `spec/services/game/**/*` (turn resolver, movement) and `spec/services/economy/**/*` (wallet, analytics, fraud detection).
- Lint/security: `bundle exec rubocop`, `bundle exec standardrb`, `bundle exec brakeman`, and `bundle exec bundler-audit` are run before shipping (see `AGENT.md` expectations).

## Deployment & Ops
- Dockerfile + `Procfile` enable container-based deploys (Fly.io/Render/Heroku compatible). `config/puma.rb` and `config/cable.yml` are tuned for single-tenant environments but respect ENV overrides.
- Observability hooks:
  - `AuditLogger` writes to `audit_logs` for privileged actions (premium adjustments, GM overrides).
  - Sidekiq Web UI is mounted at `/sidekiq` behind admin auth.
  - Moderation/event alerts integrate with Discord through webhook services (`app/services/moderation/webhook_dispatcher.rb`).
- Feature flags and maintenance tasks are seeded via `db/seeds.rb` so every environment matches the expected baseline.

## Responsible for Implementation Files
- **Configuration:** `config/application.rb`, `config/environments/*.rb`, `config/database.yml`, `config/cable.yml`, `config/puma.rb`, `Procfile.dev`, `bin/dev`.
- **Initializers & Infra:** `config/initializers/*` (Devise, Flipper, Rack::Attack, Sidekiq), `config/sidekiq.yml`.
- **Tooling & Docs:** `README.md` (env vars + setup), `doc/flow/0_technical.md` (in-depth flow), `AGENT.md`, `GUIDE.md`, `MMO_ADDITIONAL_GUIDE.md`.
- **Jobs & Observability:** `app/jobs/*`, `app/services/audit_logger.rb`, `app/services/moderation/webhook_dispatcher.rb`.
