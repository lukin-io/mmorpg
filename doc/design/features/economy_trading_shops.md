# Economy, Trading, And Shops

## Purpose

The economy lets players turn combat, gathering, crafting, and exploration into
practical choices. Shops are city buildings first.

## Neverlands Reference

Primary reference: `doc/design/reference/neverlands.md`.

Observed shop flow:

```text
outside tile -> city -> trading quarter -> Лавка -> shop tabs/items
```

The shop page renders a building shell, then category/item content is loaded
inside the shop UI. Items show price, stock, properties, requirements, and buy
availability.

## Player Experience

The player enters a shop from a city hotspot, chooses a tab/category, sees item
listings, checks requirements, buys available goods, sells inventory, then
returns to the city via `Город`.

## Currency

Core currency:

- normal money for shops/trade;
- optional premium currency only if it stays outside core power progression.

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

## Trading Rules

Core:

- direct player trade;
- vendor/shop buy and sell.

## State Concepts

- wallet;
- transaction;
- shop;
- shop stock;
- direct trade session.

## Interactions

- `areas/cities_and_buildings.md`: shops are entered through city
  hotspots.
- `features/items_inventory_equipment.md`: all goods are inventory items.
- `features/gathering_professions.md`: crafted/gathered goods enter economy.
- `features/social_chat_presence.md`: direct trade can use player identity and
  local presence.

## Out Of Scope

- Standalone global shop route as the primary player path.
- Premium store as a core GDD requirement.
