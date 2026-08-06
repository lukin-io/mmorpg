# Social, Chat, and Presence Domain

## Scope

Chat history and submission, channels, identity presentation, nearby-player
presence, player context actions, and their shared-shell integration.

## Documentation chain

- Neverlands source summary: `doc/design/reference/social/README.md`
- Current observations: `doc/design/reference/social/observations/`
- Normalized design: `doc/design/features/social_chat_presence.md`
- Shared layout design: `doc/design/areas/game_client_layout.md`
- Delivery ID: `SOCIAL-CHAT-001` in `doc/design/launch_mvp_plan.md`
- Current implementation boundary: `doc/features/game_shell.md`

## Current RPG status

Partially Implemented. Chat and presence remain owned by the shared shell; no
second social implementation handbook or runtime pipeline is introduced.

## Important responsible implementation files

- `app/controllers/chat_messages_controller.rb`
- `app/services/chat/message_dispatcher.rb`
- `app/views/chat_messages/`
- `app/assets/stylesheets/chat_presence.css`

Section 16 of `doc/features/game_shell.md` remains the exhaustive inventory.

## Evidence and implementation gaps

Fresh moderation, private-message, ignore, auxiliary-control, and high-volume
failure observations are required before those behaviors can be claimed.
