# Social Chat And Presence

Domain navigation: `doc/domains/social.md` and `doc/domains/shell.md`.

## Purpose

Social systems make the world feel populated. Chat and local player lists
should stay integrated into the compact game frame rather than separated into a
modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/source_material.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages use the captured `%<name>` addressing shape;
- local/global/private modes are expected;
- ordinary chat, personal system results, and game-wide announcements share one
  dense chronological history;
- successful NPC searches can report either an awarded item or deposited NV in
  the same personal system-row shape;
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
name for common actions, whisper, join local conversation, and read durable
personal gameplay results and world announcements without leaving chat. A
successful NPC item or NV search is visible here only after the corresponding
inventory or wallet mutation succeeds.

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

## Game Event Timeline

- Gameplay information is projected into the persistent global-chat history;
  it is not a second notification panel or a browser-selected chat channel.
- Personal system entries have an exact visible `HH:MM:SS` time, bold system
  label, and event-specific emphasis. MVP producers are fight completion with
  awarded combat XP, successfully awarded NPC loot items, and successfully
  deposited NPC-loot NV.
- Game-wide announcements use an orange source marker, attention emphasis, and
  no visible timestamp in the captured state. Local runtime uses an unbranded
  English marker and never copies source promotional/service text.
- Personal and world event rows persist so reloads retain the recent timeline.
  Historical reads are bounded to the latest 200 visible combined entries.
- Audience is server-owned: a personal row belongs to one recipient; a world
  row has no recipient. Recipient selection never comes from browser params.
- Producers publish structured allowlisted facts with stable keys at the
  authoritative gameplay transition. Repeating the same key is idempotent.
- Item and NV rows are success projections only. `InventoryItem` remains item
  ownership authority; `CurrencyWallet` plus `CurrencyTransaction` remain NV
  authority. A failed capacity check or rolled-back wallet credit publishes no
  success row.
- Event rows are immutable player-facing projections and audit aids. Gameplay
  records remain authoritative; this is not event sourcing or a generic pub/sub
  command bus.
- World-announcement creation is a server-side service boundary only. No player
  or generic admin publishing endpoint is implied by the captured evidence.
- Announcement links, scheduling/operations, retention tools, and additional
  event families remain deferred until directly observed and scoped.

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
- typed game event with recipient or world audience;
- channel;
- whisper thread;
- local presence entry;
- arena room participant.

## Interactions

- `areas/world_map.md`: local presence after movement.
- `areas/cities_and_buildings.md`: city hubs concentrate social activity.
- `areas/arena.md`: arena applications and rooms are social surfaces.
- `features/combat.md`: authoritative fight completion and successful NPC loot
  publish personal timeline facts after persistence.
- `features/economy_trading_shops.md`: owns the NV wallet and transaction
  ledger credited before a money-found fact is published.
