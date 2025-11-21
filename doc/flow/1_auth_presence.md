# 1_auth_presence.md — Authentication, Tokens & Presence Flow
---
title: WEB-001 — Account Security, Premium Ledger, Presence Stream
description: Detailed flow for Devise auth lifecycle, Rack::Attack throttling, premium token ledger, and Action Cable presence updates. Includes commands, env requirements, and failure handling.
date: 2025-11-21
---

## Table of Contents
- [Scope](#scope)
- [Architecture Overview](#architecture-overview)
- [Environment & Configuration](#environment--configuration)
- [Login & Session Lifecycle](#login--session-lifecycle)
- [Premium Token Ledger Flow](#premium-token-ledger-flow)
- [Profiles & Characters](#profiles--characters)
- [Privacy Controls](#privacy-controls)
- [Presence & Idle Tracking](#presence--idle-tracking)
- [Moderation & Audit Logging](#moderation--audit-logging)
- [Testing Strategy](#testing-strategy)
- [Troubleshooting & Runbook](#troubleshooting--runbook)

---

## Scope
This document captures the end-to-end flow for:
- Devise authentication with Confirmable, Trackable, Timeoutable modules.
- Rack::Attack throttling on login/password reset endpoints.
- Device/session history persisted via `UserSession`.
- Premium token balance & immutable ledger entries.
- Character & profile management (`User` owns up to 5 `Character` records; public profile endpoint surfaces sanitized view data).
- Privacy controls for chat availability, friend requests, and duel invitations.
- Presence/idle events pushed to clients through `PresenceChannel` and the `idle-tracker` Stimulus controller.
- Audit logging for moderator/GM/admin-sensitive operations tied to premium adjustments.

Use this file whenever modifying auth, presence, or premium token logic.

---

## Architecture Overview
| Concern | Files | Notes |
| --- | --- | --- |
| Devise config | `app/models/user.rb`, `config/initializers/devise.rb` | User includes confirmable/trackable/timeoutable; default timeout 30 minutes. |
| Session tracking | `app/services/auth/user_session_manager.rb`, `app/models/user_session.rb`, `config/initializers/warden_hooks.rb` | Warden hooks call service to persist device info + presence events. |
| Rack::Attack | `config/initializers/rack_attack.rb`, `config/application.rb` | Middleware throttles `/users/sign_in` & `/users/password`. |
| Premium ledger | `app/models/premium_token_ledger_entry.rb`, `app/services/payments/premium_token_ledger.rb`, `app/models/purchase.rb` | Credits on purchase success; debits/adjustments via service entry points. |
| Characters & profiles | `app/models/character.rb`, `app/controllers/public_profiles_controller.rb`, `app/services/users/public_profile.rb`, `config/routes.rb` | Users own up to 5 characters. Public profiles available at `/profiles/:profile_name` (JSON). |
| Privacy toggles | `app/models/user.rb`, `app/models/friendship.rb` | `chat_privacy`, `friend_request_privacy`, `duel_privacy` enums gate inbound interactions; friendships respect receiver preference on create. |
| Presence | `app/channels/presence_channel.rb`, `app/javascript/channels/presence_channel.js`, `app/jobs/session_presence_job.rb`, `app/javascript/controllers/idle_tracker_controller.js` | Broadcast online/idle/offline statuses. |
| Audit logs | `app/models/audit_log.rb`, `app/services/audit_logger.rb` | Records moderator/admin actions (premium adjustments, bans, etc.). |
| Policies | `app/policies/user_policy.rb` | Role-based access (player/moderator/gm/admin). |

---

## Environment & Configuration
| Key | Purpose | Default |
| --- | --- | --- |
| `REDIS_CACHE_URL` | Rack::Attack cache store | `redis://localhost:6379/1` |
| `REDIS_CABLE_URL` | Presence channel pub/sub | `redis://localhost:6379/3` |
| `POSTGRES_*` | DB credentials for Devise + ledger tables | See `.env` |
| `APP_URL` | Device/session metadata + Stripe redirects | `http://localhost:3000` |
| `STRIPE_SECRET_KEY` | Credits token ledger on purchase success | none |

**Commands**
```bash
bundle install
bin/rails db:migrate
bin/rails db:seed      # seeds admin user + default roles/flags
bin/dev                # runs web + sidekiq + cable for presence streams
```

---

## Login & Session Lifecycle
1. **Request**: User submits `/users/sign_in`. Rack::Attack throttles repeated attempts.
2. **Authentication**: Devise authenticates credentials; upon success, Warden triggers `after_set_user`.
3. **Session Tracking**:
   - `Auth::DeviceIdentifier` derives `device_id` via encrypted cookie/session.
   - `Auth::UserSessionManager.login!` upserts `UserSession` with IP, user agent, timestamps.
   - `Presence::Publisher.online!` broadcasts via `PresenceChannel`.
4. **Timeout/Idle**:
   - `idle-tracker` Stimulus pings `/session_ping` every 15s with `active` or `idle`.
   - `SessionPresenceJob` updates `UserSession` status, echoes presence event.
5. **Logout**:
   - Devise logout triggers Warden `before_logout` → `UserSessionManager.logout!` marks offline.

**Data Flow Diagram**
```
Browser -> Devise Controller -> Warden Hooks -> UserSessionManager -> UserSession (DB)
                                                      |
                                                      v
                                          Presence::Publisher -> Action Cable -> JS channel
```

---

## Premium Token Ledger Flow
1. `Purchase` transitions to `succeeded_status`.
2. `Purchase#after_update_commit` calls `Payments::PremiumTokenLedger.credit` with `token_amount`.
3. Ledger service:
   - Locks `User`, increments `premium_tokens_balance`.
   - Creates `PremiumTokenLedgerEntry` (entry_type, delta, balance_after).
   - Calls `AuditLogger` with metadata (actor, delta, reason).
4. Debit/adjust flows call `.debit` / `.adjust` with explicit `actor` (moderator/admin) to enforce auditability.

**Returned Values**
- `Payments::PremiumTokenLedger.*` methods return the created `PremiumTokenLedgerEntry`.
- Errors: raises `InsufficientBalanceError` when debits exceed balance.

---

## Profiles & Characters
### Character lifecycle
- `Character` belongs to `User`, optional `CharacterClass`, and optional `Guild`/`Clan`.
- Creation limit: `User::MAX_CHARACTERS` (currently 5). Validation fires on create.
- Membership inheritance:
  - `before_validation` copies `user.primary_guild` and `user.primary_clan` into the character record.
  - `GuildMembership`/`ClanMembership` `after_commit` callbacks invoke `User#sync_character_memberships!` to keep existing characters in sync when the account joins or leaves an alliance.
- Table: `characters` (name unique, level, experience, metadata JSONB, foreign keys for user/class/guild/clan).

### Public profiles
- `profile_name` is a unique slug derived from the user’s email local part at migration time (and maintained via `before_validation`).
- `PublicProfilesController#show` looks up `User` by `profile_name` (no authentication) and renders `Users::PublicProfile` JSON. The serializer exposes:
  - `id`, `profile_name`, `reputation_score`.
  - Guild & clan snapshots (name, slug, level/prestige).
  - A trimmed housing list (location key, plot type, storage slots).
  - Achievement grants (name, points, granted_at).
- No PII such as `email` is included. Consumers should rely on `profile_name` for public handles.

---

## Privacy Controls
- `User` defines enums for `chat_privacy`, `friend_request_privacy`, and `duel_privacy`. Options: `:everyone`, `:allies_only` (friends or same guild/clan), `:nobody`.
- Helper methods:
  - `allows_chat_from?(other_user)`
  - `allows_friend_request_from?(other_user)`
  - `allows_duel_from?(other_user)`
  - `allied_with?(other_user)` checks friendships (`Friendship.accepted_between`) plus shared guild/clan memberships.
- `Friendship` validation leverages `allows_friend_request_from?` so blocked/limited users can’t be spammed with invites.
- Surface these helpers before opening sockets, queueing duels, or delivering chat invitations.

---

## Presence & Idle Tracking
**Client**
```erb
<body data-controller="idle-tracker"
      data-idle-tracker-ping-url-value="<%= session_ping_path %>">
```
- Controller listens to user activity events (`mousemove`, `keydown`, etc.).
- Uses `navigator.sendBeacon` when available; falls back to `fetch`.

**Server**
- `SessionPingsController#create` enqueues `SessionPresenceJob`.
- Job updates `UserSession` status and publishes `online/idle/offline`.
- `app/javascript/channels/presence_channel.js` dispatches `presence:updated` events for Stimulus consumers (chat lists, guild rosters, etc.).

---

## Moderation & Audit Logging
- Roles seeded via `db/seeds.rb` (player, moderator, gm, admin).
- `UserPolicy` rules:
  - `index?/show?` require moderator+.
  - `update?/audit?` require GM+.
  - `destroy?` requires admin.
- `AuditLogger.log(actor:, action:, target:, metadata:)` persists `AuditLog`.
  - Example: premium adjustment `action: "premium_tokens.adjustment"`.
  - Returns the created `AuditLog` record.

---

## Testing Strategy
| Layer | File | Notes |
| --- | --- | --- |
| Models | `spec/models/user_session_spec.rb`, `spec/models/premium_token_ledger_entry_spec.rb`, `spec/models/user_spec.rb` | Validations, lifecycle helpers. |
| Models (auth adjuncts) | `spec/models/character_spec.rb`, `spec/models/friendship_spec.rb` | Character inheritance/limits, privacy-aware friend requests. |
| Services | `spec/services/payments/premium_token_ledger_spec.rb` | Balance adjustments, error handling. |
| Services (profiles) | `spec/services/users/public_profile_spec.rb` | Ensures serializer hides email and reflects guild/housing state. |
| Requests | `spec/requests/session_pings_spec.rb` | Ensures presence pings enqueue job. |
| Requests (profiles) | `spec/requests/public_profiles_spec.rb` | Public profile endpoint JSON contract. |
| Policies | `spec/policies/user_policy_spec.rb` | Role-based coverage. |

Before running `bundle exec rspec`, ensure Postgres credentials are set (`POSTGRES_PASSWORD`, etc.) or tests will fail with `fe_sendauth: no password supplied`.

---

## Troubleshooting & Runbook
| Symptom | Likely Cause | Fix |
| --- | --- | --- |
| `429 Too Many Requests` on login | Rack::Attack throttle triggered | Wait `Retry-After` seconds or raise limits in `config/initializers/rack_attack.rb`. |
| Presence events stale | `SessionPresenceJob` not running | Ensure Sidekiq `presence` queue is processed (`bin/dev` worker). |
| Token balance negative error | Attempted debit > balance | Catch `Payments::PremiumTokenLedger::InsufficientBalanceError` and surface validation error. |
| Users stuck “offline” after login | Cookies disabled → device_id missing | Investigate `Auth::DeviceIdentifier`; fall back to session-based ID. |
| `PG::ConnectionBad` during tests | Missing DB password/env | Export `POSTGRES_USER/PASSWORD/HOST` before running specs. |
| 403 on friend request | Receiver privacy set to `nobody` | Surface the error copy from `Friendship` validation; prompt sender to use chat/mail instead. |

**Monitoring Hooks**
- Add alerts on Rack::Attack throttle counts (accessible via Rails logs).
- Track `UserSession` table growth; consider pruning or archival job if needed.
- Audit log anomalies should trigger moderator review (future Slack/webhook integration).

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
- hotwire ui:
  - `app/views/layouts/application.html.erb`, `app/assets/stylesheets/application.css`, `app/javascript/application.js`, `app/components/application_component.rb` — Layout with Turbo/Stimulus assets, flash rendering, base styles, ViewComponent base class.
- dashboard:
  - `app/controllers/dashboard_controller.rb`, `app/views/dashboard/show.html.erb` — Authenticated landing view summarizing feature flags and welcome copy.
- docs:
  - `README.md`, `doc/features/*.md`, `doc/flow/0_technical.md` — Tech stack overview, feature specs, monolith flow mapping.

---

Update this flow whenever auth/presence/token behavior changes (new throttle, new ledger entry type, additional presence states, etc.).***

