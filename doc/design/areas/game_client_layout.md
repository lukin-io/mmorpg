# Game Client Layout

## Purpose

The game client layout is the persistent browser MMORPG shell. It keeps
character status, main gameplay, local presence, and chat visible enough that
movement, city navigation, combat, and social play feel connected.

## Neverlands Reference

Reference material:

- `doc/flow/13_game_layout.md`
- `doc/features/neverlands_inspired_chat.md`
- `doc/flow/neverlands_live_movement.md`
- `doc/flow/neverlands_live_city_movement.md`

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

## Related Implementation Files

Layouts and shared views:

- `app/views/layouts/game.html.erb`
- `app/views/layouts/application.html.erb`
- `app/views/shared/_nl_vitals_bar.html.erb`
- `app/views/shared/_nl_players_list.html.erb`
- `app/views/shared/_online_players.html.erb`
- `app/views/shared/_online_players_compact.html.erb`
- `app/views/world/_mini_chat.html.erb`

JavaScript and channels:

- `app/javascript/controllers/game_layout_controller.js`
- `app/javascript/controllers/layout_stack_controller.js`
- `app/javascript/controllers/nl_vitals_controller.js`
- `app/javascript/controllers/chat_controller.js`
- `app/javascript/controllers/presence_panel_controller.js`
- `app/channels/realtime_chat_channel.rb`
- `app/channels/presence_channel.rb`
- `app/channels/vitals_channel.rb`

Controllers and services:

- `app/controllers/world_controller.rb`
- `app/controllers/session_pings_controller.rb`
- `app/services/presence/publisher.rb`
- `app/services/presence/friend_broadcaster.rb`
- `app/jobs/session_presence_job.rb`

Specs:

- `spec/views/layouts/game_spec.rb`
- `spec/views/shared/_nl_vitals_bar_spec.rb`
- `spec/views/shared/_nl_players_list_spec.rb`
- `spec/views/shared/_online_players_compact_spec.rb`
- `spec/channels/realtime_chat_channel_spec.rb`
- `spec/channels/presence_channel_spec.rb`
- `spec/requests/session_pings_spec.rb`
