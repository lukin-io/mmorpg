# 9. Economy & Trading Flow

## Overview
- Implements `doc/features/9_economy.md`: currency wallets, trading loops, auctions, sinks/sources, and analytics.
- Ensures every gold/silver/premium token transaction is deterministic, auditable, and tied to a Rails service or job.

---

## Models & Persistence
- `CurrencyWallet`, `CurrencyTransaction`, `PremiumTokenLedgerEntry` — per-user balances, soft caps, and immutable audit trails.
- `AuctionListing`, `AuctionBid`, `MarketplaceKiosk`, `TradeSession`, `TradeItem` — structured trading venues (auction house, kiosks, direct trades).
- `Recipe`, `InventoryItem`, `CraftingJob` — tie into economy sinks (repairs, crafting fees, housing upkeep).
- YAML/config references: `config/gameplay/economy.yml`, `config/gameplay/auction_house.yml`, seeds for kiosks and sinks.

---

## Services & Orchestration
- `Economy::WalletService` — the only place balances change; enforces soft caps, records sinks (`wallet.record_sink_total!`), and raises `InsufficientFundsError`.
- `Economy::ListingFeeCalculator`, `Economy::TaxCalculator`, `Economy::ListingCapEnforcer` — govern auction fees and caps before `AuctionListingsController` persists records.
- `Trades::SessionManager`, `Trades::SettlementService`, `Trades::PreviewBuilder` — deterministic dual-confirm trades, reuse WalletService for settlements.
- `Marketplace::ListingFilter`, `Marketplace::StockRefresher` — kiosk searches and periodic restock logic.
- `Payments::PremiumTokenLedger` — wraps ledger writes and notifies WalletService of premium token changes.
- `Game::Inventory::ExpansionService` and `Housing::UpkeepService` — economy sinks invoked after quest rewards, crafting jobs, or housing loops.

---

## Controllers & Views
- `AuctionListingsController` + `AuctionBidsController` — Turbo-enabled listing creation and bidding; consult WalletService and fee calculators before commit.
- `MarketplaceKiosksController` — read-only kiosk browsing plus deterministic restock UI cues.
- `TradeSessionsController`, `TradeItemsController`, `TradeItems` Turbo partials — multi-step trading handshake with rate-limited invites.
- `ClanTreasuryTransactionsController`, `GuildBankEntriesController` — shared treasury deposits/withdrawals with config-driven limits.
- `Dashboards`/HUD integration — economy widgets on `/dashboard` showing wallet balances and sink summaries via `Users::ProfileStats`.

### Premium Store UI (✅ Implemented)
**Controller:** `PremiumStoreController` — index, show, purchase, gift
**Service:** `Premium::ArtifactStore` — artifact catalog, purchase!, gift!
**Flow:**
1. Player opens `/premium_store` → displays token balance, featured items
2. Browse by category (cosmetics, mounts, pets, boosts, storage, titles)
3. View item details → shows price, benefits, restrictions
4. Purchase → `Premium::ArtifactStore#purchase!` validates tokens, grants artifact
5. Gift → sends artifact to another player's account

**Key Behaviors:**
- **Unique Items:** Some artifacts can only be owned once
- **Gifting:** Send premium items to friends
- **Duration Items:** Boosts expire after set time (7 days typical)
- **Artifact Effects:** Auto-applies to character (mounts, pets, titles, storage)

### Marketplace Kiosks UI (✅ Implemented)
**Controller:** `MarketplaceKiosksController` — show, quick_buy, quick_sell
**Flow:**
1. Player interacts with kiosk in world → opens `/marketplace_kiosks/:id`
2. Quick Buy panel: fixed-price common items (potions, materials)
3. Quick Sell panel: sell inventory items at vendor rates
4. Local Listings: view zone-specific auction listings
5. All transactions use `Economy::WalletService`

**Key Behaviors:**
- **Zone-Based:** Kiosks show local listings only
- **Quick Transactions:** No auction delay for common items
- **Vendor Prices:** Quick-sell uses base item value (no bidding)

---

## Jobs & Analytics
- `EconomyAnalyticsJob` → `Economy::AnalyticsReporter` + `Economy::FraudDetector` — nightly snapshots of sinks/sources, suspicious deltas.
- `LiveOps::EconomyAlertJob` — escalates surge detection to moderation channels when thresholds in `REPORT_VOLUME_ALERT_THRESHOLD` or economy config are exceeded.
- `ScheduledEventJob` — seeds seasonal sinks (festivals, repair discounts).
- `Payments::PremiumTokenSyncJob` — reconciles external purchases with internal ledger.

---

## Policies & Security
- `AuctionListingPolicy`, `TradeSessionPolicy`, `MarketplaceKioskPolicy` — scope queries to owning users or allow read-only market visibility.
- `ClanTreasuryTransactionPolicy`, `GuildBankEntryPolicy` — enforce role-based caps from config.
- All balance-changing endpoints must call WalletService and wrap actions in transactions; no controller/model should mutate balance columns directly.

---

## Testing & Verification
- Specs: `spec/services/economy/wallet_service_spec.rb`, `spec/services/trades/session_manager_spec.rb`, `spec/requests/auction_listings_spec.rb`, `spec/requests/trade_sessions_spec.rb`, `spec/services/economy/analytics_reporter_spec.rb`.
- Ensure factories (`currency_wallet`, `auction_listing`, `trade_session`, `premium_token_ledger_entry`) include realistic defaults (soft caps, currency types).

---

## Responsible for Implementation Files
- **Models:** `app/models/currency_wallet.rb`, `currency_transaction.rb`, `premium_token_ledger_entry.rb`, `auction_listing.rb`, `auction_bid.rb`, `marketplace_kiosk.rb`, `trade_session.rb`, `trade_item.rb`, `clan_treasury_transaction.rb`, `guild_bank_entry.rb`.
- **Services:** `app/services/economy/**`, `app/services/trades/**`, `app/services/marketplace/**`, `app/services/payments/premium_token_ledger.rb`, `app/services/game/inventory/expansion_service.rb`, `app/services/housing/upkeep_service.rb`, `app/services/premium/artifact_store.rb`.
- **Controllers:** `app/controllers/auction_listings_controller.rb`, `auction_bids_controller.rb`, `marketplace_kiosks_controller.rb`, `trade_sessions_controller.rb`, `trade_items_controller.rb`, `clan_treasury_transactions_controller.rb`, `guild_bank_entries_controller.rb`, `premium_store_controller.rb`.
- **Views:** `app/views/auction_listings/*`, `app/views/trade_sessions/*`, `app/views/marketplace_kiosks/*`, `app/views/premium_store/*`.
- **Helpers:** `app/helpers/premium_store_helper.rb`.
- **Jobs:** `app/jobs/economy_analytics_job.rb`, `app/jobs/live_ops/economy_alert_job.rb`, `app/jobs/scheduled_event_job.rb`, `app/jobs/payments/premium_token_sync_job.rb`.
- **Docs:** `doc/features/9_economy.md`, `README.md` (economy section), this flow doc.

