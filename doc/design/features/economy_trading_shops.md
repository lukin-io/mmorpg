# Economy, Trading, And Shops

Domain navigation: `doc/domains/economy.md`.

## Purpose

The economy connects combat rewards and inventory with Shops entered through
authored City or linked-location buildings.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- `doc/design/reference/shell/observations/2026-07-28_game_shell_and_mvp_surfaces.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
- `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`
- `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- `doc/design/reference/world/observations/2026-09-09_starter_landmarks_and_art.md`
- `doc/design/reference/world/observations/2026-09-09_mine_exchange_wiki.md`
- `doc/design/reference/economy/observations/evidence_needed_mine_exchange_operations.md`

Current observed entry and return paths:

```text
Forpost Central Square -> Shop -> same City node
village entrance cell -> Village Square -> Shop -> Village Square -> Leave -> same outdoor cell
```

The shop page renders a building shell, then category/item content is loaded
inside the shop UI. Items show price, stock, properties, requirements, and buy
availability.

Do not model this as a global marketplace/kiosk route. The Neverlands-shaped
surface is a location-bound building with tabs for buying goods, licenses,
selling goods, and novice goods. The older Trading Quarter entry belongs to
its dated capture; the current Forpost Shop is on Central Square.

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

Those historical commerce captures do not define the current launch graph.
The five-node Forpost topology retains a bounded read-only Market interior;
it has no active Junk Dealer or Numismatics Shop integration. Their transaction
shapes remain evidence for future work. Only the bounded Shop loop currently
mutates inventory, stock, or money through these building surfaces.

## Player Experience

The player enters a Shop from a City hotspot or the exact-cell linked village,
chooses a tab/category, checks item requirements, buys available goods, and
sells inventory. City Shop returns through `Город` to its persisted node.
Village Shop returns through Village to Village Square; only the square's
separate Leave action exits outdoors. The source changes both the location
label and player list between those village rooms.

The later mine Shop and Resource Exchange are separate commerce families.
World currently reproduces their lobby entry, read-only sections, Nature
return and saved lobby location. Mine item cards and exchange selectors are
presentation evidence; no purchase, query, listing, settlement or storage
operation was exercised or implemented there. Do not route a mine Shop tab
into the ordinary City/village catalog by name alone.

The local implementation derives access and parent return from persisted
position and active authored content. It stores sanitized Shop filters for
login resume, revalidates the City hotspot or linked-village feature on return,
and falls back to World if unavailable. Outdoor travel/Look blocks direct
Shop and trade requests under the character lock. Room entry changes ordinary
chat/presence context while preserving the physical cell; Shell owns delivery
and online-session projection.

## Currency

Core currency is normal money for shops.

Currency should be visible in inventory/shop contexts and recorded as part of
economy state.

The supplied NPC-search addendum confirms a successful `24 NV` result row. The
local design adopts that as a typed combat-loot ingress into the same
authoritative NV wallet used by shops. A successful outcome must credit
`CurrencyWallet` and append a `CurrencyTransaction` with its fight/NPC source
identity before the social layer publishes money-found feedback. A
per-NPC-participation processing marker makes retry safe; `GameEvent` is not the
money authority.

NV balances and transaction amounts use fixed `decimal(12,2)` storage. This is
required by the captured fractional prices and prevents inventory transfers or
player-sale settlement from truncating `12.50` NV to an integer. A forward-only
migration repairs databases created when those columns were historically
materialized as integers; rollback is intentionally blocked because it would
discard fractional balances.

## Shop Rules

- Shops belong to authored City nodes or linked-location interiors; their
  name alone cannot authorize entry or merge audiences across locations.
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

- **Mine acquisition — Economy:** item/license purchases, stock, payment and
  item receipt remain unimplemented. Captured cards establish displayed
  details, not successful acquisition, license activation or expiry rules.
- **Resource Exchange — Economy:** actual resource queries/listings,
  transactions/settlement and storage remain unimplemented. Complete the
  [operation capture backlog](../reference/economy/observations/evidence_needed_mine_exchange_operations.md)
  before defining outcomes or reusing ordinary Shop transactions. The older
  wiki model requires current live confirmation.
- **Adjacent mine capabilities:** [Dungeons](../../domains/dungeons.md) tracks
  separate descent/underground-cell travel; [Professions](../../domains/professions.md)
  owns tools, license use/effects, digging/extraction, yield and proficiency.
  Lobby availability does not implement any of these operations.
- The current Market interior is read-only. Purchase, rent, tax settlement,
  cancellation, expiry, and authorization flows remain deferred; historical
  Numismatics and Junk Dealer captures do not imply current routes or screens.
- The captured Junk Dealer modes do not establish its inventory; its stock
  must not be copied from the General Shop.
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
- typed NPC currency award source;
- City or linked-location Shop and its authoritative parent;
- saved Shop filters and location-specific chat/presence context;
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

- `areas/cities_and_buildings.md`: City Shop entry and return preserve the node.
- `areas/world_map.md`: linked-village Shop entry and return preserve the
  outdoor region/cell and distinguish Village Square from Shop.
- `features/items_inventory_equipment.md`: all goods are inventory items.
- `features/combat.md`: a configured NPC NV outcome credits the economy wallet
  through the shared ledger before Combat publishes player feedback.
- `features/social_chat_presence.md`: future direct trade capture should account
  for player identity and local presence.
- `features/professions.md`: future profession resources may be sold only after
  their gathering and settlement behavior is captured.
- `features/dungeons.md`: tracks the distinct mine descent/underground travel
  handoff. Mine commerce remains Economy-owned; a lobby is not a dungeon run.

## Out Of Scope

- Standalone global shop route as the primary player path.
- Cash or premium currency until it has a dedicated Neverlands source capture
  and an approved scope.
- Direct player trading until it has a dedicated Neverlands source capture and
  approved implementation shape.
