# Neverlands Social, Chat, and Presence Source Summary

- Document type: neverlands-source-summary
- Domain: social
- Updated: 2026-07-29
- Evidence status: current with legacy-analysis limits

## Current observations

- `doc/design/reference/social/observations/legacy_chat_system_analysis.md`
- Chat/presence sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor presence section in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`

## Current Neverlands behavior

The shell exposes compact chat history, channel/input controls, nearby-player
presence, player context actions, refresh behavior, and identity-colored
messages. Legacy technical protocol details are evidence, not a Rails target.

## Evidence gaps

- Current moderation, private-message, ignore, and high-volume failure states
  require fresh bounded verification where they affect implementation.

## Design linkage

- `doc/design/features/social_chat_presence.md`
- `doc/design/areas/game_client_layout.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/game_shell.md`

### Responsible implementation files

- `app/controllers/chat_messages_controller.rb`
- `app/services/chat/message_dispatcher.rb`
- `app/assets/stylesheets/chat_presence.css`

Local implementation linkage is context, not Neverlands evidence.
