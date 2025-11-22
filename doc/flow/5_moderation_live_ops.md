# 5_moderation_live_ops.md — Moderation, Safety, and Live Ops Flow

## Overview
- Moderation reporting funnels (`Moderation::ReportIntake`) normalize evidence from chat, profiles, combat logs, and NPC magistrates into `moderation_tickets`.
- Action Cable (Turbo Streams + `Moderation::TicketsChannel`) keeps the moderator queue live while `Moderation::DashboardPresenter` computes widget metrics.
- Live Ops tooling lets GMs spawn NPCs, trigger/rollback events, seed rewards, and escalate anomalies via Discord/Telegram webhooks.

## Reporting & Ticket Flow
- Entry points:
  - Chat inline button → `ChatReportsController#create` → `Moderation::ReportIntake`.
  - Player profile HTML view → `Moderation::ReportsController#new`.
  - Combat log viewer (`CombatLogsController#show`) surfaces “Report” links per round.
  - NPC magistrates (`NpcReportsController#create`) reuse `Game::Moderation::NpcIntake` which now delegates to `Moderation::ReportIntake`.
- `Moderation::Ticket` stores reporter, subject, category, source, evidence, metadata, Action Cable broadcast state, and automatically issues zone surge anomaly jobs.

## Enforcement Toolkit
- Moderation UI lives under `Admin::Moderation::TicketsController` with Turbo-updating queue + ticket detail view.
- `Moderation::PenaltyService` issues warnings, mutes (via `ChatModerationAction`), trade locks (`users.trade_locked_until`), temp/perma bans (`users.suspended_until`), premium refunds (`Payments::PremiumTokenLedger.adjust`), and quest adjustments (audit log only) plus structured logging.
- Actions captured as `Moderation::Action` rows; `Moderation::PenaltyNotifier` fans out inbox/email/webhook notifications.
- Detectors (`Moderation::Detectors::HealingExploit`) flag suspicious trauma/healing usage and enqueue tickets.

## Live Ops & Events Oversight
- `LiveOps::Event` + `Admin::LiveOps::EventsController` accept GM commands; `LiveOps::CommandRunner` executes spawn/trigger/reward/pause/rollback/escalation instructions.
- Scheduled jobs `LiveOps::ArenaMonitorJob` + `LiveOps::ClanWarMonitorJob` watch tournaments/clan wars for anomalies and open tickets when thresholds exceeded.
- `LiveOps::StandingRollback` resets arena/clan states when cheating confirmed.

## Transparency, Appeals, & Player Communication
- `Moderation::TicketStatusNotifierJob` mirrors status changes into in-game mail (`MailMessage`) and emails (`ModerationMailer#status_update`); `Moderation::PenaltyNotifier` handles penalty-specific notifications.
- Players submit appeals via `Moderation::AppealsController` + `Moderation::AppealWorkflow`, which enforces SLAs and reopens tickets when overturned.
- Admin appeal review flows through `Admin::Moderation::AppealsController`.

## Instrumentation & Alerting
- `Moderation::Instrumentation` emits structured logs + StatsD metrics for ticket lifecycle and live ops commands.
- `Moderation::AnomalyAlertJob` detects zone spikes and uses `Moderation::WebhookDispatcher` (Discord/Telegram) for urgent escalations.
- Dashboard widgets show report volume, resolution time, and repeat offenders (per `Moderation::DashboardPresenter`).

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
- hotwire ui:
  - `app/views/layouts/application.html.erb`, `app/assets/stylesheets/application.css`, `app/javascript/application.js`, `app/components/application_component.rb` — Layout with Turbo/Stimulus assets, flash rendering, base styles, ViewComponent base class.
- dashboard:
  - `app/controllers/dashboard_controller.rb`, `app/views/dashboard/show.html.erb` — Authenticated landing view summarizing feature flags and welcome copy.
- docs:
  - `README.md`, `doc/features/*.md`, `doc/flow/0_technical.md` — Tech stack overview, feature specs, monolith flow mapping.

