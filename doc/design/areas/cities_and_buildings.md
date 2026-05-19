# Cities And Buildings Area

## Purpose

Cities are compact illustrated hubs. They organize shops, banks, taverns,
arenas, transport stations, trainers, quest NPCs, and social presence without
using the outdoor movement timer.

Buildings are entered from city hotspots and expose feature-specific screens.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

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

## City Node Rules

- A city is a graph of named nodes, not a coordinate grid.
- A city node has a stable key, title, background image, and hotspot list.
- Every city navigation refreshes the available outgoing hotspots.
- Local player/location presence refreshes after navigation.
- City nodes can show a disabled/current marker in the top action area.
- District-to-district navigation is immediate unless a future city explicitly
  defines a delay.

## Building Rules

- A building has a stable key and parent city node.
- A building page has its own feature UI.
- A building page provides a `Город` return action.
- Shops, banks, taverns, trainers, and transport stations are buildings, not
  top-level global pages.
- Feature-specific state should live inside the building flow.

## Oktal Starter Area

Use Oktal as the starter design reference:

| Node | Key | Important Hotspots |
| --- | --- | --- |
| Central Square | `oktal.central_square` | tavern, bank, watchtower, residential quarter, trading quarter, exit |
| Trading Quarter | `oktal.trading_quarter` | shop, market, junk dealer, numismatics, airship station, central square, industrial quarter |
| Shop | `oktal.shop_3` | buy, sell, licenses, novice goods, return to city |

Names can be adapted to original project lore, but the graph shape and flow
should stay close to the reference.

## Feature Hooks

- `features/economy_trading_shops.md`
- `features/social_chat_presence.md`
- `features/npcs_quests.md`
- `features/items_inventory_equipment.md`
- `areas/arena.md`

## Out Of Scope

- City movement as grid movement.
- Direct `/shop` style primary navigation that bypasses the city node.
- Marketing-style city landing pages.
