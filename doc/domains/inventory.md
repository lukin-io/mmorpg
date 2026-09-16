# Inventory and Equipment Domain

## Scope

The paper doll, equipment slots, carried items, item families, requirements,
durability, mass, item actions, successful-loot feedback boundary, and handoffs
to Character, Combat, Social, and Shop.

## Documentation chain

- [Required working context and update rules](../DOCUMENTATION.md#21-required-context-and-update-map)
- General item catalog, artwork and editing: [ITEMS](../ITEMS.md)
- Complete scroll catalog, activation, permissions and editing: [SCROLLS](../SCROLLS.md);
  shared fight consumer: [COMBAT](../COMBAT.md)
- Calculations and image standards: [FORMULAS](../FORMULAS.md), [ARTWORK](../ARTWORK.md)
- Neverlands source summary: [doc/design/reference/inventory/README.md](../design/reference/inventory/README.md)
- Current observations: [doc/design/reference/inventory/observations/](../design/reference/inventory/observations)
- Cross-domain successful-loot feedback observation:
  [doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md](../design/reference/social/observations/2026-08-23_chat_game_event_timeline.md)
- Normalized design: [doc/design/features/items_inventory_equipment.md](../design/features/items_inventory_equipment.md)
- Delivery IDs: `INVENTORY-UI-001` and `INVENTORY-ACTIONS-001` in
  [doc/design/launch_mvp_plan.md](../design/launch_mvp_plan.md)
- Current implementation: `doc/features/player_inventory.md` ([handbook](../features/player_inventory.md))

## Current RPG status

Fully Implemented for the declared current equipment/item boundary. Empty or
uncaptured production families, remaining targeted use, repair, and some
fight-slot behaviors remain outside it. A personal item-found event is emitted
by Combat only after Inventory reports a successful NPC-loot award; it is not
item ownership state. Multi-unit additions are atomic under one Inventory lock
and savepoint, including when a Combat caller records a capacity failure.
Combat owns the exact result-based durability roll and Careful Fighter's
half-chance modifier. Repair remains an unimplemented workshop/profession
transaction, not a direct Inventory reset.

[Attack scrolls](../design/features/scrolls.md) connect Inventory ownership,
[FORMULAS entry rules](../FORMULAS.md#scroll-01--attack-entry) and the existing
Combat processor. The first two variants have source forms/requirements and
local runtime; two live 17-to-5 attempts rejected without consumption.
[September 15](../design/reference/inventory/observations/2026-09-15_successful_attack_scroll.md)
adds successful Permit entry/charge/attacker aftermath. The later
[Fist capture](../design/reference/inventory/observations/2026-09-15_successful_fist_attack.md)
confirms gear removal, one charge, loss XP and Inventory return with gear
still unequipped; defender public recovery is captured separately from their controls. [ITEMS](../ITEMS.md#attack-scroll-use)
owns catalog editing and personal-use restrictions.

## Important responsible implementation files

- `app/models/item_template.rb`
- `app/models/inventory_item.rb`
- `app/controllers/inventories_controller.rb`
- `app/services/game/inventory/manager.rb`
- `app/assets/stylesheets/inventory.css`

Section 16 of `doc/features/player_inventory.md` is exhaustive.

## Evidence and implementation gaps

Each uncaptured item family and mutating action needs its own observable flow,
failure states, responsive acceptance, and server-authoritative contract. The
repair flow specifically still needs authenticated request, payment/material,
failure, completion, and owner-retrieval evidence.
