# Game Client Layout

## Purpose

The game client layout is the persistent browser MMORPG shell. It keeps
character status, main gameplay, local presence, and chat visible enough that
movement, city navigation, combat, and social play feel connected.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_game_shell_ui.md`
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
- The layout must support reload/resume states for movement and combat.
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
