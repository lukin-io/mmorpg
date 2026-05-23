# Game Client Layout

## Purpose

The game client layout is the persistent browser MMORPG shell. It keeps
character status, main gameplay, local presence, and chat visible enough that
movement, city navigation, combat, and social play feel connected.

## Neverlands Reference

Reference material:

- `doc/design/reference/neverlands.md`
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

## Rules

- Do not start with a marketing or landing page once the player is in game.
- Main content changes, but vitals/chat/presence remain part of the game shell.
- Action buttons are context-driven by current location/state.
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
