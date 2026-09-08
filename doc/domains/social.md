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
- `app/controllers/chat_channels_controller.rb`
- `app/controllers/session_pings_controller.rb`
- `app/models/user_session.rb`
- `app/models/game_event.rb`
- `app/queries/chat/timeline.rb`
- `app/queries/game/world/presence.rb`
- `app/services/chat/local_context.rb`
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
Fresh moderation, private-message interaction, ignore, announcement-authoring,
auxiliary-control, unfetched-message recovery, and high-volume failure observations
are required before those broader behaviors can be claimed. NPC-specific NV
probabilities remain an evidence gap.

The September 7 source capture establishes ordinary chat within one cell or
room. The shell now uses server-derived local audiences, reauthorized polling,
history bounded to the current open login and visit, and a bounded browser buffer alongside
durable personal/world game events. Presence uses the same cell/room partition
for village, Shop, supported city buildings, and selected Arena rooms. It
includes only the currently playable character for each user with a recent
open session. Its five-minute liveness
window is a technical projection; exact Neverlands expiry remains an evidence
gap. Private city/region messaging remains deferred and private-address attempts
are rejected instead of being published in ordinary chat.

CSRF-protected heartbeats only refresh existing open login rows; explicit
login owns reopening and starts a new ordinary-buffer generation. Clear keeps
chat/event delivery connected. City-building and Arena-room entry render the
new saved room's presence immediately; the shell handbook records the
first-response and full-shell navigation coverage.
