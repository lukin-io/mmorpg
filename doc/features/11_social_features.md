# 11. Social Systems & Communication

## Chat & Messaging
- **Channel Model:** `ChatChannel` now supports `global`, `local`, `guild`, `clan`, `party`, `arena`, `whisper`, and `system` types. `ChatChannel#membership_required?` gates private channels, while `ChatChannelMembership` enforces uniqueness, mute timers, and GM roles.
- **Dispatch Pipeline:** `Chat::MessageDispatcher` feeds every post into `Moderation::ChatPipeline`, which validates verification state, applies GM mute bans (`ChatModerationAction`), respects whisper privacy, and executes `/gm` commands via `Chat::Moderation::CommandHandler`. `Chat::SpamThrottler` caps per-user throughput (default 8 msgs/10s, adjustable via `User#social_settings`).
- **Profanity & Reporting:** `ChatMessage` retains filtered body text, visibility enum, and `moderation_labels`. Inline report buttons POST to `ChatReportsController`, hydrating `ChatReport#source_context` + `#evidence` and scheduling `Moderation::ReportVolumeAlertJob` to escalate spikes.
- **Mail System:** `MailMessage` now tracks attachments (`MailMessage::ATTACHMENT_KEYS`), `system_notification` flag, and `origin_metadata`. `MailMessages::SystemNotifier` emits automated mail (arena rewards, guild perks) while players compose messages through Turbo forms with attachment fields.
- **Channel Routing:** `Chat::ChannelRouter` auto-creates arena/party/guild slugs, ensures membership, and seeds metadata (arena match IDs, participant lists). Arena/party creation hooks automatically call `channel.ensure_membership!`.

## Friends & Presence
- **Presence Backbone:** `PresenceChannel` streams both `presence:global` (status pulses) and per-player feeds (`presence:friends:<user_id>`). `Presence::Publisher` emits online/idle/busy/offline payloads enriched with zone, location, and last activity.
- **Friend Broadcasts:** `Presence::FriendBroadcaster` aggregates `User#friends`, serializes their current session data, and dispatches Turbo-friendly payloads. The `presence-panel` Stimulus controller swaps the friends list live.
- **Activity Tracking:** `SessionPresenceJob` receives front-end pings (via `IdleTrackerController`), updates `UserSession` columns (`current_zone_name`, `last_character_name`, `last_activity_at`), and rebroadcasts friend snapshots to keep dashboards synchronized.
- **Discovery Tools:** `/group_listings` exposes the social LFG board (`GroupListing`), with Turbo create/edit flows plus filters for parties, guild recruitment, and profession commissions. `/social_hubs` showcases taverns/arenas/notice boards (`SocialHub`, `SocialHubEvent`) for in-world meetups.

## Guilds & Player Groups
- **Ranks & Permissions:** `GuildRank` stores customizable permission hashes (invite/kick/manage_bank/post_bulletins/start_war). `GuildMembership` references a rank and falls back to `Guild#default_rank`. `Guilds::PermissionService` centralizes permission checks across controllers.
- **Shared Utilities:** Guild bank entries (`GuildBankEntry`) and bulletins (`GuildBulletin`) have dedicated controllers/views, while `Guilds::PerkTracker` unlocks level-based perks and triggers social announcements.
- **Parties:** `Party`, `PartyMembership`, and `PartyInvitation` handle group lifecycle (ready checks, leadership swaps, invites). `Parties::ReadyCheck` orchestrates Turbo-ready toggles; each party automatically provisions a `ChatChannel` + membership for real-time coordination.
- **Social Hubs:** Static + seeded `SocialHub` records capture taverns, arena lobbies, and event plazas. `social_hubs#index/show` surface metadata, upcoming hub events, and links into the broader social economy.

## PvP Arenas & Competitions
- **Season + Match Data:** `ArenaSeason`, `ArenaMatch`, and `ArenaParticipation` track tournaments, bracket status, spectate codes, and per-character results/rating deltas. Seeds include the launch “Founders Season.”
- **Matchmaking & Rewards:** `Arena::Matchmaker` assembles queued characters into matches while `Arena::RewardJob` distributes winnings (mail attachments) after completion. `ArenaRanking`/`ArenaTournament` remain the long-term leaderboard backbone.
- **Spectator Mode:** `ArenaSpectatorChannel` + `arena-spectator` Stimulus controller stream read-only commentary/logs. Spectator overlay partials hydrate via Action Cable payloads broadcast by `Arena::SpectatorBroadcaster`.

## Reporting & Community Safety
- **Inline Reports:** Chat, profile, and combat-log buttons fire `ChatReportsController#create`/`Moderation::ReportsController`. Every report includes source metadata and spawns moderation tickets (`doc/features/5_moderation.md`).
- **Ignore Lists & Privacy:** `IgnoreListEntry` blocks whispers/messages both ways; `User#allows_chat_from?` short-circuits when ignore relationships exist. Privacy settings (chat/friend/duel) continue to rely on `User#privacy_allows?`.
- **Throttling & Alerts:** `Chat::SpamThrottler` raises `Chat::Errors::SpamThrottledError` when limits are hit, while `Moderation::ReportVolumeAlertJob` pings Discord/Telegram webhooks if report volume surpasses `REPORT_VOLUME_ALERT_THRESHOLD`.

## Integrations & Out-of-Game Community
- **Webhook Dispatcher:** `Social::WebhookDispatcher` sends community updates (guild perks, arena winners, seasonal hub events) to `SOCIAL_DISCORD_WEBHOOK_URL` / `SOCIAL_TELEGRAM_WEBHOOK_URL`. `Social::CommunityAnnouncementJob` wraps async delivery.
- **Guild/Arena Announcements:** `Guilds::PerkTracker#announce` and `Arena::RewardJob` both trigger webhook + mail notifications so achievements make it off-platform.
- **Roadmap Hooks:** Interfaces remain open for future forum embedding, screenshot sharing, and fan-site APIs leveraging the same webhook infrastructure.

## Responsible for Implementation Files
- **Models:** `app/models/chat_channel.rb`, `app/models/chat_channel_membership.rb`, `app/models/chat_message.rb`, `app/models/chat_report.rb`, `app/models/mail_message.rb`, `app/models/ignore_list_entry.rb`, `app/models/group_listing.rb`, `app/models/social_hub*.rb`, `app/models/guild_rank.rb`, `app/models/guild_bulletin.rb`, `app/models/guild_perk.rb`, `app/models/party*.rb`, `app/models/arena_season.rb`, `app/models/arena_match.rb`, `app/models/arena_participation.rb`.
- **Services:** `app/services/chat/**/*.rb`, `app/services/moderation/chat_pipeline.rb`, `app/services/mail_messages/system_notifier.rb`, `app/services/presence/**/*.rb`, `app/services/guilds/**/*.rb`, `app/services/parties/ready_check.rb`, `app/services/arena/**/*.rb`, `app/services/social/webhook_dispatcher.rb`.
- **Controllers & Views:** `app/controllers/chat_messages_controller.rb`, `app/controllers/chat_reports_controller.rb`, `app/controllers/chat_channels_controller.rb`, `app/controllers/friendships_controller.rb`, `app/controllers/mail_messages_controller.rb`, `app/controllers/ignore_list_entries_controller.rb`, `app/controllers/group_listings_controller.rb`, `app/controllers/social_hubs_controller.rb`, `app/controllers/guild_*`, `app/controllers/parties_controller.rb`, `app/controllers/party_memberships_controller.rb`, `app/controllers/party_invitations_controller.rb`, `app/controllers/arena_matches_controller.rb`, `app/views/**/social_*`.
- **Channels & Frontend:** `app/channels/presence_channel.rb`, `app/channels/arena_spectator_channel.rb`, `app/javascript/controllers/{chat,presence_panel,arena_spectator}.js`.
- **Jobs & Alerts:** `app/jobs/session_presence_job.rb`, `app/jobs/moderation/report_volume_alert_job.rb`, `app/jobs/arena/reward_job.rb`, `app/jobs/social/community_announcement_job.rb`.
- **Config & Data:** `config/routes.rb`, `db/migrate/20251125103720_add_social_messaging_fields.rb`, `db/migrate/20251125103725_create_social_structures.rb`, `db/migrate/20251125103737_create_guild_party_arena_systems.rb`, `db/seeds.rb`, plus `.env` documentation in `README.md`.
