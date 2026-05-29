# Cities And Buildings Area

## Purpose

Cities are compact illustrated hubs. They organize documented building flows
without using the outdoor movement timer.

Buildings are entered from city hotspots and expose feature-specific screens.
Current source-backed launch scope is intentionally small: Arena is implemented
as a city building path, and `Лавка` is documented as the shop building to build
next.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

Live UI reference: `doc/design/reference/neverlands_live_game_shell_ui.md`.

Observed Oktal flow:

```text
outside tile -> click Войти -> central square
central square -> trading quarter
trading quarter -> Лавка
Лавка -> Город -> trading quarter
trading quarter -> central square
central square -> outside tile
```

## Screen Model

A city node is an illustrated scene with clickable hotspots.

Each hotspot can be:

- a district transition;
- a building entry;
- an exit to the outdoor map.

City movement is immediate page/state navigation. It does not use the outdoor
travel countdown.

## Entry And Exit

City entry is offered by the current outside tile as a contextual action, such
as `Войти`.

City exit is a hotspot from a city node back to the outside map.

Building entry is a hotspot from a city node.

Building exit uses a `Город` return action that goes back to the parent city
node.

## Live City UI Observation

The 2026-05-25 Forpost capture confirms the city node interaction model:

- city page refreshes the local player list;
- top shell shows character, vitals, quest/profile/inventory/current-city
  controls, and exit;
- city art is the main surface;
- hotspots are absolute-positioned image controls;
- hover swaps the hotspot art to a highlighted variant and shows a tooltip;
- each hotspot submits a server-issued action key;
- building return generates fresh city hotspot action keys.

Observed Forpost hotspots included arena, `Лавка`, city exit, district
transitions, and several non-MVP buildings such as tavern, workshop, hospital,
and guard tower. Do not implement those extra buildings from names alone.
Capture their behavior first or leave them as inactive/blocked flavor.

## City Node Rules

- A city is a graph of named nodes, not a coordinate grid.
- A city node has a stable key, title, background image, and hotspot list.
- Every city navigation refreshes the available outgoing hotspots.
- Local player/location presence refreshes after navigation.
- Hotspots must have keyboard-accessible equivalents and text labels in the
  Rails implementation; source image maps are a visual reference, not enough UI
  by themselves.
- City nodes can show a disabled/current marker in the top action area.
- District-to-district navigation is immediate unless a future city explicitly
  defines a delay.

## Building Rules

- A building has a stable key and parent city node.
- A building page has its own feature UI.
- A building page provides a `Город` return action.
- Arena and `Лавка` are the only current building flows.
- Other building names seen in raw city captures are not implementation scope
  until their Neverlands behavior is captured into feature/area docs.
- Shop access is a building flow, not a generic vendor NPC dialogue.
- Feature-specific state should live inside the building flow.

## Starter Area

Use the observed city flow shape as the starter reference, but keep only the
source-backed MVP buildings:

| Node | Key | Important Hotspots |
| --- | --- | --- |
| City Node | `starter.city` | arena, shop, exit |
| Arena | `starter.arena` | arena rooms, applications, player/team/NPC fights, return to city |
| Shop | `starter.shop` | buy, sell, licenses, novice goods, return to city |

Future city districts and buildings must be added by capture-first expansion,
not by importing generic town-service assumptions.

## Feature Hooks

- `features/economy_trading_shops.md`
- `features/social_chat_presence.md`
- `features/npcs_quests.md`
- `features/items_inventory_equipment.md`
- `areas/arena.md`

## Out Of Scope

- City movement as grid movement.
- Direct `/shop` style primary navigation that bypasses the city node.
- Town NPC service roles inside buildings before source capture.
- Marketing-style city landing pages.
