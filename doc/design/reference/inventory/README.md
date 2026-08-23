# Neverlands Inventory, Items, and Equipment Source Summary

- Document type: neverlands-source-summary
- Domain: inventory
- Updated: 2026-08-23
- Evidence status: current for the bounded launch surface

## Current observations

- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- Inventory sections in
  `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md`
- Character-sheet/item-row measurements in
  `doc/design/reference/shell/observations/2026-07-29_style_system.md`
- Successful bot-search item-found feedback, adjacent to a separate NV variant, in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`

## Current Neverlands behavior

Inventory combines a paper doll, item families/subcategories, dense item rows,
requirements, properties, durability, carried mass, and server-issued item
actions. Shop rows reuse the item vocabulary but Shop owns commerce. A supplied
chat capture also confirms concise successful item-found feedback, but it does
not establish failed-capacity behavior or make that row inventory authority.
The NV variant is Economy-owned and does not create an inventory item.

## Evidence gaps

- Player transfer, targeted item use, crafting/production families, and some
  fight-slot interactions remain outside the completed local boundary.

## Design linkage

- `doc/design/features/items_inventory_equipment.md`

## Local Implementation Linkage

- Local status: Fully Implemented for the bounded Inventory handbook
- Implementation handbook: `doc/features/player_inventory.md`

### Responsible implementation files

- `app/models/item_template.rb`
- `app/models/inventory_item.rb`
- `app/services/game/inventory/manager.rb`
- `app/assets/stylesheets/inventory.css`

Local implementation linkage is context, not Neverlands evidence.
