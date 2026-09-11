# Economy and Shop Domain

## Scope

City and linked-village Shop navigation, browse/filter modes, dense catalog rows, buying, selling,
stock, prices, requirements, funds, NPC-loot NV ingress, capacity, and
transactional safety. Future mine item/license purchases and resource exchange
queries, listings, transactions and storage belong here as distinct commerce
flows.

## Documentation chain

- Neverlands source summary: `doc/design/reference/economy/README.md`
- Current observations: `doc/design/reference/economy/observations/`
- License requirements and sale economics:
  `doc/design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md`
- Completed Shop purchase/Inventory handoff:
  `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`
- Mine/exchange operation gaps:
  [capture backlog](../design/reference/economy/observations/evidence_needed_mine_exchange_operations.md)
- Cross-domain NPC-money observation:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- [September 10 starter assortment capture](../design/reference/economy/observations/2026-09-10_starter_shop_catalog.md)
- Normalized design: `doc/design/features/economy_trading_shops.md`
- Delivery IDs: `ECONOMY-SHOP-001` and `ECONOMY-TRANSACTIONS-001` in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/shop_economy.md`

## Current RPG status

Partially Implemented. The bounded Shop shell and server-authoritative
transactions exist. The typed NPC NV award path credits the same wallet/ledger
transactionally before social feedback; no production NPC amount/probability is
authored without further evidence. Full populated live-state parity,
market trading, profession quest chains, medical treatment, repair and other
service economies remain outside the completed transaction boundary.

The September 9 slice adds the 19 observed category controls, original Shop
interior/icon art, explicit source-backed goods and one-use trade offers. One
Buy spends the authoritative NV price, persists one inventory item and its
mass, decrements that Shop's stock by one, credits its funds and consumes the
offer atomically.
Duplicate/expired/changed or foreign offers cannot repeat the transfer.
Licenses has six typed purchasable permissions, prerequisite checks and saved
expiry under Your licenses. Sell requires active trading permission, uses the
source skill/durability price, pays from Shop funds and restores one stock unit.
Full stock and insufficient merchant funds reject unchanged. For Beginners
shows the observed denial at level 10 or above; lower-level characters see an
empty section without purchase offers until eligible operations are observed.

Shop revalidates the active City hotspot or exact-cell linked-village feature.
Its saved filters resume after login only while that location is available.
Village Shop returns to Village Square before the separate outdoor exit;
World owns coordinates, and Shell owns the distinct room's presence/chat.
Persisted outdoor travel or Look rejects direct Shop/trade requests without
changing money, inventory, stock, or saved room.

World also implements mine/exchange **lobbies**: entry, read-only sections,
Nature return and location resume. The mine Shop previews do not grant access
to the ordinary Shop catalog; its purchases and the exchange's queries,
listings, transactions and storage operations are unimplemented. The shared
wallet alone does not implement those flows.

## Important responsible implementation files

- `app/controllers/shop_controller.rb`
- `app/services/game/shop/catalog.rb`
- `app/services/game/shop/purchase.rb`
- `app/services/game/shop/sale.rb`
- `app/services/economy/wallet_service.rb`
- `app/services/arena/npc_loot_awarder.rb` (Combat-owned ingress)
- `app/assets/stylesheets/shop.css`

Section 16 of `doc/features/shop_economy.md` is exhaustive.

## Evidence and implementation gaps

One populated purchase/confirmation/Inventory-success path is now captured.
Capture source money/capacity failures, successful sale, eligible novice/license
operations and stock replenishment before claiming broader 1:1 parity.

The [Economy gap table](../features/shop_economy.md#65-mine-shop-and-resource-exchange-gap-ownership)
separates these known `[IMPL]` absences from missing `[EVIDENCE]` for successful
and failed operations. Mine underground descent/movement belongs to
[Dungeons](dungeons.md); digging/extraction and license use/effects belong to
[Professions](professions.md). World owns only the shared location handoff.
