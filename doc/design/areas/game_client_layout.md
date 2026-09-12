# Game Client Layout

Domain navigation: [Shell](../../domains/shell.md) and
[Social](../../domains/social.md).

The [Game Shell handbook](../../features/game_shell.md) owns current frame,
vitals and navigation behavior; its
[event catalog](../../features/game_shell.md#gameplay-event-catalog) owns
chat/fight-history destinations and emphasis. Area-specific content and artwork
remain with each consuming feature linked through those domains.

## Purpose

The game client layout is the persistent browser MMORPG shell. It keeps
character status, main gameplay, local presence, and chat visible enough that
movement, city navigation, combat, and social play feel connected.

This document also owns the shared adaptive UI requirements for every gameplay
surface. [ARTWORK.md](../../ARTWORK.md#shared-scene-image-standard) owns image
production, composition and dimensions; feature handbooks describe what has
actually shipped and been verified against these requirements.

## Gameplay fidelity and presentation ownership

The September 10 user direction makes adaptive, accessible, maintainable UI a
project requirement. Neverlands establishes game rules, feature identities,
available information, action meanings and state transitions. This project
owns modern implementation, original artwork and presentation across devices.
The absence of responsive behavior in Neverlands is not a reason to omit it.

Captured dimensions, fonts, colors and placement inform the compact visual
baseline. They do not require copying fixed desktop widths, clipped buildings,
tiny controls or obsolete browser behavior. Reflow, spacing, control sizing,
image composition and breakpoints may improve usability while preserving the
same game information, decisions, confirmations and authoritative outcomes.
Explicitly adopted local contracts, such as the shared City/entrance image
profile, remain binding until deliberately revised in their canonical owner.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- `doc/design/reference/source_material.md`

Neverlands uses a frame-like layout: a main content frame, chat/messages,
buttons, and a player/location list. This project can implement the same feel
with modern rendering, but the player-facing structure should stay compact.

## Screen Model

Core shell:

- top bar: character name, level, HP/MP, current action buttons;
- main content: world map, city node, building, combat, inventory, profile;
- local presence: nearby players/current location;
- chat: one chronological history of ordinary messages from the current
  cell/room, recipient-only gameplay results, and game-wide announcements, plus
  input and captured chat controls;
- exit/logout control.

The 2026-05-25 live shell capture confirms that profile, inventory, city,
building, shop, arena, and combat all replace only the main gameplay surface.
Chat, presence, top vitals, and contextual controls remain part of the game
client shell.

The 2026-07-20 city-service pass confirms that specialized buildings keep this
same shell and render dense feature tables inside the main surface: market
listings and stall controls, scheduled airship rows, hospital service tabs and
stock, and pharmacy resource rows. Preserve the compact table-first hierarchy;
do not turn each service into an unrelated full-page dashboard.

## Modern Rails Shell Decision

Neverlands frames are not a technical target. The MVP should preserve the
product contract with modern Rails primitives:

- one authenticated game layout;
- one replaceable main content region for world, city, building, profile,
  inventory, arena, combat, and results;
- persistent top vitals and context actions;
- persistent mixed chat/game-event history and local presence;
- Turbo Frames or Turbo Streams for server-rendered updates;
- authenticated current-location polling for ordinary chat, with signed
  recipient/world game-event streams retained in the same timeline;
- Stimulus controllers for timers, hotspot hover/focus, form disabling,
  chat shortcuts, panel toggles, and local visual previews.

Do not implement the old frameset or iframe layout. It makes state ownership
harder, harms accessibility, and does not add useful game-design fidelity. Use
the source-era frames only as evidence for what should stay persistent across
main-content transitions.

Tailwind CSS is not required for launch MVP. The current Rails app already has
a Neverlands-style CSS token surface. Introduce Tailwind only if a specific
screen rewrite proves it reduces real maintenance cost without replacing the
compact operational feel with a generic modern dashboard.

## Frame And Responsive Adaptation

The captured desktop shell keeps its status header, flexible main gameplay
pane, social row, and bottom controls in one frame. The source `main_top`
measurement includes the status header; the local Rails layout renders that
header and main pane as adjacent rows. World therefore uses their combined
client height when choosing complete 100px map rows. Raster density is separate
from those CSS dimensions: an optional 200px World cell image still occupies
one 100px cell, selected by the browser through `image-set`. Its 100px base
remains required. This presentation choice does not alter frame fitting,
coordinates, reachability or travel timing. The separate width and
height measurements must not change gameplay coordinates, movement offers, or
cell authority.

World owns the bounded odd-cell viewport and its recentering observer; Shell
owns the surrounding row allocation. The observer responds to header/main
size changes and disconnects with the map. A chat allocation change may alter
the number of complete visible rows without resizing individual cells or
replacing movement state. Source measurements do not establish one universal
browser-height formula or a shipped drag-resizer control.

Tablet/mobile adaptation is a local requirement. At narrow widths the shell
reflows the header and bottom controls and stacks the social regions; the main
pane remains the owning feature's scroll area. The map retains complete cells,
a centered current position, and touch panning without whole-page horizontal
overflow. `doc/features/game_shell.md` records the verified desktop/mobile
dimensions and `doc/features/world.md` owns map behavior.

## Adaptive UI requirements

These are shared product requirements for new or materially changed UI,
including desktop layouts. They define the target; they are not a blanket
claim that every existing screen already passes. Feature-owned exceptions and
remaining implementation gaps must be recorded in the responsible handbook.

| ID | Required behavior |
|---|---|
| `UI-ADAPT-001` — available space | Layout responds to its actual container width and height, including browser resize, orientation changes and a smaller gameplay pane. Use fluid sizing with deliberate maximum widths; support at least 320 CSS pixels of viewport width and wide desktop screens. Breakpoints follow content needs, not device names or browser detection. |
| `UI-ADAPT-002` — reflow and overflow | Reflow text, controls and panels before introducing scrolling. No page-level horizontal overflow or inaccessible controls. Wide data tables, category strips and coordinate-based maps may have an explicitly owned scroll region when reflow would lose meaning; all content remains reachable by touch and keyboard. Clipping overflow is not a fix for missing information. |
| `UI-ADAPT-003` — content and state | Preserve the same location, information, available actions, selected filters and authoritative state across layout changes. Resizing or rotating must not submit an action, repeat a transaction or restart gameplay. UI rearrangement cannot change permissions, prices, stock, coordinates or timers. |
| `UI-ADAPT-004` — readable UI | Keep text as semantic HTML that wraps and supports browser zoom to 200%. Do not shrink the whole interface with a transform to fit a phone. Long names, larger balances, empty states and errors must remain readable without obscuring the action needed to continue. |
| `UI-ADAPT-005` — input and access | Each action has a meaningful accessible name, visible keyboard focus and keyboard/touch activation. Essential information cannot depend only on hover or color. Aim for 44 × 44 CSS-pixel controls for coarse pointers; dense map silhouettes that cannot meet this size need an equivalent usable named action affordance, not overlapping invisible hit boxes. Labels/popovers remain inside the visible area and can be dismissed. |
| `UI-ADAPT-006` — images and geometry | Apply the image profile appropriate to the asset's role. City/entrance scenes follow `ART-SCENE-001`; interactive art, hotspot buttons, arrows and hover crops share one coordinate transform. Keep tooltips and ordinary form/text controls readable outside that transform. Do not crop a building to satisfy a display size or stretch an illustration independently of its targets. |
| `UI-ADAPT-007` — short viewports | On landscape phones, short windows or with an on-screen keyboard, navigation, form inputs, confirmations and resulting feedback remain reachable. Compact or scroll the owning panel as needed; decorative artwork must not make required controls inaccessible. |
| `UI-ADAPT-008` — shared implementation | Reuse shared tokens, controls and applicable image consumers. Feature styles own their reflow/scroll decisions. Use CSS layout first and focused observation only when measurement is necessary; resize handling is bounded and cleans up on Turbo disconnect. Do not maintain separate mobile gameplay logic or render a second independent copy of state. |

The image profile applies to scene illustrations, not every image. Equipment,
portraits, category atlases and World cells retain their role-specific ratios
and coordinate contracts in ARTWORK.md and their domain designs. A wide scene
may scale uniformly; ordinary forms and text must reflow.

### Adaptive UI acceptance

Use real content and a real browser for a changed player-facing flow. The
agent performs the final acceptance pass after automated checks pass, under
[AGENTS.md](../../../AGENTS.md#manual-browser-acceptance). The
following is the project's acceptance sample, not a required CSS breakpoint
list or a claim about Neverlands device support:

| Viewport / mode | Main check |
|---|---|
| 320 × 740 | Minimum-width reflow; all actions and full scene remain reachable |
| 390 × 844 | Phone portrait; touch targets, labels, owned scrolling and core action/return |
| 820 × 900 | Tablet; intermediate panel and control layout |
| 1366 × 768 | Desktop; information hierarchy, mouse/keyboard and compact composition |
| 1920 × 1080 | Wide desktop; bounded images and useful content width |
| 844 × 390 | Short landscape; form, feedback and navigation reachability |
| 200% browser zoom | Text/control reflow and focus reachability on the changed surface |

Also resize continuously across the component's actual breakpoints; isolated
screenshots at these sizes do not prove intermediate layouts. Check a long
label, an empty/error state and the feature's primary action, result and return.
For interactive images, sample roofs/walls/annexes and adjacent empty space,
then activate a real hotspot; a clickable center alone does not prove alignment.

Automated coverage should assert the changed contract at representative sizes
and failure boundaries; it need not duplicate every manual screenshot. Record
manual and automated evidence separately, including input mode and actual
viewport. Reuse still-applicable checks and report any untested requirements.
The launch plan's `RESPONSIVE-001` owns rollout status. Earlier 390px/820px
checks remain valid within their recorded scope; they do not establish the
new minimum-width, short-landscape, coarse-pointer or zoom requirements.

## UI Style Maintainability And Domain SRP

UI maintainability follows single responsibility by gameplay domain:

- Shared tokens and primitives own only genuinely cross-domain values and
  controls: typography, colors, borders, compact buttons, form baselines, and
  accessibility helpers.
- The persistent shell, chat/presence, World/City, Profile/Inventory,
  Shop, Arena/Fight, public logs, and the admin-only Manage surface each own
  their layout, component selectors, responsive rules, and local interaction
  presentation.
- A feature must not borrow another domain's selector merely because it looks
  similar. For example, Shop tabs must not depend on Arena tab classes. If two
  domains need the same semantic primitive, promote the smallest stable rule to
  the shared primitive layer and keep each domain's composition local.
- Desktop and responsive rules stay beside the component/domain they modify.
  Do not create an unrelated global mobile override layer.
- Stimulus follows the same ownership boundary: each controller owns local
  presentation behavior only, while server-rendered state remains authoritative.
- Stylesheets remain a flat, discoverable domain set. Do not add an `nl/`
  subfolder or one monolithic stylesheet that makes ownership ambiguous.
- Source image controls are rebuilt with maintainable CSS plus suitable
  ASCII/plain text. The user's explicit City exception permits original
  generated route-arrow decorations inside semantic buttons; accessible names,
  server actions and focus behavior remain owned by those buttons. Decorations
  are non-interactive, scale with their scene and are never painted into its
  background. This does not permit source image copying or automatically
  replace other controls with bitmap assets.
- World owns `world.css`, the fixed-cell map, movement affordances, outdoor
  entrance landmarks, and linked-location interior geometry. Shop owns its
  catalog and commerce layout after a location hotspot hands off to it; neither
  domain reaches into the other's selectors.
- Manage owns `manage.css`, its compact tables/forms/navigation and responsive
  overflow. It composes shared controls but does not reuse gameplay layout
  selectors or join the persistent game shell.

Domain SRP does not require one stylesheet per partial. It requires one clear
owner for every selector and prevents cross-feature coupling. A change to one
gameplay area should normally be testable and reviewable without modifying an
unrelated area's stylesheet.

## UI/AX Rules

- Image hotspots must also be focusable controls with labels, visible focus
  state, and keyboard activation.
- Icon-only controls need text alternatives or titles that expose the action.
- Timers, unavailable states, combat waiting, shop errors, and movement locks
  must be visible as text, not only color or icon changes.
- Form submission should disable only the affected action group and then
  refresh from server state.
- The current page/context action should be visibly disabled.
- Main-frame swaps must not reset chat input, player list state, or top
  vitals unless the server state changed.
- Transient request flashes must not remain attached to the surrounding shell
  after main-content navigation or return through browser history. The local
  dismissal/lifetime contract is owned by
  [Game Shell](../../features/game_shell.md#flash-message-lifecycle); durable
  game-event rows keep their separate persistence contract.
- When navigation reloads the full shell, restore already-delivered ordinary
  rows only within the current login's bounded browser buffer. A fresh login
  starts an empty ordinary buffer; durable personal/world game events reload
  independently. The local shell does not persist unsent drafts or main-pane
  scroll positions.
- Clear visible chat must preserve the timeline and subsequent delivery; it
  is not a request to delete stored messages or gameplay records.
- Authoritative fight completion and successful item/NV-search feedback must
  remain readable in the persistent history after a main-content swap or
  reload; a transient toast is not the only feedback surface.
- Personal and world rows need visible textual labels in addition to their
  source-derived color roles, and event bodies remain escaped text.
- Player-facing language is English in this project even when source labels are
  Russian in reference captures.

## Rules

- Do not start with a marketing or landing page once the player is in game.
- Main content changes, but vitals/chat/presence remain part of the game shell.
- Chat and gameplay-event rows share one dense chronology; do not create a
  separate notification center or parallel event panel for captured system
  results.
- Action buttons are context-driven by current location/state.
- Action buttons are refreshed from server-authored state and are not static
  global shortcuts.
- Text density should match a working game client, not a promotional site.
- The layout must support reload/login resume states for exact outdoor cells,
  city nodes, village interiors, Shop, captured read-only city services,
  validated Arena rooms, movement, and combat.
- The UI must not hide the current location or available actions.

Room entry must update the surrounding presence label, count, and player list
with the saved room, including when automatic refresh is disabled. The local
implementation prepares City-building presence after saving context and uses
full-shell Arena entry. Runtime ownership and coverage belong in
`doc/features/game_shell.md`.

## Feature Hooks

- `features/character_vitals.md`
- `features/social_chat_presence.md`
- `features/movement.md`
- `features/combat.md`
- `areas/world_map.md`
- `areas/cities_and_buildings.md`

## Out Of Scope

- A separate public product homepage as part of the gameplay shell.
- Decorative panels that do not carry gameplay information.
