# frozen_string_literal: true

class CreateInventoriesAndProfessionExtensions < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :character, null: false, foreign_key: true
      t.integer :slot_capacity, null: false, default: 30
      t.integer :weight_capacity, null: false, default: 100
      t.integer :current_weight, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.jsonb :currency_storage, null: false, default: {}
      t.timestamps
    end
    add_index :inventories, :character_id, unique: true

    create_table :inventory_items do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :item_template, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.string :slot_kind
      t.boolean :equipped, null: false, default: false
      t.integer :weight, null: false, default: 0
      t.integer :enhancement_level, null: false, default: 0
      t.boolean :premium, null: false, default: false
      t.boolean :bound, null: false, default: false
      t.jsonb :properties, null: false, default: {}
      t.datetime :last_enhanced_at
      t.timestamps
    end
    add_index :inventory_items, [:inventory_id, :slot_kind]

    add_column :item_templates, :weight, :integer, null: false, default: 1
    add_column :item_templates, :stack_limit, :integer, null: false, default: 99
    add_column :item_templates, :premium, :boolean, null: false, default: false
    add_column :item_templates, :enhancement_rules, :jsonb, null: false, default: {}

    add_column :professions, :healing_bonus, :integer, null: false, default: 0
    add_column :professions, :gathering_resource, :string
    add_column :professions, :metadata, :jsonb, null: false, default: {}

    create_table :gathering_nodes do |t|
      t.references :profession, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.string :resource_key, null: false
      t.integer :difficulty, null: false, default: 1
      t.integer :respawn_seconds, null: false, default: 60
      t.jsonb :rewards, null: false, default: {}
      t.timestamps
    end
    add_index :gathering_nodes, [:profession_id, :resource_key]
  end
end
