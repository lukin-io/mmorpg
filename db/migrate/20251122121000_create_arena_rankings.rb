# frozen_string_literal: true

class CreateArenaRankings < ActiveRecord::Migration[8.1]
  def change
    create_table :arena_rankings do |t|
      t.references :character, null: false, foreign_key: true, index: false
      t.string :ladder_type, null: false, default: "arena"
      t.integer :rating, null: false, default: 1200
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0
      t.integer :streak, null: false, default: 0
      t.jsonb :ladder_metadata, null: false, default: {}
      t.timestamps

      t.index [:character_id, :ladder_type], unique: true
    end
  end
end
