# frozen_string_literal: true
---
title: Game Shell Feature
description: Implementation handbook for the Neverlands-based persistent game frame, compact vitals, location presence, mixed chat/game-event timeline, and shell preferences.
status: Partially Implemented
updated: 2026-08-23
owners: Game Shell and Social Presence
template: feature-v1
---

# Game Shell

This document is the implementation contract for the current Game Shell feature. It explains the persistent top status bar, main Turbo frame, floating same-location player list, bottom mixed chat/game-event timeline, layout preferences, authentication, login resume integration, client ownership, known limits, and test coverage.

It describes what exists now. It does not turn every visible Neverlands toolbar control, chat mode, presence action, or familiar browser-game shell convention into shipped behavior.

## 1. Design authority and related documents

Domain navigation: `doc/domains/shell.md` and `doc/domains/social.md`.

Neverlands is the sole game-design and visual reference for this feature. The local implementation adapts its compact framed game client, bracketed character/vitals state, text-link toolbar, floating nearby-player panel, and bottom chat strip to Rails, Turbo, Stimulus, and the current English client.

When behavior is uncertain or conflicts with this document:

1. Re-observe Neverlands and record the evidence under `doc/design/reference/`.
2. Update the relevant shell/social design record.
3. Change implementation and coverage together.
4. Update this feature contract last.

Supporting documents:

- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md` records the live frame layout, toolbar, location/presence block, and chat strip.
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md` records current supplied-image/text evidence for player chat, personal fight, item, and NV search results, and game-wide announcements in one history.
- `doc/design/reference/social/observations/legacy_chat_system_analysis.md` records earlier chat observations and explicitly separated unknowns.
- `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md` records the player/vitals presentation linked from the shell.
- `doc/design/areas/game_client_layout.md` defines shared client-layout ownership.
- `doc/design/features/social_chat_presence.md` defines chat, membership, ignore, and presence behavior.
- `doc/design/features/character_vitals.md` defines authoritative vitals consumed by the header.
- `doc/design/launch_mvp_plan.md` defines the shell/social MVP boundary.
- `doc/features/world.md` owns outdoor/city world content and the same-cell presence query.
- `doc/features/city.md` owns city-node content rendered in the main frame.
- `doc/features/character_progression.md` owns the linked player profile.
- `doc/features/player_inventory.md` owns the linked carried/equipment surface.
- `doc/features/shop_economy.md` owns the Shop surface loaded from City.
- `doc/features/arena_combat.md` owns Arena and active-fight content rendered in the shell, plus the intentionally shell-free public fight log.

### 1.1 Cross-feature relationships

| Related feature | Relationship | Ownership and handoff |
|---|---|---|
| `doc/features/world.md` | World bootstraps the layout, supplies exact-cell presence, and resolves Character/Inventory shell actions against a possible wilderness NPC interruption. | Game Shell owns the visible controls/frame; World owns position, the allowlisted destination action, hostile handoff, and post-fight return context. |
| `doc/features/city.md` | City renders its illustrated node surface in the shell's central frame. | City owns node content, navigation, and hotspot mutations; Game Shell owns only surrounding shared controls. |
| `doc/features/character_progression.md` | Character navigation opens the profile and allocation surfaces, while the header presents current identity/vitals. | Character Progression owns allocations/profile values; Game Shell owns links, frame placement, and compact header presentation. |
| `doc/features/player_inventory.md` | Inventory navigation opens the carried/equipment surface in the main frame and reports request failures through the shell's stable flash target. | Player Inventory owns stacks, equipment, capacity, mutations, and error copy; Game Shell owns surrounding navigation, vitals, chat, presence, and flash presentation. |
| `doc/features/shop_economy.md` | The Shop occupies the central gameplay surface after a City handoff. | Shop owns catalog and economic mutations; Game Shell owns shared navigation, presence, chat, and flash presentation. |
| `doc/features/arena_combat.md` | Arena and active fights occupy the authenticated main surface, while `/log/:id` explicitly uses the public layout; authoritative completion and item/NV loot transitions also publish player-facing facts. | Arena Combat owns fight state, typed loot resolution, rewards, and the public log. Game Shell owns the authenticated frame and durable recipient event projection in the shared chat timeline. |

## 2. Feature summary

After login, the player opens the World through a persistent Neverlands-shaped game frame. The live-measured `955 × 817` composition uses a 29px top strip, flexible scrolling main frame, 8px resize band, 240px chat/presence row with a 300px right presence column, 1px separator, and 30px CSS/text chat controls. The header shows name, level, stacked server-rendered HP/MP strips, Character and Inventory actions, contextual Return/Look around, and a CSS/text exit control. Character and Inventory submit the allowlisted World context-action route so a source-backed same-cell hostile encounter can replace navigation with combat and return to the requested destination afterward.

The server owns identity, character state, location presence, social verification, channel visibility, message and game-event persistence, event audience, ignore filtering, and authorization. The browser owns only main-frame navigation, presence sort/refresh preferences, and chat focus/scroll/reset presentation.

Desktop source parity and responsive adaptation are separate contracts. The
`955 × 817` measurement remains exact at desktop. Tablet and mobile widths
reflow the same semantic regions without creating a second feature layout or
moving any authority into CSS/JavaScript.

`ApplicationController` selects the full game layout for every authenticated HTML gameplay surface, while anonymous authentication and public-profile requests use the minimal public layout. World remains the shell bootstrap and owns Character/Inventory context actions that may hand navigation to combat before the allowlisted destination. Full-page redirects therefore preserve the same top/main/presence/chat composition instead of falling back to a separate account-dashboard layout.

The MVP currently contains:

- a source-shaped authenticated top/main/presence/chat frame around World and City;
- exact-cell presence, four server allowlisted sorts, recent-session total, and optional 30-second browser refresh;
- lazy global-chat history, Turbo Stream delivery, message creation, policies, membership, mute/privacy, and ignore handling;
- a durable latest-200 mixed timeline of ordinary messages, recipient-only fight/item/NV system results, and server-owned world announcements, with no separate toast-notification surface;
- local browser persistence for presence sorting/refresh plus server persistence for character location and gameplay resume;
- English player-facing copy while Neverlands remains the design authority.

## 3. MVP goals and non-goals

### Goals

- Keep the primary game surface compact and continuously oriented around character, place, nearby players, and chat.
- Load owned feature pages inside a stable main Turbo frame where their response supports it.
- Keep presence and chat data authenticated, server-scoped, and policy-authorized.
- Keep personal gameplay results and world announcements durable, audience-scoped, idempotent at their producer boundary, and interleaved with chat.
- Preserve browser-only presentation preferences without treating them as account/game state.
- Resume the player's authoritative World, City, or supported building/shop context after login.

### Non-goals

- Recreating Neverlands framesets, CGI URLs, browser quirks, or Russian copy.
- Copying Neverlands images, sprites, logos, decorative artwork, branding,
  signatures, administration text, or project/service prose into runtime UI.
- Claiming the currently inert smile palettes, chat mode/speed cycles, transliteration, or player-action popup are complete before their live states are captured and implemented.
- Making presence into movement authority, a precise global-online system, or a remote-player locator.
- Treating client-side HP/MP interpolation as authoritative regeneration.
- Owning World, City, Inventory, Profile, Shop, Arena, or Combat domain mutations rendered in the main frame.

## 4. Player experience

### 4.1 Entry conditions

Every game request requires Devise authentication. On sign-in, the application ensures a playable character and resolves an allowlisted resume path. World is the default entry and ensures the character has an authoritative position before rendering; `ApplicationController` selects the persistent game layout for authenticated gameplay pages.

Chat additionally requires a user verified for social features. A global channel must exist for the lazy message frame and inline form to appear; otherwise the shell renders the loading placeholder without a submission form.

### 4.2 Primary surface

The top bar shows `name[level]`, stacked 160 × 6px red HP and blue MP strips, `[current/max | current/max]` text, Your character and Inventory controls, contextual Return/Look around, and the 15px source logout image. The main content fills the flexible central row.

The 240px social row shows chronological chat on the left and the current zone, same-cell count, recent-session total, `a-z`, `z-a`, `0-33`, `33-0`, and refresh controls in a 300px right column. The 30px bottom strip uses project-owned text/glyph controls in the captured order around one text input and server-rendered `HH:MM:SS` time.

At `<=940px` the shell removes its desktop minimum width, compacts presence to
260px, and keeps the bottom control strip usable. At `<=720px` the header uses
two rows with horizontally scrollable context navigation, chat and presence
stack in the social region, and the bottom controls use two rows. The flexible
main region remains the owning feature's scroll container. At `<=420px` only
the compact vitals geometry changes further.

### 4.3 Player actions and feedback

The player can request Character or Inventory from World, sort nearby players, enable/disable automatic presence refresh, press Say to focus chat, submit a nonblank message with Enter, follow profile links, and exit after confirmation. World either redirects the context action to its allowlisted destination or starts the current hostile encounter and saves that destination for the fight's explicit finish step.

Chat success clears/refocuses the inline input and arrives through the channel Turbo Stream. HTML chat success redirects with a notice; JSON success returns created status. Validation, mute, privacy, or authorization failures return an inline `422`, HTML error surface, JSON error, redirect, or forbidden response as appropriate.

Fight completion and successfully awarded NPC item or NV loot appear as recipient-only
system rows in the same chronology. Personal rows show exact `HH:MM:SS`, a bold
system label, and event-specific XP/item/money emphasis. Server-published world rows
use an unbranded orange `World` marker and no visible timestamp. Both initial
history and after-commit Turbo delivery enforce recipient scope on the server;
ordinary request errors continue to use the stable flash surface.

### 4.4 Exit and integration behavior

Logout ends the authenticated game view. Login returns through `Game::World::ResumeContext`, which selects World, a supported City building, or Shop from server-sanitized context; exact cell/node position remains owned by World/City.

When central navigation hands off, the destination feature owns its content and mutation rules. Game Shell continues to own only the frame, shared navigation, current vitals presentation, presence presentation, global compact chat, flashes, and client preferences.

## 5. Feature topology and authored content

The feature is a fixed shell region graph plus social channel types.

| Region or key | Player-facing name | Connections or actions | Implemented content |
|---|---|---|---|
| `top_bar` | Character status/navigation | Profile, Inventory, City state, logout | Name, level, HP/MP, compact text controls |
| `main_content` | Current feature surface | Turbo-frame navigation/handoff | World/City bootstrap and compatible feature pages |
| `players_panel` | Nearby players | Four sorts, refresh toggle, profile links | Exact zone/x/y list excluding current player; maximum 10 |
| `bottom_bar` | Chat/status | Say, Enter submit, streamed mixed history | Global channel, compact messages/events, input, time |
| `global`, `local`, `system` | Public channel types | Read subject to policy; post except system | Public policy scope |
| `whisper` | Membership channel | Member read/post with privacy checks | Participant metadata and membership |
| `arena` | Arena channel | Public-style access/post | Channel type exists; arena owns match integration |

### 5.1 Coordinate, key, or identity terminology

- **Main content frame** — DOM identity `main_content`; a navigation target, not domain authority.
- **Exact location** — authoritative `zone_id`, `x`, and `y` on `CharacterPosition`; presence uses all three.
- **Recent session** — an unsigned-out `UserSession` seen within the last five minutes; used only for the displayed total.
- **Channel ID/type** — server record identity and enum controlling scope/membership rules.
- **Game-event key/audience** — stable producer identity plus either one persisted recipient or the world audience; neither is selected by the browser.
- **Layout preference** — browser-local `playersSort` and `autoRefresh`, stored under `browser_rpg_layout`.

DOM placement, displayed location text, a player-list row, local storage, or a submitted channel ID never grants location, identity, membership, or posting authority.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Persistent game layout | `GET /world` | Interactive | `layouts/game` through `WorldController` |
| Main feature frame | `turbo-frame#main_content` | Interactive integration | Game layout and destination controller/view |
| Same-cell presence | `GET /world/players` | Interactive/read-only | World query and shared list partial |
| Compact global chat | lazy `GET /chat_channels/:id` | Interactive | Chat controllers/views/services |
| Mixed game-event history/live delivery | Global chat timeline | Interactive/read-only | `GameEvent`, `Chat::Timeline`, `Chat::EventPublisher`, Turbo Streams |
| Chat creation | `POST /chat_channels/:chat_channel_id/chat_messages` | Interactive | Policy and `MessageDispatcher` |
| Inline HP/MP | Every shell render | Interactive presentation over authoritative values | Shared vitals partial and Stimulus controller |
| Send, clear input, refresh chat, clear visible chat | Bottom controls | Interactive | `game-layout` presentation actions plus chat form/frame |
| Smile palettes, chat mode/speed, transliteration, player actions | Bottom controls | Not Done | Measured CSS/text controls rendered; transition states remain evidence/implementation gaps |

### 6.2 Header, main frame, and vitals

World renders outdoor or city content into the layout's single main Turbo frame. Character and Inventory controls submit `POST /world/context`; City displays as disabled context rather than a generic exit, and city movement remains inside the City surface. The logout `X` submits Devise sign-out after confirmation.

The vitals partial calculates clamped display percentages from authoritative character values and renders current/max HP and MP. It supplies the same values to `nl-vitals`, whose targets update both strips and the compact text between server renders. This interpolation remains presentation only and never persists vitals.

### 6.3 Presence and layout preferences

Presence includes other positioned characters with the same zone, x, and y; excludes the current character; applies one of four server allowlisted sorts; and limits the result to 10. Unknown sorts fall back to alphabetical ascending. The total count uses distinct users with a session seen in the last five minutes and is broader than the current cell.

`game-layout` stores sort and automatic-refresh preferences in local storage. When enabled, it fetches the same authenticated partial every 30 seconds. A failed refresh logs a warning and leaves the last rendered list in place.

### 6.4 Compact chat, game events, and deferred behavior boundary

The lazy compact global frame uses `Chat::Timeline` to compose ordinary
messages after ignore filtering with world and current-recipient `GameEvent`
rows. It loads a bounded candidate set for each record type, sorts by occurrence
time and stable tie breakers, and displays only the latest 200 combined entries
chronologically. Non-global channel histories contain only their own messages.
All message/event bodies are escaped; chat additionally replaces
case-insensitive `script` text with `[removed]` before display.

The frame subscribes to the channel stream plus signed global and
recipient-specific event streams. New rows append to one stable
`chat_timeline` target after commit. When the first live row arrives, CSS hides
the prior empty placeholder. Chat and personal system timestamps use exact
`HH:MM:SS`; captured world rows intentionally have no visible timestamp.
The full channel page suppresses the shell's lazy duplicate history frame, so
one document never contains competing timeline targets/subscriptions.

Message creation strips surrounding whitespace, rejects blank bodies, ensures social verification, blocks system-channel posting and active mutes, checks whisper privacy, ensures membership where required, persists the message, and broadcasts after commit. The source send and clear-input buttons drive the same form/input; refresh reloads the compact frame and clear removes its visible rows locally.

`Chat::EventPublisher` accepts allowlisted server-owned facts and stable keys.
The first integrated producers are Arena/World shared combat completion and
successful NPC item/NV loot awards. Item rows are published only after
`InventoryItem` persistence; NV rows are published only after the Economy-owned
wallet and ledger transaction are persisted. `system_information` and
`world_announcement` are
narrow server-side extension points; no player/admin endpoint, schedule, link
model, or invented global content is shipped. There is no separate toast
notification path, command execution, transliteration, smile picker, formatting
palette, chat-mode cycle, refresh-speed cycle, or player-action popup.

`Chat::TimelineBroadcaster` is the presentation integration boundary used by
both record types after commit. It alone owns event stream names, the stable DOM
target, and partial selection; persistence models do not know view identities.

## 7. Authoritative data and presentation model

| Record or component | Responsibility | Important contract |
|---|---|---|
| `Character` and `CharacterPosition` | Header identity/vitals and exact presence location | Current signed-in character is authoritative |
| `UserSession` | Recent online-total signal | Recent means unsigned-out and seen within five minutes |
| `ChatChannel` and `ChatChannelMembership` | Channel type, visibility, creator, membership | Public types versus member-required whisper |
| `ChatMessage` | Persisted sender/body/visibility/metadata | Body present; broadcasts only after commit |
| `GameEvent` | Immutable recipient/world gameplay-information projection | Allowlisted fight/item/money/system/world type, stable unique key, structured payload, occurrence time, and audience constraints |
| `Chat::Timeline` | Bounded mixed history read | Latest 200 visible combined rows; events only in the global channel |
| `Chat::EventPublisher` | Normalize and persist server-owned event facts | Stable keys are idempotent and conflicting reuse fails |
| `Chat::TimelineBroadcaster` | After-commit Turbo presentation | Owns stream names, stable DOM target, and record partial selection |
| `IgnoreListEntry` and `Chat::IgnoreFilter` | Initial-history visibility and whisper privacy | System/self messages retain explicit behavior |
| `ChatChannelPolicy` and `ChatMessagePolicy` | Read/post authorization | Verified social user plus public/member rules |
| `Game::World::ResumeContext` | Allowlisted login destination | Never follows arbitrary persisted URLs |
| Stimulus/local storage | Shell interaction preferences | Presentation only; never character/session authority |

### 7.1 Source of truth

Database character, position, session, channel, membership, message, event, and ignore records are authoritative for their own state. Gameplay records remain authoritative for combat/reward outcomes; `GameEvent` is a durable player-facing projection and audit aid, not event-sourcing state. The World controller builds current location/presence. Chat policy scope selects visible channels, `IgnoreFilter` removes blocked historical messages, and `GameEvent.visible_to` admits only world plus current-recipient rows.

If there is no global channel, compact chat has no source URL or form. If no other characters are present, the list renders its empty state. Missing layout preferences fall back to alphabetical sort and automatic refresh enabled.

### 7.2 Validation and state lifecycle

- Channel names/slugs are required and slug is unique; missing slugs are generated on create.
- Channel types are `global`, `local`, `whisper`, `system`, and `arena`.
- Global/local/arena/system do not require membership for read policy; whisper does.
- System chat is read-only; verified users may post only to policy-accessible writable channels.
- Chat bodies are stripped and must be nonblank; no maximum length is currently enforced.
- Game events require an allowlisted type, nonblank stable key/body, object payload,
  occurrence time, and a database-valid recipient/world audience. Persisted
  events cannot be updated or destroyed through the model.
- Event keys are database-unique. Identical retries return the existing row;
  reuse for a different recipient/type/body/payload raises a conflict.
- Global history loads at most 200 combined visible entries; other channels load
  at most 200 messages. Presence loads at most 10 co-located characters.
- The automatic presence timer is 30 seconds; recent total uses a five-minute session window.

### 7.3 Presentation versus authority

Turbo-frame targets, sort links, refresh checkbox state, local-storage values, displayed counts, DOM channel/event data, and client clock rendering are presentation/input only. Server endpoints and services apply sort allowlists, current-position queries, policy scope, message authorization, event audience, and domain validation.

Client-side vitals values are a display snapshot. Server character/vitals services remain authoritative for regeneration, damage, healing, maximums, and persistence.

## 8. Runtime architecture

```mermaid
flowchart LR
    A["Login or GET World"] --> B["Resolve playable character, resume context, and position"]
    B --> C["World builds current surface and same-cell presence"]
    C --> D["Render game layout and main_content frame"]
    D --> E["Lazy-load authorized global chat history"]
    E --> M["Compose visible messages and game events"]
    F["Sort or 30-second refresh"] --> G["GET authenticated same-cell players partial"]
    H["Submit chat message"] --> I["Policy, verification, mute/privacy, membership checks"]
    I --> J["Persist message and broadcast after commit"]
    J --> K["Turbo Stream appends; input resets"]
    I -->|failure| L["422/forbidden/error response without message"]
    N["Authoritative combat/inventory/wallet transition"] --> O["Publish stable structured GameEvent"]
    O --> P["Commit immutable recipient/world row"]
    P --> Q["Signed Turbo Stream appends to the same timeline"]
```

### 8.1 Load and render

`ApplicationController#after_sign_in_path_for` resolves a safe gameplay path. `WorldController#show` ensures current character/position, prepares World or City, remembers World context, and renders with the game layout. The layout renders current data, a server-built presence partial, and a lazy compact frame for the first global channel. `ChatChannelsController` authorizes that channel and asks `Chat::Timeline` for the current viewer's mixed history.

### 8.2 Accept or execute action

Presence refresh submits only a sort key; World applies its constant allowlist and exact-location scope. Chat creation loads the channel, authorizes a new message against it, permits only body, and delegates to `MessageDispatcher`, which rechecks social/mute/privacy/membership state before creation.

### 8.3 Complete, redirect, or hand off

Presence returns an HTML partial that replaces only the list. Chat Turbo success returns an empty successful response while the after-commit broadcast appends the message; HTML redirects and JSON returns `201`. Event creation has no browser endpoint: an authoritative producer calls `Chat::EventPublisher`, and the immutable row broadcasts only after its surrounding transaction commits. Errors return `422` surfaces, and authorization uses the shared forbidden handler.

Feature navigation hands central ownership to the target controller/view. The Character/Inventory World-shell boundary first hands intent to `WorldContextActionsController`, which owns hostile interruption and allowlisted return metadata. Login resume hands destination selection to Resume Context and exact position rendering to World/City.

### 8.4 Concurrency behavior

Chat creation uses normal database persistence and after-commit broadcasting. It has no idempotency key; repeated valid submits create repeated messages, which is current chat semantics. Game-event producers use deterministic unique keys at the authoritative transition, and matching retries converge on one row. Combat finalization remains transaction/lock protected, so event delivery cannot expose rolled-back results. Membership creation relies on database uniqueness for a channel/user pair. Presence reads a point-in-time query and a refresh may replace an older list with a newer response; no gameplay state is mutated.

## 9. HTTP and Turbo contract

| Method and path | Purpose | Success | Failure |
|---|---|---|---|
| `GET /world` | Bootstrap authenticated shell and current World/City surface | Full game-layout HTML or full HTML for Turbo redirect recovery | Login/active-character failure path |
| `GET /world/players` | Refresh exact-cell presence | Shared players-list HTML partial | Authentication/active-position failure |
| `POST /world/context` | Request Character or Inventory from the World shell | Full redirect to the allowlisted destination or the shared hostile fight | Unsupported context falls back to World; anonymous request redirects to login. |
| `GET /chat_channels/:id` | Render full or compact authorized channel history | HTML page or `chat_messages` frame without layout | Redirect/forbidden/not found |
| `POST /chat_channels/:chat_channel_id/chat_messages` | Persist an authorized message | Turbo `200`, HTML redirect, or JSON `201` | Turbo/HTML/JSON `422`, or authorization failure |
| `DELETE /users/sign_out` | Exit authenticated shell | Devise sign-out redirect | Shared authentication behavior |

The shell is HTML/Turbo-first. Chat exposes a small internal JSON response but no separately versioned public API or serializer contract. Game-event publication has no HTTP endpoint, so blueprint and Swagger/rswag coverage are not applicable.

## 10. Client-side and CSS ownership

`app/javascript/controllers/game_layout_controller.js` owns only:

- presence sort selection and 30-second partial refresh;
- browser persistence of sort/refresh preferences;
- Say-to-chat focus;
- chat refresh, local clear, and form submission affordances.

`app/javascript/controllers/chat_controller.js` and `app/javascript/controllers/chat_input_controller.js` own scroll behavior, Enter submission, successful reset/focus, and presentation-only username helpers. `app/javascript/controllers/nl_vitals_controller.js` receives display values and updates the stacked source strips and text without persisting game state.

They must not:

- decide authoritative location, channel access, mute/privacy, or identity;
- persist messages, vitals, presence, or gameplay resume state directly;
- invent channel capabilities or trust local-storage sort values;
- treat an interpolated vital as a server mutation.

`app/assets/stylesheets/application.css` is only a small reset. `controls.css` imports ordered flat modules: `tokens.css` and `primitives.css` own shared typography/colors/flat controls; `shell.css` owns the `29 / flexible / 8 / 240 / 1 / 30px` frame, stacked vitals, contextual header, and CSS/ASCII bottom controls; `chat_presence.css` owns message, game-event, and nearby-player rows. This is SRP by UI domain, with no Tailwind dependency and no nested `nl/` stylesheet folder.

The header strip reproduces the captured `#FCFAF3` band closed by the source's
1px white / 1px gold / 2px cream accent rows, and the vitals readout carries the
source `.hpfont` treatment with the HP pair in the combat color and the MP pair
in the link color. Control chrome is never redefined in `shell.css`: the top
navigation composes the `.lbut` primitive and only overrides padding plus the
current-page label color, because the source's disabled pill hides its text and
this shell navigates by text rather than by images.

Domain-SRP is the maintainability rule for all central surfaces. World/City,
Profile/Inventory, Shop, Arena/Fight, and public logs own their selectors,
composition, responsive behavior, and local Stimulus presentation. A domain
must not reuse an unrelated domain class as a styling shortcut; shared rules
move to `tokens.css` or `primitives.css` only when they express the same stable
semantic primitive in multiple domains. Similar appearance alone is not enough
to create shared ownership.

`shell.css` also owns the explicit tablet/mobile row reflow; destination feature
stylesheets own only their main-surface adaptation. This keeps responsive rules
next to the desktop component they modify instead of adding a global mobile
override layer.

Accessibility behavior:

- primary navigation uses links, message sending uses a form, and refresh uses a labeled checkbox;
- the City state uses `aria-current="page"` rather than a false action;
- Say moves keyboard focus to the chat input;
- the mixed timeline is a polite live log with semantic event times; labels and
  copy preserve meaning without color alone;
- textual names, levels, counts, vitals, flashes, and empty states do not rely on color alone.

## 11. Persistence and login resume

Character identity/vitals, exact position, gameplay context, sessions, channels, memberships, messages, immutable gameplay-event projections, and ignore relationships persist in the database. Awarded items and NV remain authoritative in Inventory and the Economy wallet/ledger respectively; the event row is only their durable timeline projection. Sort/refresh preferences persist only in browser local storage under `browser_rpg_layout`; they are not synchronized across devices or accounts.

On login or return:

- a valid Shop context resumes Shop after access revalidation;
- a valid supported City-building context resumes that building;
- invalid/removed context falls back to World;
- World renders the character's persisted exact outdoor cell or city node;
- shell preferences load independently from local storage and cannot redirect the player.

The shell does not store unsent chat input, current central-frame scroll state,
a separate toast history, or client-interpolated vitals. Recent gameplay-event
history is intentionally stored in `game_events` and reloaded with chat.

## 12. Authorization, trust boundaries, and concurrency

- Devise authentication protects shell, World presence, channels, messages, and sign-out.
- `CurrentCharacterContext` scopes World/header/presence behavior to the signed-in user's active character.
- `ChatChannelPolicy` scopes readable channels to verified users and public/member access.
- `ChatMessagePolicy` authorizes posting to writable public/member channels; `MessageDispatcher` rechecks mute/privacy/membership.
- `GameEvent.visible_to` and signed Turbo stream names enforce world/current-recipient reads; the browser cannot select an event recipient.
- Exact location and presence come from server positions, never submitted labels or DOM rows.
- Sort keys, resume contexts, and central destinations use server routes/allowlists.
- Character/Inventory controls submit logical context names only; World owns hostile interruption and never follows a submitted URL.
- After-commit broadcasts prevent uncommitted messages or events from appearing as persisted.
- Database type/audience/payload constraints and unique event keys preserve the
  immutable projection boundary under retries.
- Local storage, Turbo targets, displayed counts, and client vitals never confer authority.
- Destination features reauthenticate and revalidate their own domain access after main-frame handoff.

## 13. Failure and boundary behavior

| Condition | Required behavior |
|---|---|
| Anonymous shell/presence/chat request | Redirect to login; expose no private game state or mutation. |
| Missing playable character/position | Shared bootstrap/failure path; do not invent a displayed location. |
| No global channel | Render shell without a chat form/source; do not invent a channel. |
| Unknown presence sort | Fall back to alphabetical ascending. |
| No nearby players | Render stable empty list and count zero. |
| Presence refresh network/server failure | Keep prior list and log a warning; no gameplay mutation. |
| Blank/whitespace chat body | Return `422`; create no message. |
| Unverified, unauthorized, muted, system-channel, or privacy-blocked post | Reject without message/broadcast. |
| More than 200 history rows | Show only latest 200 in chronological display order. |
| Another user's personal event | Exclude it from history and never subscribe the viewer to that recipient's signed stream. |
| Retried matching game-event key | Return the existing row and broadcast no duplicate. |
| Reused event key with conflicting identity | Raise a publisher conflict and preserve the original immutable row. |
| Item or NV award persistence fails | Roll back that authoritative loot resolution and publish no success row. |
| First live row after empty history | Append to `chat_timeline` and hide the empty placeholder. |
| More than 10 co-located players | Show only first 10 under selected server sort. |
| Ignored relationship | Filter initial history; whisper privacy is rejected. |
| Repeated valid chat submission | Creates another message; chat requests are not idempotent. |
| Malformed local-storage JSON | Warn and use default presentation preferences. |
| Vitals client/controller failure | Server-rendered values remain visible and authoritative. |
| Unsupported captured shell control | Do not render a working-looking generic substitute. |
| Unsupported World context name | Return to World; do not start combat or follow it as a URL. |
| Tablet/mobile viewport | Reflow shell rows and contain tool strips without whole-page horizontal overflow. |

## 14. Acceptance criteria

- World and City render inside the compact top/main/presence/chat game layout after authentication.
- The header shows current character identity, level, server-rendered vitals, implemented navigation, city state, and logout.
- Presence includes only other characters at the exact zone/x/y, supports four allowlisted sorts, and caps at 10.
- Automatic presence refresh runs at 30 seconds only when enabled and remembers browser-local preference.
- Compact global chat loads at most 200 combined authorized/filtered messages and visible gameplay events, ordered chronologically, and appends both record types through Turbo Streams.
- Fight completion/XP and successful NPC item/NV loot persist once per stable producer
  key as recipient-only system rows; server-owned world announcements use the
  same history without a separate toast surface.
- An item-found row follows a committed inventory award; an NV-found row follows
  a committed wallet credit and `CurrencyTransaction`, and neither event is
  gameplay authority.
- Non-global channel histories do not receive mixed gameplay events, and one
  recipient never receives another recipient's personal row.
- Blank, muted, privacy-blocked, system-channel, unauthorized, and anonymous chat actions create nothing.
- Login resume selects only an allowlisted supported surface and preserves World/City-owned exact location.
- Unimplemented auxiliary source controls are not represented as complete behavior; client-vitals interpolation remains presentation-only.
- Central feature navigation never transfers game authority to DOM state or local storage.
- Character and Inventory shell actions can be interrupted by the authoritative same-cell hostile encounter and resume only through World-owned allowlisted return metadata.
- The `955 × 817` desktop shell geometry remains unchanged while 820px and
  390px viewports reflow the same controls without whole-page overflow.

## 15. Test strategy and required coverage

Tests are part of the feature contract. Changes require applicable model, request, policy, service, factory, view/system, session, client/CSS, and integrated World coverage. Blueprint and Swagger/rswag do not apply to this authenticated HTML/Turbo shell.

| Coverage category | Representative guarantees |
|---|---|
| Success | Layout regions, current player/vitals, exact-cell presence/sorts, mixed chat/event history/live delivery, message send, fight/item/NV projection, membership, and resume integration. |
| Failure | Blank/muted/privacy/system posts, conflicting event keys, malformed event payload/audience, missing global channel, refresh failure behavior, and missing current state. |
| Edge/null/boundary | Zero nearby players, first live row over empty history, 10-player cap, 200-entry combined history, event ordering ties, unknown sort, five-minute session boundary, malformed preferences, and vitals zero maximum. |
| Authorization | Anonymous routes, unverified social user, inaccessible membership channel, foreign channel/message attempt, cross-recipient event isolation, and current-character presence scope. |
| Retry/concurrency | Matching stable event-key retry, database uniqueness, combat finalization retry, and after-commit delivery. |

Factories must retain edge traits for channel types/membership, message visibility, verified/unverified users, recent/stale/signed-out sessions, exact/different position, ignored relationships, and vital boundaries when exercised.

Focused verification command:

```bash
bundle exec rspec \
  spec/models/game_event_spec.rb \
  spec/models/chat_message_spec.rb \
  spec/models/user_session_spec.rb \
  spec/queries/chat/timeline_spec.rb \
  spec/services/chat/event_publisher_spec.rb \
  spec/services/chat/timeline_broadcaster_spec.rb \
  spec/services/chat/message_dispatcher_spec.rb \
  spec/services/arena/combat_processor_spec.rb \
  spec/requests/chat_channels_spec.rb \
  spec/requests/chat_messages_spec.rb \
  spec/requests/inventories_spec.rb \
  spec/requests/world_spec.rb \
  spec/views/layouts/game_spec.rb \
  spec/views/game_events/_game_event_spec.rb \
  spec/views/shared/_nl_players_list_spec.rb \
  spec/views/shared/_nl_vitals_bar_spec.rb \
  spec/system/social_ui_spec.rb \
  spec/system/responsive_neverlands_ui_spec.rb
```

Policy behavior is currently exercised through request/system coverage; dedicated `ChatChannelPolicy` and `ChatMessagePolicy` specs are a justified gap for future policy changes. `responsive_neverlands_ui_spec.rb` is the focused full-shell browser contract for mobile header/main/social/bottom row sizes and whole-page overflow. Run the complete suite before release because the shell integrates authentication, sessions, World/City, character state, Turbo Streams, and social persistence.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/features/game_shell.md`
- `doc/design/areas/game_client_layout.md`
- `doc/design/features/social_chat_presence.md`
- `doc/design/features/character_vitals.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/social/observations/legacy_chat_system_analysis.md`
- `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md`
- `doc/design/launch_mvp_plan.md`

### Routes and controllers

- `config/routes.rb`
- `app/controllers/application_controller.rb`
- `app/controllers/world_controller.rb`
- `app/controllers/world_context_actions_controller.rb`
- `app/controllers/chat_channels_controller.rb`
- `app/controllers/chat_messages_controller.rb`
- `app/controllers/concerns/current_character_context.rb`

### Models and policies

- `app/models/character.rb`
- `app/models/character_position.rb`
- `app/models/user.rb`
- `app/models/user_session.rb`
- `app/models/chat_channel.rb`
- `app/models/chat_channel_membership.rb`
- `app/models/chat_message.rb`
- `app/models/game_event.rb`
- `app/models/ignore_list_entry.rb`
- `app/policies/chat_channel_policy.rb`
- `app/policies/chat_message_policy.rb`

### Services

- `app/services/game/world/resume_context.rb`
- `app/services/game/world/interrupt_action.rb`
- `app/services/game/world/combat_return_context.rb`
- `app/services/auth/user_session_manager.rb`
- `app/services/chat/message_dispatcher.rb`
- `app/services/chat/event_publisher.rb`
- `app/services/chat/timeline_broadcaster.rb`
- `app/services/chat/ignore_filter.rb`
- `app/services/chat/errors.rb`
- `app/queries/chat/timeline.rb`

### Views, helpers, client behavior, styling, and assets

- `app/views/layouts/application.html.erb`
- `app/views/layouts/game.html.erb`
- `app/views/shared/_nl_players_list.html.erb`
- `app/views/shared/_nl_vitals_bar.html.erb`
- `app/views/chat_channels/show.html.erb`
- `app/views/chat_channels/compact_messages.html.erb`
- `app/views/chat_channels/_timeline_entries.html.erb`
- `app/views/chat_messages/_chat_message.html.erb`
- `app/views/chat_messages/_form.html.erb`
- `app/views/game_events/_game_event.html.erb`
- `app/helpers/chat_messages_helper.rb`
- `app/javascript/controllers/game_layout_controller.js`
- `app/javascript/controllers/chat_controller.js`
- `app/javascript/controllers/chat_input_controller.js`
- `app/javascript/controllers/nl_vitals_controller.js`
- `app/assets/stylesheets/controls.css`
- `app/assets/stylesheets/tokens.css`
- `app/assets/stylesheets/primitives.css`
- `app/assets/stylesheets/shell.css`
- `app/assets/stylesheets/chat_presence.css`
- `app/assets/stylesheets/application.css`
- `app/assets/stylesheets/auth.css`

### Content, configuration, seeds, and schema

- `db/seeds.rb`
- `db/schema.rb`
- `db/migrate/20251121090100_create_user_sessions.rb`
- `db/migrate/20251121135236_create_chat_channels.rb`
- `db/migrate/20251121135259_create_chat_messages.rb`
- `db/migrate/20251125103725_create_social_structures.rb`
- `db/migrate/20260823180000_create_game_events.rb`
- `db/migrate/20260823220000_add_money_found_to_game_event_types.rb`

### Dependencies

- `Gemfile.lock`

### Integrated feature entry points

- `app/views/world/show.html.erb`
- `app/views/world/city_view.html.erb`
- `app/services/game/world/resume_context.rb`
- `app/controllers/world_context_actions_controller.rb`
- `app/services/game/world/interrupt_action.rb`
- `app/services/game/world/combat_return_context.rb`
- `app/services/arena/combat_processor.rb`
- `app/services/arena/npc_loot_awarder.rb`
- `app/services/arena/application_handler.rb`
- `app/services/economy/wallet_service.rb`
- `app/controllers/inventories_controller.rb`

World owns exact position, outdoor/city content, and the presence query;
destination controllers own content loaded into `main_content`. Arena Combat
owns match/reward facts and calls the injected shell-owned event publisher.
Inventory owns its mutations and uses the shared flash for request failure.
Game Shell owns the common frame and social/event presentation, not those
domain mutations.

### Factories

- `spec/factories/users.rb`
- `spec/factories/characters.rb`
- `spec/factories/character_positions.rb`
- `spec/factories/zones.rb`
- `spec/factories/user_sessions.rb`
- `spec/factories/chat_channels.rb`
- `spec/factories/chat_messages.rb`
- `spec/factories/game_events.rb`

### Specs

- `spec/models/chat_message_spec.rb`
- `spec/models/game_event_spec.rb`
- `spec/models/user_session_spec.rb`
- `spec/queries/chat/timeline_spec.rb`
- `spec/services/chat/event_publisher_spec.rb`
- `spec/services/chat/timeline_broadcaster_spec.rb`
- `spec/services/chat/message_dispatcher_spec.rb`
- `spec/services/arena/application_handler_spec.rb`
- `spec/services/arena/combat_processor_spec.rb`
- `spec/services/arena/npc_loot_awarder_spec.rb`
- `spec/requests/chat_channels_spec.rb`
- `spec/requests/chat_messages_spec.rb`
- `spec/requests/inventories_spec.rb`
- `spec/requests/world_spec.rb`
- `spec/requests/world_context_actions_spec.rb`
- `spec/views/layouts/game_spec.rb`
- `spec/views/game_events/_game_event_spec.rb`
- `spec/views/shared/_nl_players_list_spec.rb`
- `spec/views/shared/_nl_vitals_bar_spec.rb`
- `spec/system/social_ui_spec.rb`
- `spec/system/responsive_neverlands_ui_spec.rb`

## 17. Safe extension checklist

Before extending Game Shell:

1. Capture the exact Neverlands control, layout, label, refresh behavior, chat/event response, audience, and state.
2. Decide whether Shell, World/City, Chat, Vitals, or the loaded feature owns it.
3. Add only the smallest server/client contract needed for captured behavior.
4. Keep identity, exact position, channel access, messages, game-event audience,
   producer facts, and vitals server-authoritative.
5. Give each new event producer a stable source key, publish only after its
   authoritative mutation, and do not turn `GameEvent` into gameplay state.
6. Do not derive capabilities from DOM placement, local storage, display text,
   or submitted channel/location/event labels.
7. Keep client vitals interpolation presentation-only and preserve the server-rendered fallback.
8. Preserve keyboard focus, semantic controls, readable text feedback, and compact Neverlands styling.
9. Add success, failure, edge/null/boundary, authorization, retry, policy, and browser coverage where applicable.
10. Update status, non-goals, acceptance criteria, responsible files, focused checks, and version history here.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-21 | Created the implementation handbook for the persistent game frame, exact-cell presence, compact global chat, browser preferences, and resume integration. |
| 2026-07-21 | Routed World-shell Character and Inventory controls through the World-owned hostile interruption and allowlisted post-fight return boundary. |
| 2026-07-28 | Made the Neverlands game frame universal for authenticated gameplay, removed the legacy dashboard layout/CSS, applied live shell measurements and compact primitives, and kept fixed presence from blocking main-frame controls. |
| 2026-07-28 | Matched the fresh 955 × 817 frame rows, stacked CSS HP/MP strips, 240px chat/presence row, CSS/text bottom-control sequence, and documented the auxiliary chat-control states that remain Not Done. |
| 2026-07-28 | Removed source-owned runtime images and branded/service copy; preserved the measured shell contract with project-owned CSS, semantic controls, and ASCII/plain-text affordances. |
| 2026-07-28 | Added a source-faithful responsive adaptation layer at 940/720/420px while preserving the exact desktop row contract and keeping responsive ownership inside Shell CSS. |
| 2026-07-28 | Made domain-SRP the UI maintainability rule: shared tokens/primitives stay minimal, each gameplay area owns its selectors/responsive/controller presentation, and unrelated domain classes cannot be reused as styling shortcuts. |
| 2026-07-29 | Rebuilt the header band and vitals readout from a second authenticated capture, moved shell control chrome onto the `.lbut` primitive, and replaced the remaining raw hex/font literals with tokens. |
| 2026-08-23 | Added the durable mixed chat/game-event timeline from supplied Neverlands evidence: exact-time recipient fight/item rows, unbranded world announcements, stable-key publishing, bounded history, signed after-commit Turbo delivery, Arena producer handoff, and removal of the separate legacy toast path. |
| 2026-08-23 | Extended the source-backed search-result projection with typed NV awards: committed item loot remains Inventory-owned, committed NV enters the Economy wallet ledger, and both publish one retry-safe recipient row only after their authoritative mutation succeeds. |
