# Economy Guide

Reviewed against the working tree and preserved Neverlands evidence on
**2026-09-15**. This book explains where NV comes from, who owns it, how Shop
stock and prices work, and how qualification, licenses and receipts constrain
payments. Authored prices/stock are baselines; this is not a live balance sheet.

Follow the [Economy domain](domains/economy.md),
[source summary](design/reference/economy/README.md),
[normalized design](design/features/economy_trading_shops.md) and
[MVP scope](design/launch_mvp_plan.md). The
[Shop and Economy handbook](features/shop_economy.md) owns transaction/UI
guarantees and acceptance. [ITEMS](ITEMS.md) owns the complete item catalog,
[FORMULAS](FORMULAS.md#9-inventory-and-economy) the exact calculations,
[WORLD](WORLD.md) location access and [MEDICAL](MEDICAL.md) treatment settlement.

## Contents

1. [Scope and evidence](#1-scope-and-evidence)
2. [Money, goods, stock and permissions](#2-money-goods-stock-and-permissions)
3. [Player flows and payment rules](#3-player-flows-and-payment-rules)
4. [Prices, formulas and economic effects](#4-prices-formulas-and-economic-effects)
5. [UI, events and artwork](#5-ui-events-and-artwork)
6. [Implementation and state ownership](#6-implementation-and-state-ownership)
7. [Editing and extension recipes](#7-editing-and-extension-recipes)
8. [Use cases and cross-feature effects](#8-use-cases-and-cross-feature-effects)
9. [Verification, gaps and maintenance](#9-verification-gaps-and-maintenance)

## 1. Scope and evidence

Implemented: user NV wallets and ledger, stocked City/linked-village Shop,
Hospital purchases through the same pipeline, one-unit buy/sell offers,
durability/proficiency resale, six timed licenses, Merchant qualification,
bounded NPC and progression credits, direct Inventory transfers and medical
fees. These do not establish a complete marketplace, banking or premium billing
system.

| Provenance | What it establishes |
|---|---|
| [September 9 Shop purchase](design/reference/economy/observations/2026-09-09_city_shop_purchase.md) | Live 7 NV Penknife purchase, confirmation and Inventory handoff |
| [License/selling evidence](design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md) | Live unlicensed sale rejection and displayed resale/condition examples; published Trading rates, Shop funds/stock rules and license prerequisites |
| [Starter assortment capture](design/reference/economy/observations/2026-09-10_starter_shop_catalog.md) | Source goods, prices, requirements, stock and dense category/row presentation |
| [Chat/economic event capture](design/reference/social/observations/2026-08-23_chat_game_event_timeline.md) | Actual recipient-visible NPC item/NV feedback; a captured amount is not a universal loot formula |
| [NPC/combat calibration](design/features/combat_calibration.md) | Authorized local loot probability/amount fits and level-window behavior |
| [Shop handbook](features/shop_economy.md), [Medical handbook](features/medical_care.md) | Local settlement, recovery and browser proof; not source transaction completion evidence |

Successful live Neverlands sale and eligible license activation have not been
established by the captured purchase alone. License activation at local payment
is an explicit implementation interpretation. Preserve these boundaries even
when local tests pass.

## 2. Money, goods, stock and permissions

### Authoritative records

| Entity | Meaning and important boundary |
|---|---|
| `CurrencyWallet` | One NV balance per **User**; a character spends its user's wallet |
| `CurrencyTransaction` | Signed amount, reason, metadata and resulting balance; reconstructs a committed wallet mutation |
| `ShopAccount` | Separate funds for the resolved City hotspot or linked building; not an unlimited global merchant wallet |
| `ShopStock` | Current quantity and optional maximum for one account/template pair |
| `ItemTemplate` | Stable definition, base price, requirements, effects and Shop eligibility; not an owned unit |
| `InventoryItem` | Owned quantity, condition, binding/equipment and property overrides |
| `WorldActionOffer` | Character/location/action/target-bound, expiring Shop terms; consumed with settlement |
| `CharacterLicense` | Purchased timed permission with its offer reference; not an Inventory stack |
| Merchant qualification metadata | Accepted → paid → completed progress with a real wallet receipt; not a freely inferred perk effect |

New user wallets start at 0 NV. Explicit sample-account starter grants are
separate seed data, issued once through a ledger guard. Level grants and NPC
money are separate producers; rerunning seeds must not reset an existing balance.

The ordinary assortment and six license definitions are cataloged in
[ITEMS](ITEMS.md#2-current-item-catalog). Current executable attack-scroll
purchases and remaining catalog-only variants are distinguished in
[SCROLLS](SCROLLS.md). Hospital's four bag definitions, prices, initial stock and
use requirements are in [MEDICAL](MEDICAL.md#2-injury-and-medical-content).

Only a Shop's persisted stock decides live availability. Buying requires a
positive current quantity. Selling requires a matching stock row with an
explicit maximum and `current < maximum`. A missing maximum is not “unlimited
returns”; missing stock is not permission to sell every item in the game.
Seeds preserve traded stock and funds. Automatic replenishment is not implemented.

### Licenses

| Stable key | Price NV | Duration | Purchase qualification |
|---|---:|---:|---|
| `trading_license_i` | 300 | 3 days | Merchant perk + completed Merchant qualification |
| `trading_license_ii` | 800 | 10 days | Same |
| `trading_license_iii` | 2,000 | 30 days | Same |
| `doctor_license_i` | 300 | 5 days | Healer perk |
| `doctor_license_ii` | 550 | 10 days | Healer perk + Traumatologist unlock |
| `doctor_license_iii` | 800 | 15 days | Same |

Definitions are in [Shop seeds](../db/seeds/shop_inventory.rb); kind/tier/duration
are validated by [LicenseRules](../app/services/game/shop/license_rules.rb).
Stack limit must be 1. Arbitrary `required_perk` text or an item named “license”
cannot substitute for the typed gate.

Buying immediately creates the timed license, debits NV, credits Shop funds and
decrements its stock. It does not add carried weight or an Inventory item.
An already active license of the same **kind** blocks another purchase, including
a different tier; there is no stacked extension. Active means start ≤ now <
expiry. Expired licenses disappear from Your licenses while purchase history
remains stored.

Merchant and Healer are [boolean perks](PERKS.md#2-implemented-perks); Trading
and Doctor are [numeric profession counters](SKILLS.md#profession-counters).
Trading affects sale price. Doctor/Knowledge gate bag use, not ordinary bag
purchase. Doctor II/III's complete qualification quest remains absent; those
catalog rows do not demonstrate a player can finish that quest locally.

## 3. Player flows and payment rules

### Enter and buy

Enter a reachable City Shop hotspot or the exact-cell linked Village Shop;
Hospital selects its own account through the same `Game::Shop::Location` owner.
Browse a category/mode, inspect price/requirements/stock, choose Buy and confirm.
Ordinary goods are bought one unit at a time. Check Inventory afterward and
equip/use only if the item's separate requirements are satisfied.

The server validates the active character, location/room context, idle state,
action key, target, offer expiry and unchanged quoted item definition. It locks
the relevant records and checks current stock, funds, inventory mass/slots and
license qualification where applicable. Ordinary equipment/bag requirements
do not prohibit purchase; they are enforced by equip/use owners.

One successful purchase debits the player's wallet, credits this Shop's funds,
decrements one stock unit, acquires the item or typed license, writes the wallet
receipt and completes the offer atomically. Failure leaves these valuable
records unchanged. A stale/double-clicked completed offer rejects with refresh
feedback, rather than performing a second purchase.

### Qualify as a Merchant

1. Own the Merchant perk and enter the Forpost Market (`forpost1` node, Market
   building). Accept the qualification; saved progress becomes `accepted`.
2. Go to the Central Square Shop (`main` node). Pay **1,000 NV** for the receipt.
   The transaction credits Shop funds, records `shop.merchant_qualification`,
   and saves `paid` with the ledger identity and payment time.
3. Return to the Market and complete. The service verifies the actual matching
   wallet receipt and character before setting `profession_unlocks.merchant`
   to true and progress to `completed`.
4. Visit Shop → Licenses to buy a Trading license. Qualification did not include
   its purchase price, grant an Inventory item or increase Trading proficiency.

Location, perk and busy-state checks happen under the character lock. Repeating
a completed step does not charge again. An invalid progress/receipt state fails
closed; the browser cannot grant qualification merely by posting `completed`.

### Sell to Shop

Open Sell Goods with a currently active Trading license. The chosen item must
still belong to the character, have positive quantity, be unequipped/tradable
and have valid nonbroken condition. Equipped, bound, protected/locked or
`personal_only` items are excluded by the existing tradability rule. Sale
removes one unit, not an entire stack selected by a forged quantity.

After locks, Shop checks the offer's item/condition/Trading snapshot, current
license, a matching stock row with room for a return, positive resale value,
sufficient Shop NV and wallet storage headroom. Success removes one owned unit
and its weight, pays the wallet, debits Shop funds, restores one stock unit and
commits the receipt/offer together. Full stock, missing license or insufficient
Shop funds leaves all of them unchanged. Reload shows the resulting counts.

### Other implemented NV flows

| Flow | Current producer/consumer boundary |
|---|---|
| Level rewards | [CHARACTER](CHARACTER.md) applies each reached level's configured NV with its XP/point transaction |
| NPC loot | [NPC](NPC.md#6-loot-and-experience) / [COMBAT](COMBAT.md) roll eligible typed entries once and credit actual NV or award real item templates; no separate generic sale value is inferred |
| Paid medical treatment | [MEDICAL](MEDICAL.md) revalidates an accepted patient quote and moves its exact fee between wallets with cure and bag use |
| Inventory NV transfer | Sender chooses a named other character and a positive amount; the existing service debits/credits wallets in one transaction with sent/received ledger reasons, without a configured fee |
| Item transfer/gift | Inventory validates owned/tradable quantity and recipient mass/slots; no NV is paid |

Direct transfer does not establish buyer consent for a sale. Player-to-player
paid item sales deliberately return unavailable even with a Trading license;
there is no implemented buyer-acceptance settlement. Direct transfers also do
not use Shop's one-use offer receipt, so do not claim universal replay protection
for every wallet caller. Their detailed guarantees remain Inventory-owned.

## 4. Prices, formulas and economic effects

### Resale

The exact reference is [ECON-01](FORMULAS.md#econ-01--shop-purchase-sale-and-nv-transfers).
Trading is the nonnegative integer `metadata.profession_skills.trading`;
missing/malformed data reads as 0. This reader does not add equipment bonuses.

| Minimum Trading proficiency | Percentage of base price |
|---:|---:|
| 0 | 20% |
| 100 | 30% |
| 225 | 40% |
| 350 | 50% |
| 475 | 60% |
| 600 | 70% |

Choose the highest reached threshold. Calculate
`base_price × percentage / 100 × current_durability / maximum_durability`
for a durable item, then round **once to two decimals** using decimal arithmetic.
A nondurable item has no wear multiplier. Invalid durable values return zero
from the calculator, and the sale workflow additionally rejects invalid/broken
items. An eligible quote is not a promise of Shop funds or spare stock capacity.

For a 7 NV Penknife, Trading 0 gives 1.40 NV at 10/10 durability and 1.12 NV
at 8/10. Trading 600 with 8/10 gives 3.92 NV. Neither the Merchant perk nor a
higher Trading license tier adds a price multiplier. Automatic Trading growth
is not implemented.

### Conservation, credits and bounds

- Purchase: player NV − price; Shop NV + price; Shop stock −1; owned unit or
  typed license +1. Sale reverses the resource directions at the resale price.
- Treatment/direct money transfer: sender NV − amount; recipient NV + amount.
  A treatment fee is not a Shop credit or an additional system tax.
- NPC/progression rewards create their awarded NV through the wallet writer;
  they are not debited from an imaginary NPC wallet. Loot probabilities and XP
  limits are independently owned by [FORMULAS](FORMULAS.md#6-experience-loot-and-premium).
- Persisted wallet/Shop balances cannot be negative. The exclusive
  10,000,000,000 NV limit comes from decimal storage, not a Neverlands gameplay
  wealth cap. Trades check receiver headroom before settlement.

Each Shop offer lasts ten minutes and is checked again after locks immediately
before the first settlement write. A changed price, item definition, owned
condition/quantity or Trading proficiency invalidates its saved terms. Live
stock is checked independently: another customer's purchase does not itself
change the item's quoted identity or price.

Premium combat entitlement currently changes specified search windows and XP
caps, not item prices, sale rates, currency denomination or a real-money checkout.
No unspecified economic multiplier is inferred from a paid artifact's source
price.

## 5. UI, events and artwork

Shop uses the shared game shell with Buy Goods, Sell Goods, Licenses and For
Beginners modes, 19 observed category controls, compact item rows, NV and stock
information, confirmation and visible result feedback. Category/mode filters
resume only in a still-valid location. Level 10+ sees the beginner denial;
lower levels see the currently empty beginner section without invented offers.

Buy → Inventory → equip/inspect/unequip → Shop → Sell is a complete cross-owner
flow. City Shop returns to its City node. Village Shop first returns to Village
Square, with a separate outdoor exit. An outdoor Look/movement or invalid
location cannot be bypassed with a stale Shop URL. World owns position; Shell
owns the saved room and its chat audience.

Use [ARTWORK's Shop specifications](ARTWORK.md#shop-item-and-category-image-specifications)
for the original 384×384 item/license PNGs, category atlas and exact consumer
sizes. Ordinary goods use the 62×91 CSS image box with contain fit; Inventory
uses the same item art at 60×60. Hospital bags have their own native dimensions
documented in MEDICAL/ARTWORK. [ITEMS](ITEMS.md#5-artwork-and-presentation) maps
stable item keys to assets. Presentation does not manufacture stock, eligibility
or an effect from an illustration.

NPC money/item awards and medical completion publish actual committed facts to
the [central event catalog](features/game_shell.md#gameplay-event-catalog).
Shop flash messages and durable currency receipts have their own roles; not
every wallet transaction automatically becomes a global chat message.

## 6. Implementation and state ownership

| Owner | Public responsibility / result |
|---|---|
| [WalletService](../app/services/economy/wallet_service.rb) / [CurrencyWallet](../app/models/currency_wallet.rb) | `adjust!(amount:, reason:, metadata:)` → updated locked wallet and ledger; rejects zero/insufficient funds and rolls back balance if ledger writing fails |
| [ShopAccount](../app/models/shop_account.rb), [ShopStock](../app/models/shop_stock.rb) | Location funds and unique per-template stock/capacity invariants |
| [Location](../app/services/game/shop/location.rb) | Current character context → authorized Shop/building/account fingerprint |
| [Catalog](../app/services/game/shop/catalog.rb) | Mode/category/owned-item presentation and authoritative price helpers |
| [TradeOffers](../app/services/game/shop/trade_offers.rb) | Issue/reuse visible terms; perform one matching action with character/offer/account locks, deadline/state revalidation and transactional completion |
| [Purchase](../app/services/game/shop/purchase.rb), [Sale](../app/services/game/shop/sale.rb) | Character + template/owned item + action key + quantity 1 → success/message result or unchanged-state failure; item/license/NV/stock/receipt settlement |
| [ResalePrice](../app/services/game/shop/resale_price.rb) | Pure base price, proficiency and condition → decimal payout; no database writes |
| [LicenseRules](../app/services/game/shop/license_rules.rb), [CharacterLicense](../app/models/character_license.rb) | Definition/permission validation, purchase activation, saved start/expiry and offer identity |
| [MerchantQualification](../app/services/game/shop/merchant_qualification.rb) | Character + allowlisted step/clock → state/result; locked receipt payment and verified completion |
| [ShopController](../app/controllers/shop_controller.rb) | Authenticated mode/form actions and authoritative rendered/redirected feedback |
| [Inventory TransferService](../app/services/game/inventory/transfer_service.rb) | Direct item/NV transfer; paid player sale remains disabled |

Purchase/Sale extend TradeOffers' transaction and consistent record locking.
Inventory capacity, wallet balance, current stock, condition and permissions
are checked at mutation time. Receipts preserve item/key, unit price, before/
after balances and stock, quantity/weight changes and acquired license identity
where applicable, including after a sold InventoryItem row is removed.

The low-level wallet writer is not a global idempotency service. Shop uses a
consumed offer; Merchant uses saved progress plus its real receipt; Combat uses
award/finalization guards; paid Medical uses completed treatment. Keep each
workflow's retry boundary explicit. Reload/broadcast order cannot authorize a
payment.

## 7. Editing and extension recipes

### Change an item price or stock policy

Edit the stable definition through [ITEMS' authoring recipe](ITEMS.md#6-editing-recipes):
ordinary Shop goods use `db/seeds/data/starter_shop.json`, licenses use
`db/seeds/shop_inventory.rb`, and Hospital bags use `db/seeds/combat_care.rb`.
Existing inventory instances refer to template base price; sale condition and
properties remain instance state. Changed template terms invalidate open Shop
offers on execution; completed receipts retain their original prices.

Trace the seed's create/update semantics before applying it. First-created
ShopAccount/ShopStock defaults are not a refill command and do not overwrite
spent funds or traded quantities. An intentional stock/fund correction needs
an exact-target operation and post-check; there is no general player-facing
balance/stock editor. Do not change historical ledger entries to make a new
price appear retroactive.

### Change resale, license or qualification rules

Tune `ResalePrice::RATES` only with Neverlands evidence or explicit approved
calibration. Keep decimal rounding order; check just below/at every changed
threshold, worn items and recipient limits. Update FORMULAS, SKILLS' Trading
consumer and this guide's examples with the Shop handbook.

License durations must agree between seed definitions and `LicenseRules`'
kind/tier map. Existing purchased licenses keep their stored expiry; current
rules govern a new purchase. Editing a license does not implement its missing
profession quest, and a higher tier must not silently alter bag eligibility.
Update SCROLLS, PERKS, MEDICAL and character license display when their contracts
change. Merchant qualification uses its own receipt/state checks; preserve the
paid retry boundary when changing the cost or steps.

### Add another NV producer or commerce flow

Use the existing wallet writer and ledger with an explicit reason and bounded
receipt metadata. Define who authorizes the payment, the inventory/state it
must commit with, receiver limits, failure behavior and the producer's duplicate
guard. A common wallet does not make a new exchange, bank or premium checkout
implemented. Add a source-backed owner and acceptance for the actual flow;
connect its real event producer to the existing Shell catalog.

## 8. Use cases and cross-feature effects

The following are current-rule illustrations, not newly observed source trades.

### Eligible NPC loot → item sale → license purchase

Assume a character already has Merchant qualification and a valid Trading
license, Healer perk, Trading 0 and 299 NV. An eligible below-level-13 NPC's
calibrated weapon entry happens to award a full-condition Penknife. This is a
possible existing loot entry, **not a guaranteed drop**; level/search rules,
entry RNG, capacity and the once-only award guard still apply.

Return to a Shop that accepts Penknives, has spare stock capacity and at least
1.40 NV. Sell the unequipped item for 1.40 NV: wallet becomes 300.40, Shop funds
fall by 1.40 and stock rises by one. Buy Doctor License I from an in-stock row
for 300 NV: wallet becomes 0.40, Shop funds rise by 300 and a five-day Doctor
license appears under Your licenses. A matching bag, Knowledge and Doctor
proficiency are still needed to treat anyone. Owning loot did not bypass
Trading permission or provide an injury-cure capability.

### Other boundaries

| Preconditions → action | Authoritative outcome / other owner |
|---|---|
| Merchant perk, no qualification, 1,300 NV → complete Market → Shop → Market, then buy Trading I | Pay 1,000 once for qualification and 300 for a three-day license; wallet ends at 0. Trading proficiency remains unchanged. A 1,000 NV wallet could qualify but could not also buy the license. |
| 7 NV Penknife at 8/10, Trading 0 → sell to an eligible funded Shop | Receive 1.12 NV, not 1.40. Combat wear affects later economic value through saved condition. |
| Active Trading III and enough personal NV → sell into a full Shop stock row | Reject unchanged. License tier and the player's funds cannot override return capacity or substitute for the Shop's funds. |
| Open Buy form → item price changes, offer expires or player leaves Shop → confirm | Revalidation rejects unchanged; refresh at a valid location to obtain current terms. |
| Enough NV/capacity, Doctor 0 → buy a beginner healer bag | Purchase may succeed. Treatment later fails its Doctor 100 use gate without spending a use; MEDICAL owns qualification. |
| Match reward or paid treatment acceptance is retried | Its owning settlement guard prevents duplicate reward/payment; chat reflects the committed fact. Directly calling WalletService again is not that guarded retry. |
| An NPC drops an item absent from this Shop's stock catalog | It remains owned loot; sale is unavailable here. Lootability and merchant acceptance are separate definitions. |

## 9. Verification, gaps and maintenance

The September 15 [Mass source follow-up](design/reference/character/observations/2026-09-15_stats_guide_linked_definitions.md)
adds a published Merchant-qualified overload trading exception. Its
[formula and precision boundary](FORMULAS.md#source-only-overload-and-merchant-capacity)
are source-only; current Inventory/transfer admission still uses the hard
capacity cap. This is separate from implemented Merchant license qualification
and Shop resale pricing. [STATS](STATS.md#capacity-and-overload) explains the
underlying capacity and other absent overload effects.

Protecting checks include [wallet specs](../spec/services/economy/wallet_service_spec.rb),
[trade integration](../spec/services/game/shop/trades_spec.rb),
[sale rules](../spec/services/game/shop/sale_spec.rb),
[resale math](../spec/services/game/shop/resale_price_spec.rb),
[licenses](../spec/services/game/shop/license_rules_spec.rb),
[Merchant qualification](../spec/services/game/shop/merchant_qualification_spec.rb),
[Shop requests](../spec/requests/shop_spec.rb) and
[Shop system flow](../spec/system/shop_purchase_spec.rb).
The [September 11 manual Shop acceptance](features/shop_economy.md#september-11-pre-merge-manual-shop-acceptance)
records buy/cancel/equip/unequip/sell/reload through the actual UI. Medical and
Inventory handbooks own their later handoff proof. This guide's docs-only review
does not rerun those browser, runtime-suite or CI checks.

- `[EVIDENCE]`: successful source sale/license activation, replenishment and
  uncaptured error/commerce dialogs remain distinct from local test coverage.
- `[IMPL]`: complete beginner commerce, automatic Trading growth, Doctor
  qualification quests, repair and player-sale buyer acceptance remain absent.
- Mine Shop/resource exchange have read-only location shells; transactions,
  listings and storage remain under the [Economy gap table](features/shop_economy.md#65-mine-shop-and-resource-exchange-gap-ownership).
- Generic banking, auctions and premium payments are not implemented by the
  NV wallet. Transport fare capability does not prove an available authored
  passenger route; [WORLD](WORLD.md) owns the current route boundary.

Maintain this guide when prices, stock/funds, receipts, qualification, licenses,
reward ingress or payment rules change. Synchronize the affected Shop handbook,
FORMULAS and actual ITEMS/SKILLS/PERKS/MEDICAL/CHARACTER/NPC/SCROLLS/WORLD consumers
under the [documentation update rules](DOCUMENTATION.md#22-change-triggered-documentation-updates).
