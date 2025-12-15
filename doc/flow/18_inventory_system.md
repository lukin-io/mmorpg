# Inventory System - Flow Documentation

## Version History
- **v1.0** (2024-12-15): Initial implementation with full CRUD, equipment management, enhancement system

## Overview

The inventory system provides Neverlands-inspired item management with:
- Grid-based inventory display with slot limits
- Item stacking for consumables/materials
- Equipment slots (weapon, armor, accessories)
- Item enhancement/upgrade system
- Inventory expansion via premium currency
- Weight-based capacity limits
- Drag-and-drop item management (via Stimulus)

## GDD Reference
- Feature spec: `doc/ITEM_SYSTEM_GUIDE.md`

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| **Inventory model** | ✅ Implemented | `app/models/inventory.rb` — slot/weight limits, item management |
| **InventoryItem model** | ✅ Implemented | `app/models/inventory_item.rb` — stack counts, equipment state, enhancement |
| **ItemTemplate model** | ✅ Implemented | `app/models/item_template.rb` — base attributes, equipment slots, stat modifiers |
| **Manager service** | ✅ Implemented | `app/services/game/inventory/manager.rb` — add/remove items, stacking |
| **EquipmentService** | ✅ Implemented | `app/services/game/inventory/equipment_service.rb` — equip/unequip logic |
| **EnhancementService** | ✅ Implemented | `app/services/game/inventory/enhancement_service.rb` — upgrade items |
| **ExpansionService** | ✅ Implemented | `app/services/game/inventory/expansion_service.rb` — increase slot capacity |
| **InventoriesController** | ✅ Implemented | `app/controllers/inventories_controller.rb` — show, equip, unequip, sort |
| **Views** | ✅ Implemented | Grid display, equipment slots, stats panel |
| **Stimulus controller** | ✅ Implemented | `app/javascript/controllers/inventory_controller.js` — client interactions |

---

## Use Cases

### UC-1: View Inventory
**Actor:** Player viewing their inventory
**Flow:**
1. Navigate to `/inventory`
2. `InventoriesController#show` loads character's inventory with items
3. Renders `inventories/show.html.erb` with:
   - Equipment slots panel (`_equipment.html.erb`)
   - Grid of inventory items (`_grid.html.erb`)
   - Character stats summary (`_stats.html.erb`)
   - Currency display (gold balance)

### UC-2: Equip Item
**Actor:** Player equipping an item from inventory
**Flow:**
1. Click equip button on inventory item
2. `POST /inventory/equip` with `item_id` and `slot`
3. `EquipmentService.equip!` validates:
   - Item is equippable (`item_template.equippable?`)
   - Slot matches item type
   - Character meets requirements
4. Updates `inventory_item.equipment_slot` and `inventory_item.slot_index`
5. Turbo Stream updates:
   - Equipment panel (`inventories/equipment`)
   - Inventory grid (`inventories/grid`)
   - Stats panel (`inventories/stats`)

### UC-3: Unequip Item
**Actor:** Player removing equipped item
**Flow:**
1. Click unequip button on equipment slot
2. `POST /inventory/unequip` with `slot`
3. `EquipmentService.unequip!` clears equipment state
4. Item returns to inventory grid
5. Turbo Stream updates affected panels

### UC-4: Add Item to Inventory
**Actor:** System (loot, quest reward, purchase)
**Flow:**
1. `Inventory#add_item_by_name!` or `Game::Inventory::Manager.add_item!`
2. Manager checks slot/weight capacity
3. If stackable, finds existing stack or creates new
4. Updates `inventory_item.quantity`
5. Returns success/failure result

### UC-5: Enhance Item
**Actor:** Player upgrading equipment
**Flow:**
1. Select item and enhancement materials
2. `POST /inventory/enhance` with `item_id` and `material_ids`
3. `EnhancementService.enhance!` validates:
   - Item is enhanceable
   - Materials are correct type/quantity
4. Consumes materials, increases `enhancement_level`
5. Stat modifiers scale with enhancement level

---

## Key Models

### Inventory
```ruby
class Inventory < ApplicationRecord
  belongs_to :character
  has_many :inventory_items, dependent: :destroy

  # Capacity limits
  def max_slots     # alias for slot_capacity
  def max_weight    # alias for weight_limit
  def current_weight
  def slots_used
  def has_space_for?(item_template, quantity = 1)

  # Item management
  def add_item_by_name!(name, quantity: 1)
  def remove_item!(item, quantity: 1)
end
```

### InventoryItem
```ruby
class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item_template

  # Stack management
  attribute :quantity, :integer, default: 1

  # Equipment state
  attribute :equipment_slot, :string
  attribute :slot_index, :integer

  # Enhancement
  attribute :enhancement_level, :integer, default: 0
  attribute :enhancement_metadata, :jsonb, default: {}

  def equipped?
  def stackable?
  def max_stack
end
```

### ItemTemplate
```ruby
class ItemTemplate < ApplicationRecord
  EQUIPMENT_SLOTS = %w[main_hand off_hand head chest legs feet ring amulet].freeze

  attribute :slot, :string
  attribute :item_type, :string  # equipment, consumable, material, quest
  attribute :stat_modifiers, :jsonb, default: {}
  attribute :stack_limit, :integer, default: 1
  attribute :weight, :decimal, default: 0.0

  def equippable?
  def equipment_slot
end
```

---

## Services

### Game::Inventory::Manager
Handles item addition/removal with slot/weight validation:
```ruby
class Game::Inventory::Manager
  def self.add_item!(inventory, item_template, quantity: 1)
  def self.remove_item!(inventory, item, quantity: 1)
  def self.sort_inventory!(inventory)

  private
  def self.find_or_build_stack(inventory, item_template, quantity)
end
```

### Game::Inventory::EquipmentService
Handles equip/unequip operations:
```ruby
class Game::Inventory::EquipmentService
  def initialize(character)
  def equip!(item, slot:)
  def unequip!(slot:)
  def equipped_in_slot(slot)
end
```

### Game::Inventory::EnhancementService
Handles item upgrades:
```ruby
class Game::Inventory::EnhancementService
  def initialize(character)
  def enhance!(item, materials:)
  def enhancement_cost(item)
  def success_chance(item)
end
```

---

## Controller Actions

### InventoriesController
```ruby
class InventoriesController < ApplicationController
  def show          # GET /inventory
  def equip         # POST /inventory/equip
  def unequip       # POST /inventory/unequip
  def sort          # POST /inventory/sort
  def destroy_item  # DELETE /inventory/items/:id
end
```

### Turbo Stream Responses
```ruby
# equip/unequip actions
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace("inventories-equipment", partial: "inventories/equipment", locals: { inventory: @inventory }),
      turbo_stream.replace("inventories-grid", partial: "inventories/grid", locals: { inventory: @inventory }),
      turbo_stream.replace("inventories-stats", partial: "inventories/stats", locals: { character: @character })
    ]
  end
end
```

---

## Views

### show.html.erb
Main inventory page with three panels:
- Equipment slots (left)
- Inventory grid (center)
- Stats summary (right)

### _grid.html.erb
Grid of inventory slots displaying:
- Item icon
- Stack quantity (if > 1)
- Enhancement level badge
- Tooltip with stats

### _equipment.html.erb
Equipment slot panel with:
- Slot icons (weapon, armor, accessories)
- Equipped item display
- Empty slot indicators

### _stats.html.erb
Character stats affected by equipment:
- Base stats + equipment bonuses
- Total values displayed

---

## Stimulus Controller

### inventory_controller.js
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "equipment", "stats", "tooltip"]

  // Drag and drop
  dragStart(event)
  dragOver(event)
  drop(event)

  // Item interactions
  showTooltip(event)
  hideTooltip(event)
  useItem(event)
  splitStack(event)
}
```

---

## Testing

### Model Specs
- `spec/models/inventory_spec.rb` — capacity limits, add/remove items
- `spec/models/inventory_item_spec.rb` — associations, validations, equipment state

### Service Specs
- `spec/services/game/inventory/manager_spec.rb` — add/remove/stack logic
- `spec/services/game/inventory/equipment_service_spec.rb` — equip/unequip
- `spec/services/game/inventory/enhancement_service_spec.rb` — upgrade logic
- `spec/services/game/inventory/expansion_service_spec.rb` — slot expansion

### Request Specs
- `spec/requests/inventories_spec.rb` — controller actions, Turbo Stream responses

---

## Responsible for Implementation Files

### Models
- `app/models/inventory.rb`
- `app/models/inventory_item.rb`
- `app/models/item_template.rb`

### Controllers
- `app/controllers/inventories_controller.rb`
- `app/controllers/inventory_items_controller.rb`

### Services
- `app/services/game/inventory/manager.rb`
- `app/services/game/inventory/equipment_service.rb`
- `app/services/game/inventory/enhancement_service.rb`
- `app/services/game/inventory/expansion_service.rb`

### Views
- `app/views/inventories/show.html.erb`
- `app/views/inventories/_grid.html.erb`
- `app/views/inventories/_equipment.html.erb`
- `app/views/inventories/_equipment_slot.html.erb`
- `app/views/inventories/_stats.html.erb`

### JavaScript
- `app/javascript/controllers/inventory_controller.js`

### Specs
- `spec/models/inventory_spec.rb`
- `spec/models/inventory_item_spec.rb`
- `spec/models/item_template_spec.rb`
- `spec/services/game/inventory/manager_spec.rb`
- `spec/services/game/inventory/equipment_service_spec.rb`
- `spec/services/game/inventory/enhancement_service_spec.rb`
- `spec/services/game/inventory/expansion_service_spec.rb`
- `spec/requests/inventories_spec.rb`
- `spec/factories/inventories.rb`
- `spec/factories/inventory_items.rb`
- `spec/factories/item_templates.rb`

