# frozen_string_literal: true

class CreateTileResources < ActiveRecord::Migration[8.1]
  def change
    create_table :tile_resources do |t|
      t.string :zone, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :resource_key, null: false
      t.string :resource_type, null: false, default: "material"
      t.string :biome
      t.integer :quantity, null: false, default: 1
      t.integer :base_quantity, null: false, default: 1
      t.datetime :respawns_at
      t.datetime :last_harvested_at
      t.references :harvested_by, foreign_key: {to_table: :characters}, null: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :tile_resources, [:zone, :x, :y], unique: true
    add_index :tile_resources, :respawns_at
    add_index :tile_resources, :resource_type
    add_index :tile_resources, :biome

    # Add key column to item_templates for resource matching
    unless column_exists?(:item_templates, :key)
      add_column :item_templates, :key, :string
      add_index :item_templates, :key, unique: true
    end

    # Add item_type to distinguish resources from equipment
    unless column_exists?(:item_templates, :item_type)
      add_column :item_templates, :item_type, :string, default: "equipment"
      add_index :item_templates, :item_type
    end
  end
end
