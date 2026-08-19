# Inventory and Equipment Domain

## Scope

The paper doll, equipment slots, carried items, item families, requirements,
durability, mass, item actions, and handoffs to Character, Combat, and Shop.

## Documentation chain

- Neverlands source summary: `doc/design/reference/inventory/README.md`
- Current observations: `doc/design/reference/inventory/observations/`
- Normalized design: `doc/design/features/items_inventory_equipment.md`
- Delivery IDs: `INVENTORY-UI-001` and `INVENTORY-ACTIONS-001` in
  `doc/design/launch_mvp_plan.md`
- Current implementation: `doc/features/player_inventory.md`

## Current RPG status

Fully Implemented for the declared current equipment/item boundary. Empty or
uncaptured production families, transfers, targeted use, repair, and some
fight-slot behaviors remain outside it.

## Important responsible implementation files

- `app/models/item_template.rb`
- `app/models/inventory_item.rb`
- `app/controllers/inventories_controller.rb`
- `app/services/game/inventory/manager.rb`
- `app/assets/stylesheets/inventory.css`

Section 16 of `doc/features/player_inventory.md` is exhaustive.

## Evidence and implementation gaps

Each uncaptured item family and mutating action needs its own observable flow,
failure states, responsive acceptance, and server-authoritative contract.
