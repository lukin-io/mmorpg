# World Map Area

## Purpose

The world map is the outdoor exploration surface. It is where players travel
between coordinates, discover local actions, meet nearby players, encounter
hostile NPCs, and enter cities or buildings offered by the current tile.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

Observed Neverlands behavior:

- the main gameplay frame renders a grid of map tiles;
- only server-offered destination tiles are clickable;
- each destination has its own short-lived action key;
- movement has an accepted travel duration, observed as 30 seconds near Oktal;
- the browser shows a cursor animation and countdown during movement;
- local presence refreshes after movement completion;
- contextual buttons such as `Войти` appear from the current tile state.
- local outdoor actions can be interrupted by bot ambushes and hand the player
  into the normal fight screen;
- after outdoor bot combat is finished, the player returns to the same outdoor
  coordinate with fresh action tokens.

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
city, after respawn, or after completing travel. Login is a resume action: when
the account already has a character, the post-login entry point opens the world
screen and renders the character's persisted cell. A spawn point is only used
to bootstrap a character with no saved location.

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
- hostile encounter or attack;
- city or building entry.

The server decides which actions exist for the current finalized location.
Future local actions must be documented from Neverlands before implementation.

## Rules

- Outdoor movement is coordinate-based.
- Destination availability is server-authored.
- Movement is accepted by the server before the UI enters travelling state.
- Movement completion updates the authoritative coordinate.
- Reload during travel resumes the travelling state from server time.
- The map does not invent passability in the browser.
- The local player list refreshes after movement completion.

## World State Persistence

The world map must be reproducible from database state on every request. The
browser may animate and submit choices, but it must not own world state.

Persistent state sources:

- finalized character location: current zone and coordinate;
- movement commands: offered and active movement, including action key, source
  coordinate, target coordinate, and travel timestamps;
- map tile templates: terrain, passability, and static map metadata;
- tile NPCs: spawned NPC identity, HP, defeated state, respawn, and template;
- tile entrances: city gates and other source-backed enterable structures
  attached to a coordinate.

Player-facing persistence rule: closing and reopening the browser must never
reset the player to a default or browser-held position. The server reloads the
same finalized location record. If a movement was active while the browser was
closed, the server either resumes it or finalizes it from movement command
state.

## Rails-Friendly Solution

The world map uses a single authoritative tile-state/action-offer layer.

Pipeline for every world map request:

1. Complete due movement.
2. Load current finalized character location.
3. Resolve current tile state.
4. Materialize any generated NPC before rendering it.
5. Build movement offers and contextual action offers.
6. Before completing a mutating outdoor action, evaluate source-backed hostile
   encounter rules for the current tile.
7. Render only the action offers returned by the server, or hand off to combat
   if the accepted action triggered an ambush.

Suggested action-offer fields:

```text
character
zone
coordinate
action type
target type
target id
action key
status
expires at
accepted at
completed at
error message
metadata
```

Action examples:

| Action | Persistent Target | Handler |
| --- | --- | --- |
| Move | movement command | movement acceptance service |
| Attack/Talk | tile NPC | combat or dialogue service |
| Enter city/building/dungeon | tile entrance | building or city transition service |

Validation rules:

- action key must match current character, zone, coordinate, action type, and
  target;
- stale offers are rejected;
- offers are cancelled/reissued when the authoritative map state changes;
- generated NPC state is materialized before any offer is issued;
- accepted actions write a result row or status update for audit and replay.
- if an accepted outdoor action triggers a hostile NPC attack, the original
  action does not silently complete; the response becomes a combat state and
  return context points back to the same world coordinate.

## Outdoor Ambush Handoff

The May 20, 2026 outdoor capture near `Окрестность Форпоста` showed both
outdoor local requests returning or refreshing into bot combat against two
`Чумная крыса` NPCs. The fight used the same combat client and finish-result
step as arena fights, then returned to `m_1001_999`.

Design rules:

- hostile NPC checks belong in the server-side outdoor action pipeline;
- ambushes are not a separate mini-game or modal;
- the fight stores the source context needed to return to the same world cell;
- profile/location state should show the active fight while combat is active
  and clear it after the finish action;
- local presence remains the current outdoor room after return.

## Area Graph

The outdoor map is a coordinate graph. In the starter reference area:

```text
1019,1025 -> 1018,1025
1019,1025 -> Oktal city entry action
```

The graph may later expand to more coordinates, roads, and terrain costs, but
starter implementation should remain deterministic and source-backed.

## Feature Hooks

- `features/movement.md`
- `features/social_chat_presence.md`
- `features/npcs_quests.md`
- `areas/cities_and_buildings.md`
- `features/combat.md`

## Out Of Scope

- Procedural world generation for the core map.
- Pathfinding across many tiles as the first movement experience.
- Decorative map layers that do not affect available actions.
