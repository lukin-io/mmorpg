# frozen_string_literal: true

class CreateCityHotspots < ActiveRecord::Migration[8.0]
  def change
    create_table :city_hotspots do |t|
      t.references :zone, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :hotspot_type, null: false, default: "building"
      t.integer :position_x, null: false
      t.integer :position_y, null: false
      t.string :image_normal
      t.string :image_hover
      t.string :action_type, null: false, default: "open_feature"
      t.references :destination_zone, foreign_key: {to_table: :zones}
      t.jsonb :action_params, default: {}
      t.integer :required_level, default: 1
      t.boolean :active, default: true
      t.integer :z_index, default: 0

      t.timestamps
    end

    add_index :city_hotspots, [:zone_id, :key], unique: true
    add_index :city_hotspots, :hotspot_type
    add_index :city_hotspots, :active
  end
end
