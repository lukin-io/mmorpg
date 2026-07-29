# frozen_string_literal: true
---
title: Shop and Economy Feature
description: Implementation handbook for the Neverlands-based city shop, NV wallet, catalog buying, inventory selling, and transaction ledger.
status: Partially Implemented
updated: 2026-07-28
owners: Shop and Economy
template: feature-v1
---

# Shop and Economy

This document is the implementation contract for the current Shop and Economy feature. It explains city-shop access, catalog modes and filters, NV payments, stock and inventory mutations, resale pricing, login resume, UI ownership, security, concurrency, and test coverage.

It describes what exists now. It does not treat every captured Neverlands city counter, license rule, novice service, or generic marketplace mechanic as shipped behavior.

## 1. Design authority and related documents

Neverlands is the sole game-design and visual reference for this feature. The local implementation adapts the observed Shop density, item rows, tabs, filters, NV prices, mass/slot summaries, and explicit buy/sell actions to Rails and the current English client. Source runtime images, logos, project identity, and service/administration prose are evidence only; the shipped scene uses project-owned CSS, generic game wording, and styled ASCII/text category tokens instead of copied icon bitmaps.

When behavior is uncertain or conflicts with this document:

1. Re-observe Neverlands and record the evidence under `doc/design/reference/`.
2. Update the relevant shop/economy design record.
3. Change implementation and coverage together.
4. Update this feature contract last.

Supporting documents:

- `doc/design/reference/neverlands_live_lavka_shop.md` records the live shop tabs, filters, tables, quantities, stock, prices, requirements, and status strip.
- `doc/design/reference/neverlands_live_inventory_items.md` records source inventory and item presentation used by selling and capacity feedback.
- `doc/design/reference/neverlands_live_city_movement.md` records how the city exposes building entry and exit.
- `doc/design/reference/neverlands_live_game_shell_ui.md` records the compact surrounding interface.
- `doc/design/features/economy_trading_shops.md` defines the local economy and shop boundary.
- `doc/design/areas/cities_and_buildings.md` owns the authored building topology.
- `doc/design/launch_mvp_plan.md` defines the MVP trading/economy boundary.
- `doc/features/world.md` owns exact position and the safe World fallback used by Shop resume validation.
- `doc/features/city.md` owns entry to the Shop building.
- `doc/features/character_progression.md` owns the stats and skills displayed as item requirements.
- `doc/features/game_shell.md` owns the persistent frame surrounding the shop.
- `doc/features/player_inventory.md` owns carried stacks and equipment after a trade.

### 1.1 Cross-feature relationships

| Related feature | Relationship | Ownership and handoff |
|---|---|---|
| `doc/features/world.md` | Shop uses World-owned resume context and falls back to World when a saved Shop is no longer accessible. | World/City own exact location and safe destination selection; Shop owns only its allowlisted surface context and transactions. |
| `doc/features/city.md` | Central Square exposes and authorizes entry to the Shop. | City owns the node, hotspot offer, level/access check, and return; Shop owns behavior after the entry handoff. |
| `doc/features/character_progression.md` | Shop item rows present requirements derived from character stats/skills. | Character Progression owns the values; Shop may display them but does not decide equipment eligibility or mutate progression. |
| `doc/features/game_shell.md` | Shop can render as the central gameplay surface inside the persistent shell. | Shop owns catalog/trade responses; Game Shell owns shared framing, navigation, presence, chat, and flashes. |
| `doc/features/player_inventory.md` | Shop purchases add carried stacks and Shop sales remove eligible stacks. | Shop owns exchange value/stock transactions; Player Inventory owns the resulting stack, mass, durability, and equipment rules. |

## 2. Feature summary

An authenticated player standing inside an accessible city Shop can browse server-authored item templates, filter the dense Neverlands-style table, buy positive-priced items with NV, switch to Sell, and sell eligible non-broken inventory stacks back to the shop. The screen shows wallet balance, wiki-derived carried-mass maximum, slot use, item properties, requirements, stock, unit prices, quantity controls, and result flashes.

The server is authoritative. `CurrencyWallet` owns the account's NV balance, `CurrencyTransaction` records each adjustment, `Inventory` owns carried items/capacity, `ItemTemplate` owns price and shop stock, and the current character's city context controls access. Catalog parameters and browser controls never confer purchase or sale authority.

The implemented catalog includes Buy, Licenses, Sell, and Novice modes plus seven category choices. Licenses and Novice are catalog filters using the same ordinary purchase flow; source-specific license grants, durations, or distinct novice transactions were not captured and are not implemented.

The MVP currently contains:

- city-building-gated shop access and safe login resume;
- source-shaped modes, categories, numeric filters, and dense item tables;
- transactional buy and sell operations with wallet, inventory, capacity, durability, and stock handling;
- one non-negative decimal NV wallet per user and an immutable adjustment ledger;
- authenticated current-character scoping and safe rejection of foreign inventory item IDs.

## 3. MVP goals and non-goals

### Goals

- Reproduce the captured Neverlands shop layout and deliberate buy/sell interaction.
- Keep NV, inventory contents, capacity, and shop stock server-authoritative.
- Make each successful purchase or sale atomic across the affected records.
- Preserve only allowlisted catalog context when the player reloads or logs back in.
- Revalidate city Shop availability and record ownership for every request.

### Non-goals

- Inventing license effects, durations, prerequisites, or novice-only services that were not observed.
- Player-to-player markets, auctions, barter, banking, exchange rates, credit, refunds, or generic merchant reputation.
- Making the captured Market, Junk Dealer, Numismatics Exchange, Hospital Shop, Pharmacy, or Airship Station transactional here.
- Treating displayed equipment requirements as purchase prohibitions; inventory/equipment owns whether an item can be equipped.
- Exposing a separately versioned public shop API, blueprint serializer, or Swagger/rswag contract.

## 4. Player experience

### 4.1 Entry conditions

The player enters through an active, level-accessible Shop hotspot in their current city node. `GET /shop` rechecks that current city context; direct access from the outdoor world, another building, or an unavailable hotspot redirects to World with an alert.

An inventory and wallet are created with safe defaults if the current character/user does not yet have them. Authentication and an active playable character are required before shop state is loaded or remembered.

### 4.2 Primary surface

The current Shop starts with a project-owned CSS illustration using the observed 1250 × 600 scene ratio. Beneath it, one centered 800px frame contains a compact status/return row, four equal approximately 21px mode tabs (Buy Goods, Licenses, Sell Goods, and For Beginners), a 61px icon-category strip, and a 30px level/price filter row. Local categories are All, Weapons, Armor, Jewelry, Elixirs, Resources, and Misc; the mechanics are not expanded merely to fill every source icon slot.

On tablet/mobile the decorative scene scales because it owns no action geometry. The frame remains within the main content; category and table regions own their own horizontal overflow instead of widening the page.

Buy-like modes render dense item rows with name, properties, requirements, stock, NV price, quantity, and an action. Sell renders carried stacks with item state, quantity, calculated unit return, and a sell action. The surrounding header, vitals, nearby players, and chat belong to Game Shell.

### 4.3 Player actions and feedback

The player can change mode/category/filter query parameters, choose a quantity, and submit Buy or Sell. Quantities are normalized to `1..99` at the controller boundary. Successful mutations redirect back to the sanitized shop view and show `Bought: ...` or `Sold: ...`; failures redirect without partial mutation and show the domain message.

Buying checks a positive-priced template, availability, limited stock, NV balance, inventory slots, carried mass, and stack limits. Selling checks current-character ownership, quantity, protected/equipped/bound state, and positive resale value. Unmet equipment requirements remain visible information and are enforced later by the inventory/equipment feature.

### 4.4 Exit and integration behavior

The player returns to the City through the shared building/city navigation. The Shop remembers sanitized mode, category, and numeric filter strings as gameplay context, so logout/login or a direct return resumes the same Shop screen while that Shop remains accessible.

City owns the building node before entry and after exit. Inventory owns stacking, capacity, equipment state, and later item use. Character Progression owns requirement values. Shop and Economy own only catalog eligibility, exchange mutations, wallet adjustments, stock, and shop presentation.

## 5. Feature topology and authored content

The feature uses an authored catalog/state graph rather than spatial cells.

| Runtime key | Player-facing name | Connections or actions | Implemented content |
|---|---|---|---|
| `buy` | Buy | Category/filter, quantity, purchase | Positive-priced non-license item templates |
| `licenses` | Licenses | Category/filter, quantity, purchase | Templates whose key starts with or name contains `license` |
| `sell` | Sell | Quantity, protected-state check, sale | Current character's inventory stacks |
| `novice` | Novice | Category/filter, quantity, purchase | Required level at most `5` and integer price at most `250` |
| `all` | All | No category restriction | Every template eligible for the selected mode |
| `weapons`, `armor`, `jewelry` | Equipment groups | Filter by normalized equipment slot | Captured dense equipment rows |
| `consumables`, `materials`, `misc` | Elixirs, Resources, Misc | Filter by item type/fallback | Non-equipment catalog groups |

### 5.1 Coordinate, key, or identity terminology

- **Item-template ID** — server database identity submitted for purchase; it must resolve inside the positive-priced buyable scope.
- **Inventory-item ID** — owned stack identity submitted for sale; it is resolved only through the current character's inventory.
- **Mode/category key** — allowlisted presentation/filter key; invalid values fall back to `buy` and `all`.
- **NV** — the source-backed single currency stored in the current user's wallet.
- **Shop stock** — unlimited or limited quantity stored by the item template and rechecked during purchase.

Catalog order, row position, item label, CSS class, displayed price, and query parameters never establish ownership or availability.

## 6. Feature surfaces and contained behavior

### 6.1 Implementation status

| Surface or behavior | Entry point | MVP status | Owning implementation |
|---|---|---|---|
| Shop frame/catalog | `GET /shop` | Interactive | `ShopController` and `Game::Shop::Catalog` |
| Catalog purchase | `POST /shop/buy` | Interactive | `Game::Shop::Purchase` |
| Inventory sale | `POST /shop/sell` | Interactive | `Game::Shop::Sale` |
| NV wallet and ledger | Shop services/internal callers | Interactive persistence | `CurrencyWallet` and `Economy::WalletService` |
| Licenses mode | `GET /shop?mode=licenses` | Catalog-interactive only | Ordinary catalog/purchase flow |
| Novice mode | `GET /shop?mode=novice` | Catalog-interactive only | Low-level/low-price filter |
| Other captured city counters/interiors | City building routes | Read-only or deferred | City feature |

### 6.2 Buying and stock

Only `ItemTemplate` rows with `base_price > 0` are buyable. Normal Buy excludes license-like templates; Licenses contains only them; Novice contains entries with required level at most `5` and integer base price at most `250`. Category and optional level/price filters narrow the results.

Purchase price is the template's integer `base_price` multiplied by normalized quantity. The transaction locks the template, inventory, and wallet; rechecks limited stock; debits NV through the wallet ledger; adds items through `Game::Inventory::Manager`; and decrements limited stock. Capacity uses `effective Strength × 5 + effective Health × 10 + level × 10`; capacity or funds failure rolls the transaction back.

### 6.3 Selling and NV accounting

The base resale price is 20 percent of integer base price, rounded to two decimals with a minimum of `1` NV. If maximum durability is positive, the unit return is prorated by current/max durability and rounded to two decimals. This local formula is consistent with captured examples but is not evidence for unobserved item classes.

Sale locks the inventory and stack, removes the requested quantity or destroys an exhausted stack, reduces carried weight without going below zero, increments limited shop stock, and credits the wallet ledger. Equipped, bound, protected, reserved, otherwise discard-protected, or zero-durability items cannot be sold.

Wallet balances and ledger amounts are decimal values. Every adjustment is non-zero, records a reason and resulting balance, and cannot leave the wallet negative.

### 6.4 Deferred behavior boundary

License rows do not grant a captured license object, timer, profession permission, or alternate currency. Novice is only an authored catalog filter. There is no bargain flow, buyback, refund, repair, appraisal, player order, remote shopping, or transaction-history UI.

The current forms do not use a one-time server-issued action capability. CSRF, authentication, location/ownership checks, transactions, and locks protect each request, but repeating a still-valid submission performs another purchase or sale. Idempotency/replay prevention must not be claimed.

## 7. Authoritative data and presentation model

| Record or component | Responsibility | Important contract |
|---|---|---|
| `CurrencyWallet` | One user's NV balance | Unique per user and non-negative |
| `CurrencyTransaction` | Audit one wallet adjustment | Non-zero amount, reason, metadata, and non-negative `balance_after` |
| `ItemTemplate` | Catalog identity, price, requirements, stack/durability, stock | Buyable only when positive-priced; limited stock cannot underflow |
| `Inventory` and `InventoryItem` | Current character's derived mass capacity and owned stacks | Sale scope, broken/protected state, and `Character#carrying_capacity` authority |
| `Game::Shop::Catalog` | Authored modes, categories, filters, and resale formula | Presentation eligibility only; does not transfer value |
| `Game::World::ResumeContext` | Current Shop availability and safe resume | Rechecks the active current-city Shop hotspot |

### 7.1 Source of truth

The wallet, ledger, item templates, inventory, stacks, character position, city node, and hotspot records are authoritative. Catalog arrays define valid presentation modes/categories. Missing inventory or wallet records are bootstrapped for the current owner with empty/zero state.

The browser receives calculated rows and submits only IDs, quantities, and catalog context. Services reload/lock the affected records and apply authoritative price, stock, capacity, protected-state, and balance rules.

### 7.2 Validation and state lifecycle

- A user has at most one wallet and its balance cannot be negative.
- A transaction amount cannot be zero and `balance_after` cannot be negative.
- Buy quantity is normalized to `1..99`; service calls also reject non-positive quantities.
- Sale quantity cannot exceed the current stack and cannot target a foreign/missing stack.
- Limited stock is checked before and after the template lock.
- Invalid mode/category keys fall back safely; only six filter keys are retained for the redirect/resume context.
- Decimal wallet storage is forward-only at the precision migration because reverting to integer would lose fractional sale values.

### 7.3 Presentation versus authority

Displayed prices, totals, stock, requirements, mass, slots, hidden IDs, confirmation text, filter fields, and saved gameplay-context parameters are presentation/input only. The server recalculates prices and rechecks all mutation invariants.

Numeric filters are converted with `to_i`; a direct request may therefore contain negative or malformed strings, but these only affect which rows are displayed. They never change price, ownership, stock, or wallet state.

## 8. Runtime architecture

```mermaid
flowchart LR
    A["Player enters city Shop"] --> B["Authenticate and resolve current character"]
    B --> C["Recheck active accessible Shop hotspot"]
    C --> D["Build allowlisted catalog and render HTML/Turbo frame"]
    E["Player submits Buy or Sell"] --> F["Resolve template or owned inventory stack"]
    F --> G["Validate quantity, stock, protection, capacity, and funds"]
    G --> H["Lock wallet, inventory, item/template in transaction"]
    H --> I["Transfer item/stock and adjust NV with ledger"]
    I --> J["Redirect to sanitized Shop context with flash"]
    G -->|failure| K["Rollback or do nothing; redirect with alert"]
```

### 8.1 Load and render

`ShopController` authenticates, resolves the active character, calls `ResumeContext#shop_available?`, creates missing inventory/wallet records, and builds `Game::Shop::Catalog` from request parameters. The view renders buy-like or sell rows and the controller remembers sanitized context only after successful access.

### 8.2 Accept or execute action

Buy resolves the submitted template inside the positive-priced buyable scope. Sell resolves the submitted stack through the current inventory. The controller normalizes quantity and delegates; domain services validate, start a database transaction, take row locks, recalculate authoritative values, update inventory/stock, and call the wallet service.

### 8.3 Complete, redirect, or hand off

Both mutations use an HTML redirect to the Shop with a notice or alert. Submitted mode/category/filter values are allowlisted into the return URL. Sell forces `mode=sell`. The next GET rebuilds all displayed state from persisted records.

### 8.4 Concurrency behavior

Wallet adjustment locks the wallet. Purchase also locks template and inventory; sale locks inventory and the selected stack. Database transactions make the value transfer atomic and stale limited stock/funds fail safely. Requests are not idempotent, and there is no consumed capability or request key preventing a deliberate/replayed second valid trade.

## 9. HTTP and Turbo contract

| Method and path | Purpose | Success | Failure |
|---|---|---|---|
| `GET /shop` | Render selected shop mode/category/filters | HTML or `main_content` Turbo-frame-compatible shop surface | Login redirect or World redirect when Shop is unavailable |
| `POST /shop/buy` | Buy a catalog template | Atomic purchase; redirect with notice | No/rolled-back mutation; redirect with alert |
| `POST /shop/sell` | Sell an owned inventory stack | Atomic sale; redirect to Sell with notice | No/rolled-back mutation; redirect to Sell with alert |

The feature is authenticated HTML/Turbo navigation with ordinary form redirects. It has no separately versioned public JSON API, so blueprint and Swagger/rswag coverage are not applicable.

## 10. Client-side and CSS ownership

The Shop uses server-rendered forms and links; it has no shop-specific Stimulus controller. Browser behavior is limited to native numeric inputs, confirmation prompts, Turbo navigation, and the shared shell.

It must not:

- calculate an authoritative price or balance;
- decide ownership, stock, protected state, or capacity;
- grant a license or novice privilege;
- persist a trade without server validation.

`app/assets/stylesheets/shop.css` owns the project-created CSS Shop illustration, 1250 × 600 scene ratio, centered 800px frame, compact tabs, 61px category strip, filters, status strip, locally scrollable item tables, property/requirement cells, quantity controls, and responsive overflow. Shared framing remains owned by Game Shell.

Accessibility behavior:

- mode/category controls are real links and mutations are real forms;
- quantity/filter fields retain associated labels or contextual table headings;
- confirmation prompts precede value-changing submissions;
- server flashes provide textual success/failure feedback without color-only meaning.

## 11. Persistence and login resume

Wallet balances, ledger entries, inventory stacks, carried weight, shop stock, and character gameplay context persist in the database. The Shop context stores only `mode`, `category`, `min_level`, `max_level`, `min_price`, and `max_price`; mode/category are normalized before storage.

On login or return:

- a valid saved Shop context resumes the same allowlisted catalog view;
- Shop access is rechecked against the current city node and active accessible hotspot;
- invalid mode/category values fall back to Buy/All;
- an unavailable/removed Shop falls back to World without changing the authoritative location;
- arbitrary return URLs or templates are neither stored nor followed.

City/World own exact location persistence. Shop owns only the safe interior surface context once City has established entry.

## 12. Authorization, trust boundaries, and concurrency

- Devise authentication protects every Shop route.
- `CurrentCharacterContext` scopes behavior to the signed-in user's active playable character.
- `ResumeContext#shop_available?` revalidates the current city building and level access.
- Purchase resolves only positive-priced server templates; Sale resolves only through the current inventory.
- Wallet, inventory, item/template row locks and transactions protect each value transfer.
- Mode, category, redirect filters, and resume parameters use explicit allowlists.
- Submitted price, wallet balance, stock, requirements, weight, and item labels are never trusted.
- Inventory and City recheck their own invariants at each cross-feature handoff.
- No policy class is needed for these non-REST domain records because current-character scoping occurs before service invocation; adding cross-character/admin shop access would require an explicit policy.

## 13. Failure and boundary behavior

| Condition | Required behavior |
|---|---|
| Anonymous request | Redirect to login; do not read or update gameplay context. |
| No active character | Use the shared active-character failure path; no trade. |
| Not inside an accessible Shop | Redirect to World with an alert; preserve location. |
| Missing/foreign template or inventory item | Reject as unbuyable/not found; no value transfer. |
| Quantity zero, negative, malformed, or above `99` | Controller normalizes to `1..99`; services reject non-positive direct calls. |
| Insufficient NV | No item/stock change; redirect with `Not enough NV.` |
| Inventory mass/slot overflow | Roll back debit and item/stock changes; show capacity error. |
| Limited stock changes after render | Recheck under template lock and fail without partial mutation. |
| Sale exceeds current stack | Reject; wallet, stack, weight, and stock remain unchanged. |
| Equipped/bound/protected/reserved item | Reject with `This item cannot be sold.` |
| Unequipped item at zero durability | Reject with `Broken items cannot be sold.`; preserve stack, stock, weight, and wallet. |
| Zero/non-positive price | Template is not buyable/sellable; no transaction. |
| Invalid mode/category/filter | Fall back or filter presentation only; never mutate domain state. |
| Repeated valid submission | Performs another valid trade; one-time replay protection is not implemented. |
| Unsupported license/novice effect | Do not grant or render an implied mechanic. |

## 14. Acceptance criteria

- A player in the authored City Shop can browse Buy, Licenses, Sell, and Novice modes in the compact source-shaped UI.
- Mode/category/filter selection changes only eligible rendered rows and safe saved context.
- A valid purchase atomically debits NV, records a ledger entry, adds inventory quantity/weight, and decrements limited stock.
- A valid sale atomically removes owned quantity/weight, credits decimal NV, records a ledger entry, and restores limited stock.
- A zero-durability item cannot be sold, and purchase/loot capacity uses the
  same derived character mass maximum.
- Price, ownership, stock, protected state, capacity, and wallet balance are recalculated server-side.
- Logout/login resumes a valid Shop surface without trusting an arbitrary URL or changing exact city location.
- License and novice source mechanics beyond filtering/ordinary purchase remain explicitly unimplemented.
- Insufficient funds, capacity, stale stock, invalid quantity, and protected/foreign item failures cause no partial transfer.
- Anonymous and out-of-Shop requests cannot trade or persist Shop context.
- The current empty-catalog shell matches the observed scene/control hierarchy at desktop and remains usable without document overflow at `820px` and `390px`.
- No Neverlands Shop illustration, icon bitmap, logo, signature, administration copy, or source asset URL is shipped.

## 15. Test strategy and required coverage

Tests are part of the feature contract. Shop changes require applicable model, request, service, factory, view/system, seed/config, and inventory integration coverage. A dedicated policy spec is not applicable until a Shop policy exists; request coverage must still prove authentication and current-character scoping. Blueprint and Swagger/rswag do not apply because no public API exists.

| Coverage category | Representative guarantees |
|---|---|
| Success | Shop render, classification, buy, sale, durability proration, wallet/ledger persistence, inventory/stock changes, and resume context. |
| Failure | Insufficient funds, capacity, missing item, protected item, unavailable Shop, and invalid wallet adjustment. |
| Edge/null/boundary | Zero/negative/decimal amounts, full/partial stacks, zero durability sale rejection, derived mass boundary, unlimited/limited stock, absent inventory/wallet, quantity limits, and invalid filters. |
| Authorization | Anonymous access, foreign inventory item, active-character ownership, and city hotspot availability. |

Factories must retain edge traits for stock state, stack/protected/equipped/bound state, capacity boundaries, durability, positive/zero price, city Shop availability, and ownership when exercised.

Focused verification command:

```bash
bundle exec rspec \
  spec/models/currency_wallet_spec.rb \
  spec/models/currency_transaction_spec.rb \
  spec/services/economy/wallet_service_spec.rb \
  spec/requests/shop_spec.rb
```

`Game::Shop::Catalog`, `Purchase`, and `Sale` currently rely mainly on request/integration coverage; dedicated service specs are a justified coverage gap for future behavior changes. Run the complete suite before release because the feature mutates shared inventory, economy, city context, authentication, and shell state.

## 16. Responsible for Implementation Files

### Requirements and design evidence

- `doc/features/shop_economy.md`
- `doc/design/features/economy_trading_shops.md`
- `doc/design/areas/cities_and_buildings.md`
- `doc/design/reference/neverlands_live_lavka_shop.md`
- `doc/design/reference/neverlands_live_inventory_items.md`
- `doc/design/reference/neverlands_live_city_movement.md`
- `doc/design/reference/neverlands_live_game_shell_ui.md`
- `doc/design/launch_mvp_plan.md`

### Routes and controllers

- `config/routes.rb`
- `app/controllers/shop_controller.rb`
- `app/controllers/concerns/current_character_context.rb`

### Models and policies

- `app/models/character.rb`
- `app/models/currency_wallet.rb`
- `app/models/currency_transaction.rb`
- `app/models/item_template.rb`
- `app/models/inventory.rb`
- `app/models/inventory_item.rb`

### Services

- `app/services/game/shop/catalog.rb`
- `app/services/game/shop/purchase.rb`
- `app/services/game/shop/sale.rb`
- `app/services/economy/wallet_service.rb`

### Views, helpers, client behavior, styling, and assets

- `app/helpers/shop_helper.rb`
- `app/views/shop/show.html.erb`
- `app/views/shop/_buy_table.html.erb`
- `app/views/shop/_sell_table.html.erb`
- `app/assets/stylesheets/shop.css`
- `app/assets/stylesheets/controls.css`

### Content, configuration, seeds, and schema

- `db/seeds.rb`
- `db/schema.rb`
- `db/migrate/20251121090002_create_item_templates.rb`
- `db/migrate/20251121142307_create_economy_and_trading.rb`
- `db/migrate/20260721090000_ensure_decimal_currency_columns.rb`
- `db/migrate/20251121150000_create_characters_and_privacy_settings.rb`

### Integrated feature entry points

- `app/models/city_hotspot.rb`
- `app/services/game/world/resume_context.rb`
- `app/services/game/world/city_catalog.rb`
- `app/views/city_buildings/_shop_shell.html.erb`
- `app/services/game/inventory/manager.rb`

City/Resume Context own building access and exact-location resume before the Shop. Inventory Manager owns stacking and capacity during item handoff. Shop owns exchange eligibility and value transfer, not later equipment/use behavior.

### Factories

- `spec/factories/users.rb`
- `spec/factories/characters.rb`
- `spec/factories/character_positions.rb`
- `spec/factories/zones.rb`
- `spec/factories/city_hotspots.rb`
- `spec/factories/item_templates.rb`
- `spec/factories/inventories.rb`
- `spec/factories/inventory_items.rb`

### Specs

- `spec/models/currency_wallet_spec.rb`
- `spec/models/currency_transaction_spec.rb`
- `spec/services/economy/wallet_service_spec.rb`
- `spec/requests/shop_spec.rb`

## 17. Safe extension checklist

`doc/guides/managing_game_content.md` documents how a future explicit
`ItemTemplate` management adapter must preserve Shop catalog, price, stock, and
owned-inventory boundaries. The example does not mark that route as shipped.

Before extending Shop and Economy:

1. Capture the exact Neverlands counter, row, control, response, and currency behavior.
2. Decide whether City, Shop, Inventory, or Character Progression owns the transition.
3. Add only the catalog/model/service behavior needed for that evidence.
4. Recalculate every value and revalidate current-character ownership server-side.
5. Lock all records participating in an atomic transfer and define replay behavior.
6. Never grant a license, novice benefit, or market mechanic from labels alone.
7. Preserve the dense Neverlands table language and accessible form semantics.
8. Add success, failure, edge/null/boundary, and authorization coverage, including service specs for changed trade logic.
9. Update status, non-goals, acceptance criteria, responsible files, focused checks, and version history here.

## 18. Version history

| Date | Change |
|---|---|
| 2026-07-21 | Created the implementation handbook for the city Shop, catalog filters, buying, selling, NV wallet, stock, and safe resume behavior. |
| 2026-07-27 | Aligned Shop capacity with the wiki mass formula and made zero-durability sale rejection explicit in implementation, request coverage, failure rules, and file ownership. |
| 2026-07-28 | Moved current Shop access to Central Square; added the project-owned CSS scene, measured 800px control frame, four mode tabs, icon category strip, compact filters, local table overflow, responsive acceptance, and source-asset/text boundary. |
| 2026-07-29 | Linked the cross-feature management guide's future explicit `ItemTemplate` adapter while retaining Shop ownership of catalog visibility, price, stock, and transaction invariants. |
