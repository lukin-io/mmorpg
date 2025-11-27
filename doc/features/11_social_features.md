# 11. Social Systems & Communication

## Implementation Status

| Feature | Status | Details |
|---------|--------|---------|
| **Real-Time Chat** | ✅ Implemented | ActionCable + Turbo Streams |
| **RealtimeChatChannel** | ✅ Implemented | Global, whisper, clan, party chat |
| **ChatEmoji** | ✅ Implemented | 40+ emojis, `:NNN:` codes, text shortcuts |
| **Username Context Menu** | ✅ Implemented | Whisper, Profile, Mention, Copy, Ignore |
| **Message Highlighting** | ✅ Implemented | Mention, whisper, clan, announcement styles |
| **PresenceChannel** | ✅ Implemented | Online players, zone presence |
| **Arena Rooms** | ✅ Implemented | 10 rooms with level/faction restrictions |
| **Arena Applications** | ✅ Implemented | Submit, accept, cancel fight requests |
| **Arena Combat** | ✅ Implemented | CombatProcessor with damage/defend logic |
| **City View** | ✅ Implemented | Interactive buildings, tooltips, district nav |
| **Ignore List Server-Side** | ✅ Implemented | `Chat::IgnoreFilter` + `BroadcastChatMessageWithIgnoreJob` |
| **Tactical Fights** | ❌ Not Implemented | Positioning-based combat |
| **Betting/Totalizator** | ❌ Not Implemented | Spectator wagering |

---

## Use Cases

### UC-1: Chat with Other Players
**Actor:** Verified player
**Pre-conditions:** Character exists, verified account
**Flow:**
1. Open chat channel or use bottom panel
2. Type message, press Enter
3. Message appears for all channel subscribers instantly
4. Messages can include emoji (picker or `:001:` codes)
5. Click other usernames for quick interactions

### UC-2: Private Conversation
**Actor:** Two players
**Flow:**
1. Player A types `/w PlayerB hello`
2. Message delivered only to A and B
3. Both see red-tinted whisper styling
4. Can reply by clicking sender name

### UC-3: Join Arena Fight
**Actor:** Player wanting PvP
**Flow:**
1. Navigate to Arena → select accessible room
2. Submit fight application (duel/group, parameters)
3. Wait for another player to accept
4. Countdown → match begins
5. Exchange attacks/defends via real-time combat
6. Winner determined when opponent HP reaches 0

### UC-4: Explore City
**Actor:** Player in city zone
**Flow:**
1. World view detects city biome, shows city layout
2. Buildings displayed on grid with icons
3. Hover building → tooltip with name/type
4. Click building → info panel with NPCs, description
5. "Enter" button → navigate into building zone

---

## Key Behavior

### Chat Features
- Messages broadcast via WebSocket (no polling)
- Auto-scroll when at bottom, "New messages" indicator when scrolled up
- Username click/right-click for quick actions
- Emoji picker with 40+ game-themed options
- Profanity filter replaces banned words
- Spam throttle: 8 msgs/10s default

### Arena Rules
- Room accessibility based on character level and faction
- Fight types: duel (1v1), group (team), sacrifice (FFA)
- Equipment rules: no weapons, no artifacts, limited, free
- Timeout: 2-5 minutes
- Trauma: 10-80% XP loss on defeat
- Real-time HP updates via ActionCable

### Presence System
- Online status broadcast to friends
- Zone presence for local chat
- Away/busy/offline status detection
- Online player list in bottom panel

---

## Chat & Messaging
- **Real-Time WebSocket Chat:** Messages are delivered instantly via ActionCable and Turbo Streams. No page reloads required — `ChatMessage#after_create_commit` broadcasts to all channel subscribers, and Turbo automatically appends new messages to the DOM.
- **Channel Model:** `ChatChannel` supports `global`, `local`, `guild`, `clan`, `party`, `arena`, `whisper`, and `system` types. `ChatChannel#membership_required?` gates private channels, while `ChatChannelMembership` enforces uniqueness, mute timers, and GM roles.
- **Dispatch Pipeline:** `Chat::MessageDispatcher` feeds every post into `Moderation::ChatPipeline`, which validates verification state, applies GM mute bans (`ChatModerationAction`), respects whisper privacy, and executes `/gm` commands via `Chat::Moderation::CommandHandler`. `Chat::SpamThrottler` caps per-user throughput (default 8 msgs/10s, adjustable via `User#social_settings`).
- **Profanity & Reporting:** `ChatMessage` retains filtered body text, visibility enum, and `moderation_labels`. Inline report buttons POST to `ChatReportsController`, hydrating `ChatReport#source_context` + `#evidence` and scheduling `Moderation::ReportVolumeAlertJob` to escalate spikes.
- **UI Features:** Stimulus `chat_controller.js` handles auto-scroll (when at bottom), "New messages" indicator, Enter-to-send, and form reset. Messages animate in with slide-up effect. User avatars, relative timestamps, and hover-reveal report buttons enhance UX.
- **Neverlands-Inspired Interactions:**
  - Click username to whisper, Ctrl+Click to @mention
  - Right-click username for context menu (Whisper, View Profile, Mention, Copy Name, Ignore)
  - Message highlighting: `.chat-msg--mention` (blue), `.chat-msg--whisper` (red), `.chat-msg--clan` (gray), `.chat-msg--announcement` (orange)
  - Emoji picker with game-related emojis (⚔️ 🛡️ 💰 🏰 🐉 etc.)
  - Chat commands: `/w [name]` whisper, `/me [action]` emote, `/ignore [name]` block, `@name` mention
- **Mail System:** `MailMessage` tracks attachments (`MailMessage::ATTACHMENT_KEYS`), `system_notification` flag, and `origin_metadata`. `MailMessages::SystemNotifier` emits automated mail (arena rewards, guild perks) while players compose messages through Turbo forms with attachment fields.
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
See `doc/flow/11_arena_pvp.md` for comprehensive arena system documentation.

- **Season + Match Data:** `ArenaSeason`, `ArenaMatch`, and `ArenaParticipation` track tournaments, bracket status, spectate codes, and per-character results/rating deltas. Seeds include the launch "Founders Season."
- **Matchmaking & Rewards:** `Arena::Matchmaker` assembles queued characters into matches while `Arena::RewardJob` distributes winnings (mail attachments) after completion. `ArenaRanking`/`ArenaTournament` remain the long-term leaderboard backbone.
- **Spectator Mode:** `ArenaSpectatorChannel` + `arena-spectator` Stimulus controller stream read-only commentary/logs. Spectator overlay partials hydrate via Action Cable payloads broadcast by `Arena::SpectatorBroadcaster`.

### Neverlands-Inspired Arena Features
- **Room System:** Multiple arena rooms with level/faction restrictions (Training Hall 0-5, Trial Hall 5-10, faction halls for alignment-locked combat)
- **Fight Types:** Duels (1v1), Group (team battles), Sacrifice (FFA), Tactical (positioning-based), Betting (spectator wagering)
- **Fight Parameters:** Configurable equipment rules (no weapons, no artifacts, limited, free), timeout (2-5 min), trauma percentage (10-80%)
- **Application Queue:** Submit fight applications with parameters, accept/decline pending fights, countdown timers to match start
- **Real-Time Combat:** ActionCable broadcasts for HP updates, combat log, countdown, results
- **Combat Log Styling:** Color-coded entries for damage (red), healing (green), buffs (blue), debuffs (purple), criticals (gold), misses (gray)

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
