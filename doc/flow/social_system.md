# Social Systems Flow

## Overview

Social features tie together chat, friends/presence, guild tooling, parties, and arena spectators:

- **Chat & Messaging:** `Chat::MessageDispatcher` routes through `Moderation::ChatPipeline` which applies spam throttling, mutes, and privacy/ignore gates before persisting. Channel scopes cover global/local/guild/clan/party/arena/whisper, inline reports enrich `ChatReport#source_context`, and `MailMessages::SystemNotifier` backs offline/system mail with item or currency attachments. Turbo Stream broadcasts render outside a request context, so broadcast partials must be warden-safe (e.g., `ChatMessagesHelper#safe_current_user`).
- **Friends & Presence:** `PresenceChannel` streams both the global feed (`presence:global`) and user-specific friend snapshots (`presence:friends:<user_id>`). `Presence::FriendBroadcaster` publishes aggregated status/location payloads consumed by `presence-panel` Stimulus controllers.
- **Guilds & Parties:** Customizable ranks (`GuildRank`), shared bank/bulletin boards, level perks (`Guilds::PerkTracker`), and Hotwire-ready parties (`Party`, `PartyInvitation`, `Parties::ReadyCheck`) reflect doc/features/11_social_features.md.
- **PvP Arenas:** `Arena::Matchmaker`, `ArenaSpectatorChannel`, and `/arena_matches` handle matchmaking plus read-only spectator overlays. Rewards leverage `Arena::RewardJob` + mail attachments.
- **Reporting & Safety:** Ignore lists (`IgnoreListEntry`), privacy-aware whispers, and `Moderation::ReportVolumeAlertJob` route spikes through the moderation webhook bridge referenced in `doc/features/5_moderation.md`.
- **Out-of-Game Integrations:** `Social::WebhookDispatcher` + `Social::CommunityAnnouncementJob` broadcast guild achievements, arena outcomes, and hub events to Discord/Telegram. Configure via `SOCIAL_DISCORD_WEBHOOK_URL`/`SOCIAL_TELEGRAM_WEBHOOK_URL`.

## Testing
- System spec: `spec/system/social_ui_spec.rb` covers chat send/validation, friends, mail, ignore list, and report/moderation panel flows.

## Responsible for Implementation Files
- **Configuration:** `config/application.rb`, `config/environments/*.rb`, `config/database.yml`, `config/cable.yml`, `config/puma.rb`, `Procfile.dev`, `bin/dev`.
- **Initializers & Infra:** `config/initializers/*` (Devise, Flipper, Rack::Attack, Sidekiq), `config/sidekiq.yml`.
- **Tooling & Docs:** `README.md` (env vars + setup), `doc/flow/0_technical.md` (in-depth flow), `AGENT.md`, `GUIDE.md`, `MMO_ADDITIONAL_GUIDE.md`.
- **Jobs & Observability:** `app/jobs/*`, `app/services/audit_logger.rb`, `app/services/moderation/webhook_dispatcher.rb`.
