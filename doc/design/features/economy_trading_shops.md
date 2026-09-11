# Economy, Trading, And Shops

Domain navigation: `doc/domains/economy.md`.

## Purpose

The economy connects combat rewards and inventory with Shops entered through
authored City or linked-location buildings.

## Neverlands Reference

Primary references:

- `doc/design/reference/neverlands.md`
- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- `doc/design/reference/economy/observations/2026-09-10_shop_layout_and_entrance_scale.md`
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

The September 10 measurement corrects the earlier fixed-size interpretation
of the entrance. The natural source image is 1250 × 600, but its display
height is 75% of the gameplay frame height clamped to 300–600px. Preserve
its 25:12 ratio, center it, and place the four tabs after a 4px gap. All
decorative building entrances share this sizing contract; on narrow clients,
cap the width to the available container and scale proportionally. Interactive
City/location canvases keep their separate authored geometry.

The source frame includes the player/navigation strip. Locally, sum the shell
top bar and main content pane heights before applying the formula; exclude
chat. Using only the content pane would make the image smaller than the source
at the same visible frame geometry.

Below the image, the catalog remains centered at 800px. Do not add a Shop
title, player summary, Inventory link bar or Refresh bar before its mode tabs.
The category strip uses 19 icon-only links with title tooltips, source-sized
41 × 53px images (44 × 53px for Knives and Belts), 3px cell padding and
1px cell spacing around the single cell containing all icons. Do not add that
padding to each category. Use the captured `#e0e0e0` separators, `#f9f9f9`
background and compact left-aligned level/price fields. Keep English wording,
original illustrations and accessible names as explicit local adaptations;
they do not justify a different information hierarchy.

Place the two-line player NV/mass and Shop-funds summary below the filters;
do not add a slot counter or a Licenses economy header. Goods detail panels
use the captured Tahoma typography, beige headings, pale body background and
vertically centered requirements, with only unmet values colored. License
cards use three borderless columns, bold green permission/duration text,
durability/mass before the 60px illustration, then price/stock and quantity/Buy
controls. Existing original license artwork replaces the now-observed source
illustrations; no source logo or bitmap enters runtime.

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
The five-node Forpost topology retains a Market interior with read-only listings
and a bounded Merchant qualification handoff;
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

The local Shop-to-Inventory handoff uses the shared shell action inside the
main content frame. Inventory replaces the displayed frame while Shop remains
the parent browser URL and saved accessible gameplay context; reload/login
restores Shop. This Rails/Turbo integration is a local implementation detail,
not an additional source observation or a change to outdoor navigation.

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

## Starter assortment

The [September 10 active-session capture](../reference/economy/observations/2026-09-10_starter_shop_catalog.md)
defines 79 ordinary starter goods: five in each of fifteen equipment categories
and all four Duel Permits. Relics and Runes were empty; Other stays empty because
the user excluded its sole Wood Chips quest-waste row. Licenses contain the six
observed Trading I–III and Doctor I–III definitions. Do not invent extra tiers
or generic goods to reach five in an empty section.

Fresh stock uses each captured current/maximum quantity, including zero.
Reseeding preserves existing local stock and funds. Captured requirement and
bonus keys map to existing character rules; display-only shield block points
and duel-permit descriptions do not imply new combat or consumable behavior.
Each starter good and license uses an original bitmap, recorded in
`doc/ARTWORK.md`, with original license art replacing the 60px source cards
confirmed in the September 10 layout capture. Original goods art follows the same item through Shop, Inventory
and its equipment slot.

## Shop Rules

Current license/sale evidence: `doc/design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md`.

- The September 9 live purchase and Inventory handoff is recorded in
  `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`.
- One equipment Buy action purchases one unit: payment, item receipt, carried
  mass and a one-unit stock reduction are one local database transaction.
  The shared stock count is economic supply, not a decorative number.
- The 19 captured category controls replace generic equipment/resource groups.
  Only explicitly authored Shop goods are buyable; an inventory item's price
  alone does not place it in the Shop.
- Shop capabilities bind character, exact location/building, action and item
  quote; successful consumption commits with the trade, preventing replay.
- Licenses describe typed professional permissions and durations, with Merchant/Healer
  prerequisites. Ownership is shown in Abilities → Your licenses. The local
  description-based acquisition starts duration at purchase; this is a declared
  adaptation, not observed source activation. Novice remains unavailable at
  level 10 or above; do not invent eligible cheap-goods buying.
- Shops belong to authored City nodes or linked-location interiors; their
  name alone cannot authorize entry or merge audiences across locations.
- Shops can have category tabs.
- Shop inventory can have stock counts.
- Items show price, requirements, and properties.
- Buying checks money, stock, purchase-specific gates when captured, and
  inventory capacity. Equipment/use requirements are still displayed but are
  not automatically purchase blockers.
- Selling requires an active trading license and owned sellable goods. It pays
  from that Shop's independent NV pool, adds exactly one unit to its stock and
  rejects full stock or insufficient funds without partial changes.
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
- The official Trader table uses 20/30/40/50/60/70% at skill boundaries
  0/100/225/350/475/600. Live healthy/worn knife quotes confirm durability
  proration at the initial tier. Local decimal settlement rounds the complete
  calculation once to two places; exact source rounding remains unobserved.
- Each Shop has its own stock and funds. Equipment capacity is enforced; a
  license count without a shown maximum does not inherit the equipment cap.
- License purchase follows the profession prerequisites below. A label,
  numeric skill alone or unrelated license cannot grant those rights.
- Player-to-player selling requires its own source-backed offer and buyer
  acceptance flow. A trading license alone must not permit an immediate debit
  of another player's wallet; the prior unilateral settlement is removed locally.
- An existing active license blocks another purchase of the same kind until
  renewal/upgrades are captured; purchasing is not an inferred stacking mechanic.

### Profession prerequisites for licenses

The [official-wiki prerequisite record](../reference/economy/observations/2026-09-09_licenses_and_shop_selling.md#profession-prerequisites-wiki-clarification-2026-09-10)
owns the source evidence. Selected boolean perks, numeric profession
proficiency, quest completion and purchased timed permissions are distinct
state. Selecting a profession perk must not award the other three.

| License family/tier | Purchase prerequisite |
|---|---|
| Trading I–III | Merchant perk and completed Merchant onboarding |
| Doctor I | Healer perk; the page states no additional license-purchase quest gate |
| Doctor II–III | Healer perk and completed Traumatologist quest |

Merchant onboarding follows Market acceptance → Shop 1,000-NV receipt payment
→ Market completion. Local progress and the owned payment ledger authorize the
license unlock. Exact dialogue, physical receipt behavior and the temporary
garment reward remain uncaptured/incomplete.

Trading begins at 0; a positive Trading threshold must not be invented for the
first license. Its proficiency controls the resale tiers above. Published
Shop-sale growth is separate from purchase eligibility; local settlement
currently reads proficiency without awarding growth.

For Doctor II/III, 100 Doctor skill (including applicable equipment) is the
published **Traumatologist quest-entry** threshold. It is not evidence for an
independent continuous purchase/validity threshold. Doctor I purchase must also
remain distinct from the initial medical quest, bag/knowledge requirements and
treatment/crafting unlocks. The [Shop handbook](../../features/shop_economy.md#62-buying-and-stock)
owns the exact implemented checks and outstanding medical workflows.

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
- Market listings remain read-only; the license qualification steps above are
  the bounded exception. Listing purchase, rent, tax settlement,
  cancellation, expiry, and authorization flows remain deferred; historical
  Numismatics and Junk Dealer captures do not imply current routes or screens.
- The captured Junk Dealer modes do not establish its inventory; its stock
  must not be copied from the General Shop.
- Published Trader rules establish buyer confirmation and a Trading license
  held by at least one party for direct player trade. Exact live confirmation,
  failure/cancellation/expiry states and settlement behavior still need capture.
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
- `features/items_inventory_equipment.md`: ordinary goods enter inventory; professional licenses are separate owned timed permissions displayed in Abilities.
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
