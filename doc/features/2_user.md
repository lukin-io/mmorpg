# 2. Social, Housing, and Meta Systems

## Chat & Messaging
- Channel matrix (global, local, guild, clan, party, whispers) runs through `ChatChannelsController`, `ChatMessagesController`, and their models (`ChatChannel`, `ChatMessage`, `ChatChannelMembership`).
- Moderation surfaces are shared with `5_moderation.md`: profanity filtering, spam throttling, and inline report buttons calling `Moderation::ReportIntake` with evidence snapshots. GMs issue mutes/bans via `ChatModerationAction`.
- Persistent mail (`MailMessagesController`, `MailMessage`) handles offline messages, attachments, and system notices; Turbo streams update inboxes when new mail lands.

## Friends, Presence & Grouping
- `Friendship` + `FriendshipsController` manage bidirectional lists, status updates, and invitations. Privacy enums on `User` determine who can reach you.
- Presence is broadcast via Action Cable (global chat, guild panels) while the `idle-tracker` Stimulus controller pings `SessionPingsController`. Group finder hooks tie into guild recruitment and profession commissions.
- Party/guild membership UI lives in controllers like `GuildsController`, `GuildMembershipsController`, `ClansController`, and `ClanMembershipsController`, all protected by Pundit policies.

## Guilds, Clans & Shared Resources
- Guild artifacts: `Guild`, `GuildMembership`, `GuildApplication`, `GuildBankEntry`, and `GuildMission` models back leveling bonuses, banks, applications, and mission tracking. Controllers broadcast Turbo updates for rosters and banks.
- Clan scaffolding mirrors guilds via `Clan`, `ClanMembership`, `ClanTerritory`, and war/job models—tying into taxes and warfare described in `12_clan_system.md`.
- Shared chat, announcements, and leader permissions are enforced through Pundit policies and Service objects under `app/services/guilds` / `app/services/clans`.

## Achievements, Titles, Housing, Pets & Mounts
- Account-wide achievements/titles stem from `Achievement`, `AchievementGrant`, and services like `Achievements::GrantService`. Profile stats aggregate via `Users::ProfileStats`.
- Player housing: `HousingPlot`, `HousingDecorItem`, and `Housing::InstanceManager` provision instanced plots; `Housing::UpkeepService` charges recurring gold sinks, while the housing controllers expose UI for creation and access rules.
- Pets/mounts: `PetCompanion`, `PetSpecies`, and `Mount` models track ownership, buffs, and cosmetics; controllers live under `app/controllers/pet_companions_controller.rb` and `app/controllers/mounts_controller.rb`.

## Events, Activities & Meta Progression
- Seasonal toggles and competitions run through `GameEventsController`, `EventInstance`, `LiveOps::Event`, and the leaderboard stack (`Leaderboard`, `LeaderboardEntry`, `LeaderboardsController`).
- Community achievements (fishing derbies, crafting drives) hook into guild/clan missions and the global overview dashboards described in `7_game_overview.md`.
- Feature flags (Flipper) gate limited-time content; announcements use `AnnouncementsController` + Action Cable broadcasts.

## Responsible for Implementation Files
- **Chat & Social:** `app/models/chat_channel*.rb`, `app/controllers/chat_channels_controller.rb`, `app/controllers/chat_messages_controller.rb`, `app/controllers/chat_reports_controller.rb`, `app/controllers/friendships_controller.rb`, `app/controllers/mail_messages_controller.rb`.
- **Guilds/Clans:** `app/models/guild*.rb`, `app/models/clan*.rb`, `app/controllers/guilds_controller.rb`, `app/controllers/guild_memberships_controller.rb`, `app/controllers/guild_applications_controller.rb`, `app/controllers/clans_controller.rb`, `app/controllers/clan_memberships_controller.rb`, `app/controllers/clan_wars_controller.rb`.
- **Housing/Pets/Mounts:** `app/models/housing_plot.rb`, `app/models/housing_decor_item.rb`, `app/services/housing/*.rb`, `app/controllers/housing_plots_controller.rb`; `app/models/pet_companion.rb`, `app/models/mount.rb`, respective controllers.
- **Achievements & Profile:** `app/models/achievement*.rb`, `app/services/achievements/*.rb`, `app/services/users/profile_stats.rb`.
- **Events & Meta:** `app/models/announcement.rb`, `app/models/game_event.rb`, `app/controllers/announcements_controller.rb`, `app/controllers/game_events_controller.rb`, `app/models/leaderboard*.rb`, `app/controllers/leaderboards_controller.rb`, `app/models/live_ops/event.rb`.
