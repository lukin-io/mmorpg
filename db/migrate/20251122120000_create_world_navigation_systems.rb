# frozen_string_literal: true

class CreateWorldNavigationSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :zones do |t|
      t.string :name, null: false
      t.string :biome, null: false
      t.integer :width, null: false, default: 32
      t.integer :height, null: false, default: 32
      t.integer :turn_counter, null: false, default: 1
      t.jsonb :encounter_table, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :zones, :name, unique: true

    create_table :spawn_points do |t|
      t.references :zone, null: false, foreign_key: true
      t.integer :x, null: false
      t.integer :y, null: false
      t.string :faction_key, null: false
      t.string :city_key
      t.integer :respawn_seconds, null: false, default: 60
      t.boolean :default_entry, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :spawn_points, [:zone_id, :faction_key]

    create_table :character_positions do |t|
      t.references :character, null: false, foreign_key: true, index: {unique: true}
      t.references :zone, null: false, foreign_key: true
      t.integer :x, null: false
      t.integer :y, null: false
      t.integer :state, null: false, default: 0
      t.integer :last_turn_number, null: false, default: 0
      t.datetime :last_action_at
      t.datetime :respawn_available_at
      t.timestamps
    end
    add_index :character_positions, [:zone_id, :x, :y]

    add_column :map_tile_templates, :biome, :string, null: false, default: "plains"
  end
end
