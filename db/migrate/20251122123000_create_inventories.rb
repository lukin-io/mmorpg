# frozen_string_literal: true

class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :character, null: false, foreign_key: true, index: {unique: true}
      t.integer :slot_capacity, null: false, default: 30
      t.integer :weight_capacity, null: false, default: 100
      t.integer :current_weight, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.jsonb :currency_storage, null: false, default: {}
      t.timestamps
    end

    create_table :inventory_items do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :item_template, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.string :slot_kind
      t.string :equipment_slot
      t.integer :slot_index
      t.boolean :equipped, null: false, default: false
      t.integer :weight, null: false, default: 0
      t.integer :enhancement_level, null: false, default: 0
      t.boolean :bound, null: false, default: false
      t.jsonb :properties, null: false, default: {}
      t.datetime :last_enhanced_at
      t.timestamps
    end
    add_index :inventory_items, [:inventory_id, :slot_kind]
    add_index :inventory_items, [:inventory_id, :equipped, :equipment_slot],
      name: "idx_inventory_equipped_slot"
  end
end
