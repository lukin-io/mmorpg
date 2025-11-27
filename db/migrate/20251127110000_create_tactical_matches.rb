# frozen_string_literal: true

class CreateTacticalMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :tactical_matches do |t|
      t.references :creator, null: false, foreign_key: {to_table: :characters}
      t.references :opponent, foreign_key: {to_table: :characters}
      t.references :winner, foreign_key: {to_table: :characters}
      t.references :arena_room, foreign_key: true

      t.integer :status, default: 0, null: false
      t.integer :grid_size, default: 8, null: false
      t.integer :turn_time_limit, default: 60, null: false
      t.integer :turn_number, default: 1
      t.integer :actions_remaining, default: 3
      t.bigint :current_turn_character_id

      t.jsonb :grid_state, default: {}
      t.string :instance_key

      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :turn_started_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :tactical_matches, :instance_key, unique: true
    add_index :tactical_matches, :status
  end
end
