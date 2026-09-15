# Social Chat And Presence

Domain navigation: [Social](../../domains/social.md) and
[Shell](../../domains/shell.md).

The [gameplay event catalog](../../features/game_shell.md#gameplay-event-catalog)
connects actual producers, audiences, wording and persistence to the Shell
implementation. [WORLD](../../WORLD.md#5-travel-context-and-return-behavior)
describes the location/room changes that determine chat and presence context.

## September12 authorized calibration

The user authorized the best evidence-grounded approximation after22 controlled
fights. [Calibration v1](combat_calibration.md) owns the fitted combat, mastery,
fatigue, magic, XP/drop, injury/recovery and remote-placement rules. It
supersedes earlier implementation holds for hidden coefficients; historical
source observations and uncertainty remain unchanged. Medical Care supplies
the bounded healer/patient transaction and Hospital bag purchase handoff.


## Purpose

Social systems make the world feel populated. Chat and local player lists
should stay integrated into the compact game frame rather than separated into a
modern social dashboard.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- `doc/design/reference/world/observations/2026-09-08_forpost_oktal_airship_journey.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/source_material.md`

Borrowed feel:

- chat and player list are persistent game-frame companions;
- local presence refreshes after movement/city navigation;
- usernames are interactive;
- private messages use the captured `%<name>` addressing shape;
- ordinary chat is restricted to one cell or room; global delivery is for
  system announcements, not ordinary player messages;
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

The player can read chat while travelling, see who is nearby, join local
conversation, and read durable personal gameplay results and world
announcements without leaving chat. A
successful NPC item or NV search is visible here only after the corresponding
inventory or wallet mutation succeeds.

Private addressing and broader player-name actions belong to the captured
target, but their complete delivery/interaction behavior remains deferred. The
current local composer rejects a `%<name>` private-address prefix rather than
publishing the intended private text to the room.

## Chat Channels

Source audience boundaries:

- ordinary local cell/room chat, including each selected Arena room;
- world-wide system announcements;
- recipient-only system information;
- private city/region messages and separate clan-private messages, deferred.

The server derives the ordinary audience from the selected playable character's
persisted region or city node, exact cell, and validated room identity. Village
exterior, Village Square, village/city Shop, supported city-building interiors,
and selected Arena rooms remain separate when coordinates are unchanged.
Display labels never identify audiences: the same named outdoor area can span
multiple cells. Leaving a cell or room ends permission to read or post there, including through a stale
form or subscription. Private messages use their separately captured city or
region boundary and remain deferred; a private-address attempt must never be
silently sent as an ordinary local message.

Already-delivered ordinary rows remain in the browser's bounded chat buffer
while moving. A new login clears ordinary browser history. Durable local
`ChatMessage` records may support audit/debugging, but they do not authorize a
player to replay earlier logins or visits. Recovery of messages never fetched
before departure is not inferred. The local buffer is capped at 200 combined
rows; personal gameplay records below retain their explicitly required durable
history across logins.

The local Rails adaptation delivers ordinary rows through authenticated
current-location polling every ten seconds, with a direct committed sender
response. It does not broadcast ordinary rows to shared local streams whose
old signed subscription could outlive movement. Each read/post rechecks the
current open login and room; a post serializes with movement and logout.
Personal/world gameplay events retain their signed after-commit streams and
durable server history under the user's log-system requirement. These polling,
locking, and storage choices are implementation decisions, not inferred source
network internals.

For an aboard airship journey, the local room key is the persisted route and
exact departure, shared by waiting, in-flight, and arrived-aboard passengers.
The moving ground cell beneath the flight is not its ordinary-chat audience.
Boarding/disembarkation change the visit; intermediate path/phase updates
preserve its timestamp. Other routes/departures and ground rooms remain
separate. Current-session authorization, ten-second polling, delivered browser
history, Clear, and fresh-login behavior retain the same rules above.

The completed source trip showed distinct station/route roster labels and
waiting-state reload recovery. Chat delivery aboard and the source's internal
flight grouping were not exercised. Grouping the local passengers of one
authoritative flight applies the already-confirmed one-cell/room rule; it is
an explicit implementation choice, not additional source transport evidence.

Clear is a presentation action: it keeps the timeline and delivery connected,
removes displayed rows, and retains bounded cleared ordinary ids in that same
login's browser buffer so the next poll does not immediately restore them.
It deletes no chat or gameplay-event records. The exact source behavior for
every Clear, reconnect, and browser-storage failure variant remains uncaptured.

Standalone channel dashboards, slash-command chat, shout channels, generic
profanity dictionaries, modern Unicode emoji pickers, per-channel
moderator/owner roles, and spam-throttle product rules are not part of the
captured Neverlands design.

## Game Event Timeline

- Gameplay information is projected into the persistent shared chat history;
  it is not a second notification panel or a browser-selected chat channel.
- Personal system entries have an exact visible `HH:MM:SS` time, bold system
  label, and event-specific emphasis. MVP producers are fight completion with
  awarded combat XP, successfully awarded NPC loot items, and successfully
  deposited NPC-loot NV.
  The September 11 solo-NPC cycle confirms positive-XP notices on explicit
  Finish and no private zero-XP completion row; the Combat owner records the
  evidence and projects its already durable reward through the same timeline.
- Game-wide announcements use an orange source marker, attention emphasis, and
  no visible timestamp in the captured state. Local runtime uses an unbranded
  English marker and never copies source promotional/service text.
- Personal and world event rows persist so reloads retain the recent timeline.
  Historical reads are bounded to the latest 200 visible combined entries.
- Audience is server-owned: a personal row belongs to one recipient; a world
  row has no recipient. Recipient selection never comes from browser params.
- Producers publish structured allowlisted facts with stable keys at the
  authoritative gameplay transition. Repeating the same key is idempotent.
- A producer reuses `system_information` only when its personal audience,
  generic system meaning, and rendering match. A distinct semantic or visual
  family requires an allowlisted event type, database-constraint migration,
  validated publisher method, explicit renderer, layered retry/audience tests,
  and updates through the evidence/design/handbook/launch chain.
- Item and NV rows are success projections only. `InventoryItem` remains item
  ownership authority; `CurrencyWallet` plus `CurrencyTransaction` remain NV
  authority. A failed capacity check or rolled-back wallet credit publishes no
  success row.
- Event rows are immutable player-facing projections and audit aids. Gameplay
  records remain authoritative; this is not event sourcing or a generic pub/sub
  command bus.
- Event publication has no generic browser/admin endpoint. Domain services call
  the publisher inside the transaction that persists the source transition;
  after-commit broadcasting and bounded history are presentation/read concerns.
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
- Distinct validated village, Shop, city-building, and selected Arena rooms
  are distinct audiences even when their outdoor/city coordinates are unchanged.
- Exact logout/disconnect expiry and temporary offline-row presentation remain
  an evidence gap. The existing local five-minute session projection is a
  technical membership/online-total definition, not a Neverlands expiry claim.

The local presence projection includes only the user's currently playable
character (`User#character`, first-created with id as tie-breaker), not every
owned character. A user with at least one unsigned-out session last seen
strictly within five minutes is eligible; multiple devices do not duplicate a
row. List and header count use the same exact room scope, with at most ten
visible sorted rows and the full room count. Total online counts distinct
eligible users across locations. This bounded projection does not lock other
players or make movement decisions.

An active aboard reservation overrides cell/room presence with its route and
departure audience until explicit disembarkation. Ground lists exclude aboard
characters even when they share an underlying position. The flight projection
does not load ground NPCs, tiles, or room candidates; it retains the same
online/selected-character rules, sorted ten-row bound, and full audience count.

The server refreshes an existing open session on shell, presence, and local-chat
requests. The CSRF-protected heartbeat never creates a login record, moves a
last-seen timestamp backward, or reopens a signed-out record. Explicit login
owns reopening and sets a fresh generation for the ordinary browser buffer.
These safeguards define local session integrity without claiming a source
disconnect formula.

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
