# Neverlands Social, Chat, and Presence Source Summary

- Document type: neverlands-source-summary
- Domain: social
- Updated: 2026-09-07
- Evidence status: current for mixed event rows, cell/room audiences, and the
  browser re-entry history boundary; legacy-analysis limits remain elsewhere

## Current observations

- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Chat/presence sections in
  `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- Outdoor presence section in
  `doc/design/reference/world/observations/2026-05-20_outdoor_npc_resource.md`

Historical context remains in
`doc/design/reference/social/observations/legacy_chat_system_analysis.md`.
Its protocol details and interpretation of italic names do not establish a
current source timeout or offline-row rule.

## Current Neverlands behavior

The shell exposes compact chat history, channel/input controls, nearby-player
presence, player context actions, refresh behavior, and identity-colored
messages. The current supplied capture and text addendum additionally show
ordinary/private chat, timestamped personal fight/item/NV system results, and
untimed orange-marked game-wide announcements interleaved in one dense history.
Legacy technical protocol details are evidence, not a Rails target.

The September 7 Neverlands-hosted Chat article confirms ordinary chat belongs
to one cell/room, with no ordinary world-wide player channel. Live Arena room
changes confirm separate room audiences. Private city/region messaging remains
a separate delivery scope. Browser ordinary-chat history does not survive a
new login; no source online-expiry interval has been established.

Live exterior/cell/city/Arena observations also show why display names cannot
identify an audience: adjacent cells can retain the same area label while the
player list changes. The bounded observation did not send ordinary source
messages or perform another source login. The re-entry rule comes from the
Neverlands-hosted article, and the user explicitly confirmed the cell/room
ordinary-chat boundary.

## Evidence gaps

- Current moderation, private-message interaction, ignore, announcement-authoring,
  unfetched-message recovery, detailed Clear behavior, and high-volume failure states require fresh bounded
  verification where they affect implementation.
- Exact online expiry, temporary offline formatting, and first-ever Arena room
  selection remain unestablished. A saved room on the observed account does not
  define a universal initial room.
- The supplied NV row does not identify an NPC or drop probability, so no
  production NPC money table may be inferred from it.

## Design linkage

- `doc/design/features/social_chat_presence.md`
- `doc/design/areas/game_client_layout.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/game_shell.md`

The local ordinary path uses authenticated polling, current login/visit
cutoffs, and a bounded browser buffer; personal/world events retain durable
history and signed streams. Validated city/village/Shop/Arena contexts share one
authoritative audience resolver. Presence includes only playable characters
whose users have a recent open session, using an explicitly technical
five-minute window. CSRF-protected heartbeats cannot reopen signed-out records.
These are local implementation choices and safeguards, not claims about the
source network or expiry internals. Private city/region delivery remains deferred.

### Responsible implementation files

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
- `app/services/arena/npc_loot_awarder.rb`
- `app/views/game_events/_game_event.html.erb`
- `app/assets/stylesheets/chat_presence.css`

Local implementation linkage is context, not Neverlands evidence.
