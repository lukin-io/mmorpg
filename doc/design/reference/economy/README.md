# Neverlands Economy and Shop Source Summary

- Document type: neverlands-source-summary
- Domain: economy
- Updated: 2026-09-09
- Evidence status: current for captured Shop rows and mine/exchange lobby controls; economic operation captures incomplete

## Current observations

- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- Shop rows and item actions in
  `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- Service-building evidence in
  `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`
- Successful `24 NV` NPC-search result in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`
- Linked-village Shop entry and return in
  `doc/design/reference/world/observations/2026-09-07_forpost_grid_and_action_audit.md`
- Exact cell/room ordinary-chat and presence boundaries in
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`
- [Mine/exchange live lobby controls](../world/observations/2026-09-09_starter_landmarks_and_art.md)
  and [official-wiki reference](../world/observations/2026-09-09_mine_exchange_wiki.md).
  These observations are owned by World and linked here without copying them.

## Current Neverlands behavior

The captured Lavka is a City building with mode tabs, category/filter controls,
dense buy/sell rows, requirements, prices, stock, player funds, and City return.
The current Forpost entry is on Central Square. The later village pass also
enters Shop from Village Square: Shop shows its own player list, and its Village
return restores the square before a separate Leave action exits to the same
outdoor cell. Matching Shop labels do not combine distinct location audiences.
The supplied social addendum separately confirms a successful NPC search can
report `24 NV`; it does not expose source wallet persistence, the NPC identity,
or drop probability.

The later mine capture records displayed item/license details and purchase
controls; the exchange capture records three section shells and resource
selectors. No purchase, exchange query/listing, transaction or storage action
was submitted. The older wiki describes a distinct exchange trading model,
whose current operation rules still need live confirmation.

## Evidence gaps

- Full market trading, player transfers, license effects, repair, stock
  replenishment, and several service-building transaction flows remain open.
- The village entry/return observation does not establish a distinct stock
  pool, new prices, or additional trading mechanics for that Shop.
- The [mine/exchange operations backlog](observations/evidence_needed_mine_exchange_operations.md)
  owns missing acquisition, query/listing, settlement and storage captures.
  Displayed license durations are known; acquisition/activation/expiry and
  successful or failed economic outcomes remain distinct questions.

## Design linkage

- `doc/design/features/economy_trading_shops.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/shop_economy.md`
- Current entry/resume accepts an active City hotspot or exact-cell linked
  village feature; the persisted parent selects City versus Village return.
  Location and timed-action guards remain authoritative for direct requests.
- World ships mine/exchange lobbies with read-only controls and location
  resume. Their economic operations remain unimplemented under the
  [Economy gap table](../../../features/shop_economy.md#65-mine-shop-and-resource-exchange-gap-ownership).
  Professions owns license use and extraction; Dungeons tracks underground
  travel. The lobbies do not promote either feature to implemented.

### Responsible implementation files

- `app/controllers/shop_controller.rb`
- `app/services/game/shop/catalog.rb`
- `app/services/game/shop/purchase.rb`
- `app/services/economy/wallet_service.rb`
- `app/services/arena/npc_loot_awarder.rb` (Combat-owned ingress)
- `app/assets/stylesheets/shop.css`

Local implementation linkage is context, not Neverlands evidence.
