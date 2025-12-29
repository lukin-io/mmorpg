# 2. Social Systems — Economy & Trading Flow

## Overview
- Covers multi-currency wallets, auction house, kiosk marketplace, and direct trades from `doc/features/2_user.md` + `9_economy.md`.
- Currency movements run through `CurrencyWallet` + `CurrencyTransaction` for auditing.
- Auction listings and bids exposed through HTML controllers plus Hotwire-ready tables.

## Domain Models
- `CurrencyWallet`, `CurrencyTransaction` — track balances and immutable ledger rows.
- `AuctionListing`, `AuctionBid`, `MarketplaceKiosk` — represent public trading venues.
- `TradeSession`, `TradeItem` — secure, dual-confirmed trades including item + currency payloads.

## Services & Workflows
- `Economy::WalletService` centralizes currency adjustments/soft caps. `Economy::TaxCalculator` + `Economy::ListingFeeCalculator` apply city/ownership modifiers, and `Economy::ListingCapEnforcer` keeps inflation in check.
- `Marketplace::ListingEngine` validates params, calculates tax/fees, and persists `AuctionListing` rows. `Marketplace::ListingFilter` powers advanced search UI.
- `Trades::SessionManager` starts sessions, enforces TTL, and handles two-step confirmations; `Trades::PreviewBuilder` powers the anti-scam UI and `Trades::SettlementService` moves currency/premium tokens after completion.
- `Economy::AnalyticsReporter` + `Economy::FraudDetector` feed `EconomicSnapshot`/`EconomyAlert` tables via `EconomyAnalyticsJob`.

## Controllers & UI
- `AuctionListingsController` (`index/new/create/show`) with nested `AuctionBidsController#create` for bidding.
- `MarketplaceKiosksController#index` lists quick-sell kiosks and provides a form to add entries.
- `TradeSessionsController` handles starting, viewing, and confirming trade sessions; `TradeItemsController` manages per-player contributions. View `app/views/trade_sessions/show.html.erb` renders the contribution preview before confirmation.

### Hotwire UI Notes
- **Auction bids:** The bid field uses HTML5 constraints (for example `min`) so obviously-invalid values are blocked client-side; server-side validations still enforce correctness and authorization.
- **Trade sessions:** Offers can include both items and currency. The UI renders each offer line with an icon; `TradeSessionsHelper#trade_item_icon` treats currencies explicitly and falls back safely when item metadata/templates are missing.
- **Authorization:** Trade sessions are restricted to participants (non-participants should see an authorization error rather than a partial/empty trade UI).

## Policies & Security
- `AuctionListingPolicy`, `TradeSessionPolicy` ensure only verified players list/bid and only participants confirm trades.

## Testing & Verification
- Model specs for wallets, listings, bids.
- Service specs for tax calculator, listing engine, trade session manager.
- Request specs covering listing creation, bidding, and trade confirmation flows.
- System spec: `spec/system/economy_group_loops_spec.rb` covers bidding and trade session UI flows end-to-end.

---

## Responsible for Implementation Files
- models:
  - `app/models/currency_wallet.rb`, `app/models/currency_transaction.rb`, `app/models/auction_listing.rb`, `app/models/auction_bid.rb`, `app/models/marketplace_kiosk.rb`, `app/models/trade_session.rb`, `app/models/trade_item.rb`
- services:
  - `app/services/economy/tax_calculator.rb`, `app/services/marketplace/listing_engine.rb`, `app/services/trades/session_manager.rb`
- controllers/views:
  - `app/controllers/auction_listings_controller.rb`, `app/controllers/auction_bids_controller.rb`, `app/views/auction_listings/*`
  - `app/controllers/marketplace_kiosks_controller.rb`, `app/views/marketplace_kiosks/index.html.erb`
  - `app/controllers/trade_sessions_controller.rb`, `app/views/trade_sessions/show.html.erb`
- policies:
  - `app/policies/auction_listing_policy.rb`, `app/policies/trade_session_policy.rb`
- database:
  - `db/migrate/20251121142307_create_economy_and_trading.rb`
- docs/tests:
  - `doc/flow/2_user_economy_trading.md`, associated specs (to be expanded under `spec/models`, `spec/services`, `spec/requests`).
