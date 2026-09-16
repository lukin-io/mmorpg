# Neverlands Inventory, Items, and Equipment Source Summary

For the design, delivery status and current implementation using this evidence,
follow the [Inventory domain](../../../domains/inventory.md).

- Document type: neverlands-source-summary
- Domain: inventory
- Updated: 2026-09-15
- Evidence status: current for the bounded launch surface

## Current observations

- [September16 artwork categories](observations/2026-09-16_artwork_categories.md):
  shared Shop/Inventory category dimensions, image versus cell backgrounds,
  license framing and original-art adoption boundaries.

- [September 15 successful Permit attack](observations/2026-09-15_successful_attack_scroll.md):
  lake 17→19, retained gear, low-HP entry, committed lethal exchange, one charge,
  570 XP and independent Finish.
- [September 15 successful Fist attack](observations/2026-09-15_successful_fist_attack.md):
  cemetery17→17, gear stripping,21 exchanges over about13 minutes, both
  contributors in statistics,93/9835 XP, one charge, attacker Inventory return
  with gear still removed and eventual defender public recovery.

- Shop purchase and resulting carried penknife in
  `doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md`
- `doc/design/reference/inventory/observations/2026-06-01_inventory_items_and_shop_rows.md`
- Inventory sections in
  `doc/design/reference/character/observations/2026-05-11_player_profile_and_development.md`
- Wear, Careful Fighter, and repair wiki audit in
  `doc/design/reference/character/observations/legacy_skills_and_arena_analysis.md`
- Character-sheet/item-row measurements in
  `doc/design/reference/shell/observations/2026-07-29_style_system.md`
- Successful bot-search item-found feedback, adjacent to a separate NV variant, in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`

## Current Neverlands behavior

The September 9 Shop purchase added one carried penknife with 10/10 durability,
mass 5 and its observed property/requirement row. The Shop and Inventory money
and mass displays matched; Return restored the same Shop. This confirms the
visible acquisition handoff without claiming access to source persistence.

Inventory combines a paper doll, item families/subcategories, dense item rows,
requirements, properties, durability, carried mass, and server-issued item
actions. Shop rows reuse the item vocabulary but Shop owns commerce. A supplied
chat capture also confirms concise successful item-found feedback, but it does
not establish failed-capacity behavior or make that row inventory authority.
The NV variant is Economy-owned and does not create an inventory item.
Careful Fighter halves the exact per-result item-wear chance. Repair is a
workshop/profession listing and retrieval flow rather than an Inventory reset.

## Evidence gaps

- The [September 14 attack-scroll capture](observations/2026-09-14_attack_scrolls.md)
  records Duel Permit I/Fist Attack rows, requirements and target forms plus
  wiki rules. Later Permit I and Fist Execute attempts from level 17 against
  co-located zMey [5] both returned a generic failure without consumption or
  equipment changes. This is compatible with the wiki's ±3 window, not a
  successful fight or proof of the rejection cause. Other targeted items, source transfer
  edge cases, production, fight-slot interactions and authenticated repair
  retain their own evidence gaps. [Scroll design](../../features/scrolls.md)
  distinguishes local admission behavior from those source observations.

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
