# 9. Economy & Trading Systems

## Currency Model
- `CurrencyWallet` now tracks per-currency soft caps (`gold_soft_cap`, `silver_soft_cap`, `premium_tokens_soft_cap`) and sink totals. `Economy::WalletService` handles all adjustments, overflow routing, and `CurrencyTransaction` creation so every quest reward, repair, or sink has a ledger row.
- Sinks:
  - Auction listing fees + progressive taxes use `Economy::ListingFeeCalculator` and `Economy::TaxCalculator`.
  - Repairs/Housing upkeep charge via `Housing::UpkeepService`, while infirmaries consume medical supplies through `Economy::MedicalSupplySink` (called from `Game::Recovery::InfirmaryService`).
  - Premium tokens stay on `users.premium_tokens_balance`, but `Payments::PremiumTokenLedger` now syncs wallets so tokens can be traded just like gold/silver.

## Trading Mechanics
- Auction House supports advanced filters for item type, rarity, and stat thresholds (`Marketplace::ListingFilter`) surfaced in `AuctionListingsController#index`. Listing creation enforces per-account caps (`Economy::ListingCapEnforcer`), charges listing fees, and optionally logs GM overrides via `AuditLogger`.
- Direct Player Trades: the session page uses `Trades::PreviewBuilder` to show an anti-scam summary; contributors add/remove rows via `TradeItemsController`. Dual confirmation triggers `Trades::SettlementService`, moving gold/silver with `Economy::WalletService` and premium tokens via `Payments::PremiumTokenLedger`.
- Marketplace kiosks clamp duration (`MarketplaceKiosk::MAX_DURATION_HOURS`) so city pop-ups feel rapid-fire.

## Crafting & Resource Economy
- `GatheringNode` gained rarity tiers (`rarity_tier` enum) plus a `contested` flag that speeds respawns for PvP hotspots.
- `Economy::DemandTracker` records every crafted item (`MarketDemandSignal` rows) and routes doctor-crafted goods into per-zone `MedicalSupplyPool` stockpiles. Infirmaries then burn those supplies during trauma recovery.

## Premium Items & Monetization
- `Premium::ArtifactStore` redeems premium artifacts (teleports → `Game::Movement::TeleportService`, storage boosters → `Game::Inventory::ExpansionService`, XP boosts → `Players::Progression::ExperiencePipeline`). All redemptions go through the premium token ledger for refunds/adjustments and are auditable via `AuditLogger`.
- Cosmetic purchases (housing decor, mounts, titles) continue to use the ledger; refer to `doc/features/1_auth.md` and `5_moderation.md` for moderation visibility expectations.

## Player-driven Market Controls
- Taxes remain dynamic per clan-owned territory (`Economy::TaxCalculator` + `ClanTerritory`), but we now throttle inflation with:
  - Daily listing caps enforced in `Economy::ListingCapEnforcer`.
  - Progressive listing fees calculated from lot value.
  - GM overrides captured via `AuditLogger` with action `economy.override`.

## Economic Data & Analytics
- `EconomicSnapshot`, `ItemPricePoint`, and `MarketDemandSignal` tables capture price history, demand, trade volume, and currency velocity. `Economy::AnalyticsReporter` + `EconomyAnalyticsJob` persist snapshots while `Economy::FraudDetector` writes `EconomyAlert` rows for moderation follow-up.
- Suspicious trading behavior auto-reports through `Moderation::ReportIntake` (category `:economy`), satisfying the requirement to alert moderators about dupes/gold sellers.

---

## Responsible for Implementation Files
- models:
  - `app/models/currency_wallet.rb`, `app/models/currency_transaction.rb`, `app/models/auction_listing.rb`, `app/models/trade_session.rb`, `app/models/trade_item.rb`, `app/models/marketplace_kiosk.rb`, `app/models/gathering_node.rb`
  - analytics tables: `app/models/market_demand_signal.rb`, `app/models/medical_supply_pool.rb`, `app/models/economic_snapshot.rb`, `app/models/item_price_point.rb`, `app/models/economy_alert.rb`
- services/jobs:
  - `app/services/economy/*.rb` (wallet service, listing fee/cap, demand tracker, medical sink, analytics reporter, fraud detector)
  - trading: `app/services/trades/session_manager.rb`, `app/services/trades/preview_builder.rb`, `app/services/trades/settlement_service.rb`
  - housing upkeep + infirmary: `app/services/housing/upkeep_service.rb`, `app/services/game/recovery/infirmary_service.rb`
  - premium artifacts + teleport: `app/services/premium/artifact_store.rb`, `app/services/game/movement/teleport_service.rb`
  - background job: `app/jobs/economy_analytics_job.rb`
- controllers/views:
  - `app/controllers/auction_listings_controller.rb`, `app/views/auction_listings/index.html.erb`, `app/views/auction_listings/new.html.erb`
  - `app/controllers/trade_sessions_controller.rb`, `app/controllers/trade_items_controller.rb`, `app/views/trade_sessions/show.html.erb`
  - `app/controllers/marketplace_kiosks_controller.rb`, `app/controllers/housing_plots_controller.rb`
- migrations:
  - `db/migrate/20251124140000_add_soft_caps_and_currency_ledgers.rb`
  - `db/migrate/20251124141000_add_trade_and_gathering_economy_fields.rb`
  - `db/migrate/20251124142000_create_economic_analytics_tables.rb`
  - `db/migrate/20251124143000_add_upkeep_to_housing_plots.rb`
- docs/tests:
  - README + this feature file, specs under `spec/services/economy/*`, `spec/services/marketplace/listing_engine_spec.rb`, `spec/services/trades/*`, `spec/services/premium/artifact_store_spec.rb`.
