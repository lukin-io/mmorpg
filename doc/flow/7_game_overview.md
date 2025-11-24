# 7. Game Overview Landing Page Flow

## Overview
- Implements `doc/features/7_game_overview.md`, exposing the product vision, personas, genre/tone, platform stack, and success metrics through a public `GET /game_overview` route.
- Mirrors the markdown copy through `config/game_overview.yml` so the UI stays in sync with the spec while remaining server-rendered via Hotwire.
- Live KPIs (retention, community, monetization balance) are sourced from deterministic queries and cached snapshots to avoid recomputing heavy aggregates on every request.

## Sections & Content Pipeline
- `config/game_overview.yml` stores hero text, bullet lists, persona cards, and metric definitions. Loading happens through `GameOverview::SectionCatalog`, keeping copy changes data-driven.
- `GameOverview::OverviewPresenter` merges static copy with runtime data:
  - Hero + sections delivered verbatim from the catalog.
  - Platform/technology cards hydrate dynamic values (Rails/Ruby versions, queue layout).
  - Success metrics use the latest persisted snapshot or a cached ephemeral one when none exist.
- Views live under `app/views/game_overview/*`:
  - `_hero`, `_vision`, `_target_audience`, `_genre_tone`, `_platform_technology` render declarative content.
  - `_success_metrics` wraps a Turbo Frame with Stimulus-powered refresh/polling.
  - `_metric_card` handles consistent formatting + delta badges through helper methods.

## Metrics & Snapshot Engine
- `GameOverview::SuccessMetricsSnapshot` aggregates:
  - Retention: distinct users participating in quests, crafting jobs, or chat over 24h/7d windows.
  - Community: chat senders, active guilds/clans (membership updates), active seasonal events.
  - Monetization: succeeded purchases, average premium tokens per payer, whale-share percentage (top 5% spenders).
- `GameOverviewSnapshot` persists the rollups (with `captured_at`) for historical deltas.
- `GameOverview::SnapshotJob` (queued on `low`) provides a nightly/cron entry point to store another snapshot. Until a scheduler is configured, devs can enqueue it manually.
- The presenter falls back to a cached in-memory snapshot (`Rails.cache`) so stakeholders always see fresh-enough data even before the first persisted row exists.

## Controllers & Frontend
- `GameOverviewController#show`
  - Skips authentication/device hooks so the page is public.
  - Responds to HTML + Turbo Stream; Turbo requests only re-render the metrics frame via `success_metrics_grid`.
- `success-metrics` Stimulus controller polls every 60s (and exposes a manual Refresh button) by fetching Turbo Streams.
- Helper methods in `GameOverviewHelper` format counts/percents and annotate deltas with positive/negative badges.

## Testing & Verification
- Request spec (`spec/requests/game_overview_spec.rb`) keeps the route public and Turbo friendly.
- Service specs ensure catalog loading + KPI math behave deterministically.
- Job spec verifies snapshot persistence; system spec asserts that critical sections render via the browser stack.
- RSpec + RuboCop remain the regression gates; run `bundle exec rspec` + `bundle exec rubocop` after migrations.

---

## Responsible for Implementation Files
- models:
  - `app/models/game_overview_snapshot.rb`
- services:
  - `app/services/game_overview/section_catalog.rb`, `app/services/game_overview/overview_presenter.rb`, `app/services/game_overview/success_metrics_snapshot.rb`
- jobs:
  - `app/jobs/game_overview/snapshot_job.rb`
- controllers:
  - `app/controllers/game_overview_controller.rb`
- helpers & frontend:
  - `app/helpers/game_overview_helper.rb`, `app/javascript/controllers/success_metrics_controller.js`, `app/views/game_overview/*`
- routes & config:
  - `config/routes.rb`, `config/game_overview.yml`
- database:
  - `db/migrate/20251124120000_create_game_overview_snapshots.rb`
- docs & tests:
  - `doc/flow/7_game_overview.md`, `README.md`, `changelog.md`, `spec/requests/game_overview_spec.rb`, `spec/services/game_overview/*`, `spec/jobs/game_overview/snapshot_job_spec.rb`, `spec/system/game_overview_spec.rb`, `spec/factories/game_overview_snapshots.rb`

