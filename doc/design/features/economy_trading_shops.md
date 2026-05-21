# Economy, Trading, And Shops

## Purpose

The economy lets combat rewards, inventory, and city shops become practical
choices. Shops are city buildings first.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_lavka_shop.md`

Observed shop flow:

```text
outside tile -> city -> trading quarter -> Лавка -> shop tabs/items
```

The shop page renders a building shell, then category/item content is loaded
inside the shop UI. Items show price, stock, properties, requirements, and buy
availability.

Do not model this as a global marketplace/kiosk route. The Neverlands-shaped
surface is a city building with tabs for buying goods, licenses, selling goods,
and novice goods.

## Player Experience

The player enters a shop from a city hotspot, chooses a tab/category, sees item
listings, checks requirements, buys available goods, sells inventory, then
returns to the city via `Город`.

## Currency

Core currency is normal money for shops.

Currency should be visible in inventory/shop contexts and recorded as part of
economy state.

## Shop Rules

- Shops are buildings attached to city nodes.
- Shops can have category tabs.
- Shop inventory can have stock counts.
- Items show price, requirements, and properties.
- Buying checks money, stock, item requirements, and inventory capacity.
- Selling checks ownership and whether the item can be sold.
- Shop actions refresh the visible item list and current action keys.

## Known But Deferred

- Neverlands has direct player trading, but the exact flow, licenses,
  restrictions, UI states, and settlement rules still need source capture.
- Do not keep or rebuild a generic two-panel trade session before that capture.

## State Concepts

- wallet;
- transaction;
- city building shop;
- shop category;
- shop stock with current and maximum counts;
- shop license good.

## Interactions

- `areas/cities_and_buildings.md`: shops are entered through city
  hotspots.
- `features/items_inventory_equipment.md`: all goods are inventory items.
- `features/social_chat_presence.md`: future direct trade capture should account
  for player identity and local presence.

## Out Of Scope

- Standalone global shop route as the primary player path.
- Cash or premium currency until it has a dedicated Neverlands source capture
  and an approved scope.
- Direct player trading until it has a dedicated Neverlands source capture and
  approved implementation shape.
