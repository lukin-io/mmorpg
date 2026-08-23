# Neverlands Social, Chat, and Presence Source Summary

- Document type: neverlands-source-summary
- Domain: social
- Updated: 2026-08-23
- Evidence status: current for the bounded mixed-timeline capture, with
  legacy-analysis limits elsewhere

## Current observations

- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/social/observations/legacy_chat_system_analysis.md`
- Chat/presence sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor presence section in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`

## Current Neverlands behavior

The shell exposes compact chat history, channel/input controls, nearby-player
presence, player context actions, refresh behavior, and identity-colored
messages. The current supplied capture and text addendum additionally show
ordinary/private chat, timestamped personal fight/item/NV system results, and
untimed orange-marked game-wide announcements interleaved in one dense history.
Legacy technical protocol details are evidence, not a Rails target.

## Evidence gaps

- Current moderation, private-message, ignore, announcement-authoring,
  reconnect/retention, and high-volume failure states require fresh bounded
  verification where they affect implementation.
- The supplied NV row does not identify an NPC or drop probability, so no
  production NPC money table may be inferred from it.

## Design linkage

- `doc/design/features/social_chat_presence.md`
- `doc/design/areas/game_client_layout.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/game_shell.md`

### Responsible implementation files

- `app/controllers/chat_messages_controller.rb`
- `app/models/game_event.rb`
- `app/queries/chat/timeline.rb`
- `app/services/chat/event_publisher.rb`
- `app/services/chat/timeline_broadcaster.rb`
- `app/services/chat/message_dispatcher.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/views/game_events/_game_event.html.erb`
- `app/assets/stylesheets/chat_presence.css`

Local implementation linkage is context, not Neverlands evidence.
