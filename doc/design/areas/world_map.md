# World Map Area

## Purpose

The world map is the outdoor exploration surface. It is where players travel
between coordinates, discover local actions, meet nearby players, encounter
hostile NPCs, gather resources, and enter cities or buildings offered by the
current tile.

## Neverlands Reference

Primary reference: `doc/flow/neverlands_live_movement.md`.

Observed Neverlands behavior:

- the main gameplay frame renders a grid of map tiles;
- only server-offered destination tiles are clickable;
- each destination has its own short-lived action key;
- movement has an accepted travel duration, observed as 30 seconds near Oktal;
- the browser shows a cursor animation and countdown during movement;
- local presence refreshes after movement completion;
- contextual buttons such as `Войти` appear from the current tile state.

## Screen Model

The world map screen is a compact game surface:

- top character/vitals/action bar;
- tile grid centered on the player;
- visible clickable movement markers;
- player cursor or travelling sprite;
- countdown overlay during movement;
- local player list/presence panel;
- chat frame or chat bar.

It should feel like a utilitarian MMORPG client, not a large marketing page.

## Entry And Exit

Players enter the world map after login/character selection, after leaving a
city, after respawn, or after completing travel.

Players leave the world map by:

- entering a city through a contextual action;
- entering a tile building when offered;
- starting combat or another feature overlay;
- using teleport/respawn systems when available.

## Available Actions

The map can offer:

- movement to nearby tiles;
- character profile;
- inventory;
- enter city/building;
- look around;
- gather;
- fish;
- dig;
- drink/use terrain feature;
- quest interaction;
- hostile encounter or attack;
- local NPC dialogue.

The server decides which actions exist for the current finalized location.

## Rules

- Outdoor movement is coordinate-based.
- Destination availability is server-authored.
- Movement is accepted by the server before the UI enters travelling state.
- Movement completion updates the authoritative coordinate.
- Reload during travel resumes the travelling state from server time.
- The map does not invent passability in the browser.
- The local player list refreshes after movement completion.

## Area Graph

The outdoor map is a coordinate graph. In the starter reference area:

```text
1019,1025 -> 1018,1025
1019,1025 -> Oktal city entry action
```

The graph may later expand to more coordinates, roads, terrain costs, and
encounter tables, but starter implementation should remain deterministic.

## Feature Hooks

- `features/movement.md`
- `features/social_chat_presence.md`
- `features/gathering_professions.md`
- `features/npcs_quests.md`
- `areas/cities_and_buildings.md`
- `features/combat.md`

## Out Of Scope

- Procedural world generation for the core map.
- Pathfinding across many tiles as the first movement experience.
- Decorative map layers that do not affect available actions.
