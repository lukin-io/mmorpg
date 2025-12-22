# frozen_string_literal: true

class CreateTileBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :tile_buildings do |t|
      t.string :zone, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :building_key, null: false
      t.string :building_type, null: false, default: "castle"
      t.string :name, null: false
      t.references :destination_zone, null: true, foreign_key: {to_table: :zones}
      t.integer :destination_x
      t.integer :destination_y
      t.string :icon, default: "🏰"
      t.integer :required_level, default: 1, null: false
      t.string :faction_key
      t.jsonb :metadata, default: {}, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :tile_buildings, [:zone, :x, :y], unique: true
    add_index :tile_buildings, :building_type
    add_index :tile_buildings, :building_key, unique: true
    add_index :tile_buildings, :active
  end
end
