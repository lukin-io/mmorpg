# frozen_string_literal: true

class CreateTileNpcs < ActiveRecord::Migration[8.1]
  def change
    create_table :tile_npcs do |t|
      t.string :zone, null: false
      t.integer :x, null: false
      t.integer :y, null: false
      t.references :npc_template, null: false, foreign_key: true
      t.string :biome
      t.string :npc_key, null: false
      t.string :npc_role, null: false, default: "hostile"
      t.integer :current_hp
      t.integer :max_hp
      t.integer :level, null: false, default: 1
      t.datetime :defeated_at
      t.datetime :respawns_at
      t.references :defeated_by, foreign_key: {to_table: :characters}, null: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :tile_npcs, [:zone, :x, :y], unique: true
    add_index :tile_npcs, :respawns_at
    add_index :tile_npcs, :npc_role
    add_index :tile_npcs, :biome
  end
end
