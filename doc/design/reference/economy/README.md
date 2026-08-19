# Neverlands Economy and Shop Source Summary

- Document type: neverlands-source-summary
- Domain: economy
- Updated: 2026-07-29
- Evidence status: current for captured Shop rows; incomplete overall

## Current observations

- `doc/design/reference/economy/observations/2026-05-21_lavka_shop.md`
- Shop rows and item actions in
  `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- Service-building evidence in
  `doc/design/reference/city/observations/2026-07-28_city_movement_and_services.md`

## Current Neverlands behavior

The captured Lavka is a City building with mode tabs, category/filter controls,
dense buy/sell rows, requirements, prices, stock, player funds, and City return.

## Evidence gaps

- Full market trading, player transfers, license effects, repair, stock
  replenishment, and several service-building transaction flows remain open.

## Design linkage

- `doc/design/features/economy_trading_shops.md`

## Local Implementation Linkage

- Local status: Partially Implemented
- Implementation handbook: `doc/features/shop_economy.md`

### Responsible implementation files

- `app/controllers/shop_controller.rb`
- `app/services/game/shop/catalog.rb`
- `app/services/game/shop/purchase.rb`
- `app/assets/stylesheets/shop.css`

Local implementation linkage is context, not Neverlands evidence.
