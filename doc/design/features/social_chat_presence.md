# Social Chat And Presence

## Purpose

Social systems make the world feel populated. Chat and local player lists
should stay integrated into the compact game frame rather than separated into a
modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_game_shell_ui.md`
- `doc/design/reference/source_material.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages use the captured `%<name>` addressing shape;
- local/global/private modes are expected;
- message rendering replaces `script` with `скрипт`;
- chat smile codes use the captured `:NNN:` code family with a maximum of
  three replacements per message when smile assets are implemented;
- the layout is dense and operational.

The 2026-05-25 live shell capture confirms the persistent chat/presence control
set: local player sorting, auto-refresh toggle, manual refresh, current
location count, total online count, chat action checkbox, send, clear input,
smile buttons, manual chat refresh, clear chat, all/private/none mode cycle,
refresh speed cycle, transliteration toggle, and server time display.

## Player Experience

The player can read chat while travelling, see who is nearby, click a player
name for common actions, whisper, and join local conversation.

## Chat Channels

Core:

- local;
- global;
- whisper;
- arena room;
- system.

Standalone channel dashboards, slash-command chat, shout channels, generic
profanity dictionaries, modern Unicode emoji pickers, per-channel
moderator/owner roles, and spam-throttle product rules are not part of the
captured Neverlands design.

## Presence Rules

- Presence is tied to current location.
- Movement completion refreshes nearby players.
- City navigation refreshes nearby players.
- Player list should show name, level, and basic status/signs.
- Player list should provide sorting by name and level and a visible refresh
  mode.
- Silence/chat restriction is a player-level status, not a per-channel
  moderator role system.
- Generic busy/idle/presence broadcast states are not part of the captured
  Neverlands design.

## State Concepts

- chat message;
- channel;
- whisper thread;
- local presence entry;
- arena room participant.

## Interactions

- `areas/world_map.md`: local presence after movement.
- `areas/cities_and_buildings.md`: city hubs concentrate social activity.
- `areas/arena.md`: arena applications and rooms are social surfaces.
