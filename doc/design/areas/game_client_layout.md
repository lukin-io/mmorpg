# Game Client Layout

Domain navigation: `doc/domains/shell.md` and `doc/domains/social.md`.

## Purpose

The game client layout is the persistent browser MMORPG shell. It keeps
character status, main gameplay, local presence, and chat visible enough that
movement, city navigation, combat, and social play feel connected.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/source_material.md`

Neverlands uses a frame-like layout: a main content frame, chat/messages,
buttons, and a player/location list. This project can implement the same feel
with modern rendering, but the player-facing structure should stay compact.

## Screen Model

Core shell:

- top bar: character name, level, HP/MP, current action buttons;
- main content: world map, city node, building, combat, inventory, profile;
- local presence: nearby players/current location;
- chat: messages, input, channel controls;
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
- persistent chat and local presence;
- Turbo Frames or Turbo Streams for server-rendered updates;
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
  ASCII/plain text. Project-owned images are reserved for genuine game artwork.
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
- Main-content swaps must not reset chat input, player list state, or top
  vitals unless the server state changed.
- Player-facing language is English in this project even when source labels are
  Russian in reference captures.

## Rules

- Do not start with a marketing or landing page once the player is in game.
- Main content changes, but vitals/chat/presence remain part of the game shell.
- Action buttons are context-driven by current location/state.
- Action buttons are refreshed from server-authored state and are not static
  global shortcuts.
- Text density should match a working game client, not a promotional site.
- The layout must support reload/login resume states for exact outdoor cells,
  city nodes, implemented interiors such as Shop and captured read-only city
  services, movement, and combat.
- The UI must not hide the current location or available actions.

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
