# Cities And Buildings Area

## Purpose

Cities are compact illustrated hubs. They organize shops, banks, taverns,
arenas, transport stations, trainers, quest NPCs, and social presence without
using the outdoor movement timer.

Buildings are entered from city hotspots and expose feature-specific screens.

## Neverlands Reference

Primary reference: `doc/flow/neverlands_live_city_movement.md`.

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

## Related Implementation Files

Models:

- `app/models/city_hotspot.rb`
- `app/models/tile_building.rb`
- `app/models/zone.rb`
- `app/models/character_position.rb`

Controller and services:

- `app/controllers/world_controller.rb`
- `app/services/game/world/city_hotspot_service.rb`
- `app/services/game/world/tile_building_service.rb`
- `app/helpers/world_helper.rb`

Views and JavaScript:

- `app/views/world/city_view.html.erb`
- `app/views/world/_city_view.html.erb`
- `app/views/world/_city_hotspot.html.erb`
- `app/views/world/_actions.html.erb`
- `app/javascript/controllers/city_controller.js`
- `app/javascript/controllers/city_view_controller.js`

Assets and data:

- `app/assets/images/city.png`
- `app/assets/images/arena.png`
- `app/assets/images/workshop.png`
- `app/assets/images/clinic.png`
- `app/assets/images/gate.png`
- `db/migrate/20251216091841_create_tile_buildings.rb`
- `db/migrate/20251218132823_create_city_hotspots.rb`
- `db/migrate/20251218155628_add_dimensions_to_city_hotspots.rb`
- `db/seeds.rb`

Specs:

- `spec/models/city_hotspot_spec.rb`
- `spec/models/tile_building_spec.rb`
- `spec/services/game/world/city_hotspot_service_spec.rb`
- `spec/services/game/world/tile_building_service_spec.rb`
- `spec/views/world/_city_view_spec.rb`
- `spec/system/world_map_spec.rb`
- `spec/requests/world_spec.rb`
