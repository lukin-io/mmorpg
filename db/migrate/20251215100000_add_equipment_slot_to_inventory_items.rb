# frozen_string_literal: true

class AddEquipmentSlotToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :equipment_slot, :string
    add_column :inventory_items, :slot_index, :integer

    add_index :inventory_items, [:inventory_id, :equipped, :equipment_slot],
              name: "idx_inventory_equipped_slot"
  end
end
