# Social Chat And Presence

## Purpose

Social systems make the world feel populated. Chat, local player lists, parties,
and eventually clans should be integrated into the compact game frame rather
than separated into a modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/features/neverlands_inspired_chat.md`
- `doc/flow/neverlands_live_movement.md`
- `doc/flow/neverlands_live_city_movement.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages and local/global modes are expected;
- the layout is dense and operational.

## Player Experience

The player can read chat while travelling, see who is nearby, click a player
name for common actions, whisper, join local conversation, and coordinate with
a party or clan.

## Chat Channels

Core:

- local;
- global;
- whisper;
- party;
- system.

Later:

- clan/guild;
- trade;
- arena room;
- event.

## Presence Rules

- Presence is tied to current location.
- Movement completion refreshes nearby players.
- City navigation refreshes nearby players.
- Player list should show name, level, and basic status/signs.
- Away/offline state should be simple and understandable.

## Party Rules

Core party behavior:

- invite;
- accept/decline;
- leave;
- leader;
- member list;
- party chat;
- ready check later for group combat.

Parties should support combat and quest coordination, but not become a full
separate product area in the first pass.

## Clan/Guild Rules

Clans are later social progression. Keep the first GDD limited to:

- name;
- membership;
- ranks;
- clan chat;
- shared identity.

Territory war, research, and treasury are later expansions.

## State Concepts

- chat message;
- channel;
- whisper thread;
- local presence entry;
- party;
- party member;
- clan/guild;
- ignore entry.

## Interactions

- `areas/world_map.md`: local presence after movement.
- `areas/cities_and_buildings.md`: city hubs concentrate social activity.
- `areas/arena.md`: arena applications and rooms are social surfaces.
- `features/npcs_quests.md`: party questing can build on this later.

## Out Of Scope

- External webhooks/community integrations.
- Heavy moderation tooling in the GDD.
- Housing/pets/achievements as social systems for the core loop.

## Related Implementation Files

Models:

- `app/models/chat_channel.rb`
- `app/models/chat_channel_membership.rb`
- `app/models/chat_message.rb`
- `app/models/chat_emoji.rb`
- `app/models/chat_report.rb`
- `app/models/friendship.rb`
- `app/models/ignore_list_entry.rb`
- `app/models/mail_message.rb`
- `app/models/party.rb`
- `app/models/party_invitation.rb`
- `app/models/party_membership.rb`
- `app/models/guild.rb`
- `app/models/guild_membership.rb`
- `app/models/clan.rb`
- `app/models/clan_membership.rb`
- `app/models/user_session.rb`

Controllers:

- `app/controllers/chat_channels_controller.rb`
- `app/controllers/chat_messages_controller.rb`
- `app/controllers/chat_reports_controller.rb`
- `app/controllers/friendships_controller.rb`
- `app/controllers/ignore_list_entries_controller.rb`
- `app/controllers/mail_messages_controller.rb`
- `app/controllers/parties_controller.rb`
- `app/controllers/party_invitations_controller.rb`
- `app/controllers/party_memberships_controller.rb`
- `app/controllers/guilds_controller.rb`
- `app/controllers/clans_controller.rb`
- `app/controllers/session_pings_controller.rb`

Services and jobs:

- `app/services/chat/message_dispatcher.rb`
- `app/services/chat/channel_router.rb`
- `app/services/chat/ignore_filter.rb`
- `app/services/chat/profanity_filter.rb`
- `app/services/chat/spam_throttler.rb`
- `app/services/presence/publisher.rb`
- `app/services/presence/friend_broadcaster.rb`
- `app/services/auth/user_session_manager.rb`
- `app/services/guilds/permission_service.rb`
- `app/services/clans/permission_matrix.rb`
- `app/jobs/broadcast_chat_message_with_ignore_job.rb`
- `app/jobs/session_presence_job.rb`

Channels, views, and JavaScript:

- `app/channels/realtime_chat_channel.rb`
- `app/channels/presence_channel.rb`
- `app/channels/party_channel.rb`
- `app/views/chat_messages/_chat_message.html.erb`
- `app/views/chat_messages/_form.html.erb`
- `app/views/shared/_nl_players_list.html.erb`
- `app/views/shared/_online_players.html.erb`
- `app/views/world/_mini_chat.html.erb`
- `app/javascript/controllers/chat_controller.js`
- `app/javascript/controllers/chat_input_controller.js`
- `app/javascript/controllers/presence_panel_controller.js`
- `app/javascript/controllers/party_controller.js`

Specs:

- `spec/channels/realtime_chat_channel_spec.rb`
- `spec/channels/presence_channel_spec.rb`
- `spec/models/chat_message_spec.rb`
- `spec/models/friendship_spec.rb`
- `spec/models/party_spec.rb`
- `spec/models/guild_spec.rb`
- `spec/models/clan_spec.rb`
- `spec/models/user_session_spec.rb`
- `spec/requests/chat_messages_spec.rb`
- `spec/requests/session_pings_spec.rb`
- `spec/services/chat/message_dispatcher_spec.rb`
- `spec/services/chat/profanity_filter_spec.rb`
- `spec/services/chat/spam_throttler_spec.rb`
- `spec/system/social_ui_spec.rb`
- `spec/views/shared/_nl_players_list_spec.rb`
