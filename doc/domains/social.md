# Social, Chat, and Presence Domain

## Scope

Chat history and submission, durable personal/world gameplay-event projection,
channels, identity presentation, nearby-player presence, player context
actions, and their shared-shell integration.

## Documentation chain

- Neverlands source summary: `doc/design/reference/social/README.md`
- Current observations: `doc/design/reference/social/observations/`
- Normalized design: `doc/design/features/social_chat_presence.md`
- Shared layout design: `doc/design/areas/game_client_layout.md`
- Delivery ID: `SOCIAL-CHAT-001` in `doc/design/launch_mvp_plan.md`
- Current implementation boundary: `doc/features/game_shell.md`

## Current RPG status

Partially Implemented. Chat, presence, and the bounded mixed event timeline
remain owned by the shared shell handbook. `GameEvent` is a separate durable
projection record inside that one player-facing chronology, not a second
notification surface or gameplay authority.

## Important responsible implementation files

- `app/controllers/chat_messages_controller.rb`
- `app/models/game_event.rb`
- `app/queries/chat/timeline.rb`
- `app/services/chat/event_publisher.rb`
- `app/services/chat/timeline_broadcaster.rb`
- `app/services/chat/message_dispatcher.rb`
- `app/views/game_events/`
- `app/views/chat_messages/`
- `app/assets/stylesheets/chat_presence.css`

Section 16 of `doc/features/game_shell.md` remains the exhaustive inventory.

## Evidence and implementation gaps

The captured fight-completion, item-found, money-found, and mixed
world-announcement timeline is implemented within the shared shell boundary.
Fresh moderation, private-message, ignore, announcement-authoring,
auxiliary-control, reconnect/retention, and high-volume failure observations
are required before those broader behaviors can be claimed. NPC-specific NV
probabilities remain an evidence gap.
