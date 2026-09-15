# Neverlands Economy and Shop Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Economy domain](../../../domains/economy.md).

- Document type: neverlands-source-summary
- Domain: economy
- Updated: 2026-09-10
- Evidence status: current for one Shop purchase and Inventory handoff, captured rows and mine/exchange lobbies; other economic operation captures incomplete

## Current observations

- [September 10 Shop layout and frame-relative entrance sizing](observations/2026-09-10_shop_layout_and_entrance_scale.md)
- [September 10 starter catalog: 79 goods, six licenses and empty source sections](observations/2026-09-10_starter_shop_catalog.md)

- [Licenses, Shop selling and September 10 wiki prerequisite clarification](observations/2026-09-09_licenses_and_shop_selling.md#profession-prerequisites-wiki-clarification-2026-09-10)
- `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`
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
The [current layout measurement](observations/2026-09-10_shop_layout_and_entrance_scale.md)
distinguishes the 1250 × 600 natural illustration from its displayed size:
the entrance scales with gameplay-frame height between 625 × 300 and
1250 × 600, above a centered 800px catalog. Its four tabs directly follow a
4px entrance gap; categories are icon-only with title tooltips.
The September 9 pass completed one 7-NV penknife purchase: the player paid
7 NV, gained one 10/10-durability carried item and 5 mass, and the shared Shop
stock refreshed. Buying consumes available Shop stock. Inventory and Return
confirmed the item and same Shop context; source database internals are not
visible. The same pass confirmed six disabled license cards and a novice
section denial for a level-17 player, explicitly restricted to below level 10.
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

The later Sell attempt rejected an unlicensed character unchanged. Healthy and
worn quotes match a 20% initial return, adjusted for durability. The official
Trader page documents the 20–70% skill tiers, independent Shop funds/supply,
full-stock refusal and insufficient-merchant-funds refusal. License ownership
appears under Abilities → Your licenses. The
[prerequisite matrix](observations/2026-09-09_licenses_and_shop_selling.md#license-purchase-requirements)
separates Merchant/Healer perks, numeric proficiency, quest qualification and
timed licenses. It records Merchant onboarding and distinguishes Doctor I from
the Traumatologist requirement for Doctor II/III: 100 Doctor skill unlocks that
quest, rather than establishing a separate ongoing license-purchase threshold.

## Evidence gaps

- The successful purchase is observed; insufficient-money/capacity attempts,
  source replay/expiry responses, isolated concurrent settlement and stock
  replenishment remain uncaptured. Successful sale and eligible novice/license
  mutations remain separate gaps.
- Full market trading, player transfers, license effects, repair, stock
  replenishment, and several service-building transaction flows remain open.
- The official Trader page establishes independent Shop stock/funds. The village
  opening balances and assortment still require their own capture; matching
  labels or navigation do not justify copying Forpost supply.
- The [mine/exchange operations backlog](observations/evidence_needed_mine_exchange_operations.md)
  owns missing acquisition, query/listing, settlement and storage captures.
  Displayed license durations are known; acquisition/activation/expiry and
  successful or failed economic outcomes remain distinct questions.

## Design linkage

- `doc/design/features/economy_trading_shops.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/shop_economy.md`
- The bounded catalog uses 19 categories and explicitly authored goods. Buy
  atomically changes wallet/ledger, item/mass, stock and a consumed capability;
  replay cannot repeat a trade. Typed license permissions, separate Shop accounts
  and licensed selling are implemented; Novice grants no ordinary purchase. Original scene/category art and exact prompts live in `doc/ARTWORK.md`.
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
