# Economy and Shop Domain

## Scope

City and linked-village Shop navigation, browse/filter modes, dense catalog rows, buying, selling,
stock, prices, requirements, funds, NPC-loot NV ingress, capacity, and
transactional safety.

## Documentation chain

- Neverlands source summary: `doc/design/reference/economy/README.md`
- Current observations: `doc/design/reference/economy/observations/`
- Cross-domain NPC-money observation:
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Normalized design: `doc/design/features/economy_trading_shops.md`
- Delivery IDs: `ECONOMY-SHOP-001` and `ECONOMY-TRANSACTIONS-001` in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/shop_economy.md`

## Current RPG status

Partially Implemented. The bounded Shop shell and server-authoritative
transactions exist. The typed NPC NV award path credits the same wallet/ledger
transactionally before social feedback; no production NPC amount/probability is
authored without further evidence. Full populated live-state parity,
market trading, licenses, repair, transfers, and other service economies do
not.

Shop revalidates the active City hotspot or exact-cell linked-village feature.
Its saved filters resume after login only while that location is available.
Village Shop returns to Village Square before the separate outdoor exit;
World owns coordinates, and Shell owns the distinct room's presence/chat.
Persisted outdoor travel or Look rejects direct Shop/trade requests without
changing money, inventory, stock, or saved room.

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

Capture populated, disabled, confirmation, success, and failure variants before
claiming 1:1 parity for those states.
