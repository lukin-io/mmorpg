# frozen_string_literal: true

class CreateDungeonTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :dungeon_templates do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.text :description
      t.integer :min_level, default: 1, null: false
      t.integer :max_level, default: 100, null: false
      t.integer :min_party_size, default: 1, null: false
      t.integer :max_party_size, default: 5, null: false
      t.integer :duration_minutes, default: 120, null: false
      t.string :biome
      t.jsonb :encounters, null: false, default: []
      t.jsonb :rewards, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :dungeon_templates, :key, unique: true
    add_index :dungeon_templates, [:min_level, :max_level]
  end
end
