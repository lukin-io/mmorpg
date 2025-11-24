# 7. Game Overview

## Vision & Objectives
- Deliver an authentic Neverlands revival with modern UX: deterministic combat, Hotwire-first UI, and social depth across guilds, clans, housing, and Live Ops.
- Keep the world reactive—quests, crafting, trades, arenas, and moderation feeds roll up into a unified dashboard so designers can react without redeploying.
- Balance nostalgia with sustainability: premium systems focus on convenience/cosmetics while gameplay pillars remain effort-driven.

## Target Audience & Tone
- Veteran Neverlanders, tactical MMO fans, and community leaders (guild/clan officers, Live Ops hosts) are the core audience.
- Tone: medieval fantasy centered on strategy, faction politics, and resource control rather than twitch reflexes.

## Platform & Technology
- Browser-first Rails + Turbo + Stimulus UI responsive to desktop/mobile Safari & Chrome. No SPA; Turbo Streams power real-time dashboards.
- `/game_overview` renders KPIs via `GameOverviewController#show`, presenters in `app/services/game_overview`, and ViewComponents/partials for cards.
- Sidekiq jobs (`EconomyAnalyticsJob`, tournament recalculations, fraud detectors) keep metrics fresh without blocking user requests.

## KPIs & Analytics
- Returning players, quest completions, crafting throughput, and chat activity feed `GameOverview::SuccessMetricsSnapshot`.
- Monetization health leverages `Purchase`, `Payments::PremiumTokenLedger`, `Economy::WalletService`, and suspicious trade alerts from `Economy::FraudDetector`.
- Community strength is measured via active guild/clan counts (`GuildMembership`, `ClanMembership`), seasonal events (`EventInstance.active`), leaderboard deltas, and moderation volume (`Moderation::Ticket`).
- Snapshots persist in `GameOverviewSnapshot`; presenters compare against the previous entry to highlight spikes/drops directly in the dashboard.

## Responsible for Implementation Files
- **Controllers & Views:** `app/controllers/game_overview_controller.rb`, `app/views/game_overview/show.html.erb`.
- **Models:** `app/models/game_overview_snapshot.rb`, `app/models/quest_assignment.rb`, `app/models/crafting_job.rb`, `app/models/chat_message.rb`, `app/models/guild_membership.rb`, `app/models/clan_membership.rb`, `app/models/event_instance.rb`, `app/models/purchase.rb`, `app/models/moderation/ticket.rb`.
- **Services & Jobs:** `app/services/game_overview/overview_presenter.rb`, `app/services/game_overview/success_metrics_snapshot.rb`, `app/jobs/economy_analytics_job.rb`, `app/services/economy/analytics_reporter.rb`, `app/services/economy/fraud_detector.rb`.
- **Docs:** `README.md` (economy/overview section), `doc/flow/0_technical.md`, this file.
