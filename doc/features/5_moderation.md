# 5. Moderation, Safety, and Live Ops

## Goals & Principles
- Protect the nostalgia-driven Neverlands community without sacrificing trust: fast GM tooling, transparent communications, and auditable actions (`AuditLogger`, `audit_logs` table).
- All punitive actions (ban/mute/trade-lock/refund) are gated by Pundit policies and tied to a `Moderation::Ticket`, ensuring accountability.

## Reporting & Ticket Flow
- Inline report entry points (chat lines, player profiles, NPC magistrates) submit payloads to `Moderation::ReportIntake`, which sanitizes evidence and creates `Moderation::Ticket` rows.
- Tickets reference `Moderation::Action`, `Moderation::Appeal`, and optional chat/NPC reports for traceability; Turbo streams update moderator dashboards (`app/services/moderation/dashboard_presenter.rb`).
- Evidence: chat excerpts, screenshot URLs, combat replay IDs, zone keys. `Moderation::Instrumentation` tracks volume/response times for analytics.

## Enforcement Toolkit
- `Moderation::PenaltyService` issues warnings, mutes, bans, trade locks, and premium reimbursements while logging via `AuditLogger`.
- Automated detectors raise tickets without manual reports:
  - `Moderation::Detectors::HealingExploit` watches trauma reductions.
  - `Economy::FraudDetector` monitors suspicious trades and emits `EconomyAlert` rows for GM follow-up.
- GM/admin panels (namespaced controllers under `app/controllers/admin/moderation/*`) expose ticket queues, actions, and appeal workflows.

## Live Ops & Event Oversight
- Live Ops commands (in `app/services/live_ops` and `app/controllers/admin/live_ops/events_controller.rb`) let staff spawn/disable quests, pause arenas, or compensate players after outages.
- Scheduled jobs (e.g., `EconomyAnalyticsJob`, tournament recalculations) surface anomalies early; moderators can roll back standings if cheating is confirmed.

## Transparency & Player Communication
- Penalties notify players via in-game mail (`MailMessage`) and email, including reason/duration. Appeals use `Moderation::Appeal` + `Moderation::AppealsController`.
- Policy docs (this file + `README.md` excerpts) are linked from the UI; penalty history is visible to account owners through audit logs in the profile modal.
- Webhooks (`app/services/moderation/webhook_dispatcher.rb`) publish high-severity actions to Discord/Telegram for rapid team response.

## Responsible for Implementation Files
- **Models:** `app/models/moderation/ticket.rb`, `app/models/moderation/action.rb`, `app/models/moderation/appeal.rb`, `app/models/chat_report.rb`, `app/models/economy_alert.rb`, `app/models/audit_log.rb`.
- **Services:** `app/services/moderation/report_intake.rb`, `app/services/moderation/penalty_service.rb`, `app/services/moderation/detectors/*.rb`, `app/services/economy/fraud_detector.rb`, `app/services/audit_logger.rb`, `app/services/moderation/webhook_dispatcher.rb`, `app/services/moderation/dashboard_presenter.rb`.
- **Controllers:** `app/controllers/moderation/reports_controller.rb`, `app/controllers/moderation/tickets_controller.rb`, `app/controllers/admin/moderation/tickets_controller.rb`, `app/controllers/admin/moderation/actions_controller.rb`, `app/controllers/admin/moderation/appeals_controller.rb`.
- **Jobs & Alerts:** `app/jobs/economy_analytics_job.rb` (fraud detection), Sidekiq worker configs, Discord/Telegram webhook integrations.
