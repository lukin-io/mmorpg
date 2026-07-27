# Economy, Trading, And Shops

## Purpose

The economy lets combat rewards, inventory, and city shops become practical
choices. Shops are city buildings first.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/neverlands_live_lavka_shop.md`
- `doc/design/reference/neverlands_live_game_shell_ui.md`
- `doc/design/reference/neverlands_live_inventory_items.md`
- `doc/design/reference/neverlands_live_city_movement.md`

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

The 2026-05-25 shell/UI capture confirms the shop is a normal building shell:
top vitals/actions remain visible, `Город` is the return action, shop content
loads inside the main surface, and each AJAX response refreshes profile,
inventory, return, and shop action keys.

The 2026-07-20 city pass distinguishes three additional commerce shapes from
the launch `Лавка`:

- the Junk Dealer uses the same shop shell and modes under a different building
  key, although its stock was not loaded and must not be assumed identical;
- the Market is a player-listing and rented-stall system with listing filters,
  stall inventory, a stall account, skill-gated mass tiers, 30-day rent, and a
  tier-dependent sale tax;
- the Numismatics Shop is a single-commodity listing book with count, unit
  price, total, and per-listing buy offers.

These source-captured variants now have city-hotspot entry and read-only MVP
screens so the city graph does not lead to generic or invented services. They
do not turn the MVP shop into a global marketplace: only the documented
`Лавка` loop can mutate inventory, stock, or money.

## Player Experience

The player enters a shop from a city hotspot, chooses a tab/category, sees item
listings, checks requirements, buys available goods, sells inventory, then
returns to the city via `Город`.

## Currency

Core currency is normal money for shops.

Currency should be visible in inventory/shop contexts and recorded as part of
economy state.

NV balances and transaction amounts use fixed `decimal(12,2)` storage. This is
required by the captured fractional prices and prevents inventory transfers or
player-sale settlement from truncating `12.50` NV to an integer. A forward-only
migration repairs databases created when those columns were historically
materialized as integers; rollback is intentionally blocked because it would
discard fractional balances.

## Shop Rules

- Shops are buildings attached to city nodes.
- Shops can have category tabs.
- Shop inventory can have stock counts.
- Items show price, requirements, and properties.
- Buying checks money, stock, purchase-specific gates when captured, and
  inventory capacity. Equipment/use requirements are still displayed but are
  not automatically purchase blockers.
- Selling checks ownership and whether the item can be sold.
- Selling rejects zero-durability items even when they are not equipped.
- Shop actions refresh the visible item list and current action keys.
- Shop tabs are buy goods, licenses, sell goods, and novice goods.
- Buy/sell/novice modes use category filters plus level and price filters.
- License mode hides the category/price filters and loads license goods.
- Item rows show player wallet, carried mass, shop funds, stock, price,
  properties, requirements, and unavailable reasons.
- Buying and selling are confirmable, item-specific, server-authorized actions.
- After any shop request, replace the item list from the server response
  instead of mutating it only in browser state.
- Purchase eligibility is separate from equip/use eligibility. A shop row can
  show unmet item requirements in red and still expose `Buy` when stock, money,
  and carry mass allow purchase.
- Out-of-stock rows remain visible and show no buy action.
- Money or carry-capacity failures remain visible and show the unavailable
  reason `Недостаточно средств или превышена допустимая масса`.
- Carry capacity is the wiki-backed derived character mass maximum:
  `effective Strength × 5 + effective Health × 10 + level × 10`; the Shop does
  not trust a displayed or submitted capacity.
- Sell rows are player inventory rows inside the shop tab. They show the
  item's base shop price, current durability, shop stock context, and a
  server-authorized sell button.
- The 2026-06-01 jewelry sell capture suggests resale price is base item price
  times `20%`, prorated by current durability. This is an observed inference,
  not yet a universal rule for all shops or item families.

## Known But Deferred

- The player Market and Numismatics Shop have implemented read-only reference
  screens, including the market's stall tiers and listing-management shape. Their
  successful and failed purchase, rent, tax settlement, cancellation, expiry,
  and authorization outcomes were not exercised, so they remain deferred.
- The Junk Dealer exposes only its captured shop modes; its stock must not be
  copied from the General Shop.
- Neverlands has direct player trading, but the exact flow, licenses,
  restrictions, UI states, and settlement rules still need source capture.
- Inventory-side forms show the source shape for transfer, gift,
  player-targeted sale, normal currency transfer, and DNV transfer: all are
  tokenized inline forms with recipient nickname fields. Treat this as
  adjacency evidence, not enough to implement settlement or abuse rules.
- Do not keep or rebuild a generic two-panel trade session before that capture.

## State Concepts

- wallet;
- transaction;
- city building shop;
- shop category;
- shop stock with current and maximum counts;
- shop license good;
- resale value.

Deferred source-backed concepts:

- player market listing;
- rented stall, mass limit, skill requirement, rent expiry, and sale tax;
- stall account;
- single-commodity exchange listing.

## Interactions

- `areas/cities_and_buildings.md`: shops are entered through city
  hotspots.
- `features/items_inventory_equipment.md`: all goods are inventory items.
- `features/social_chat_presence.md`: future direct trade capture should account
  for player identity and local presence.
- `features/professions.md`: future profession resources may be sold only after
  their gathering and settlement behavior is captured.

## Out Of Scope

- Standalone global shop route as the primary player path.
- Cash or premium currency until it has a dedicated Neverlands source capture
  and an approved scope.
- Direct player trading until it has a dedicated Neverlands source capture and
  approved implementation shape.
