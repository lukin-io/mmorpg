# frozen_string_literal: true

class CreateTacticalParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :tactical_participants do |t|
      t.references :tactical_match, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true

      t.integer :grid_x, default: 0, null: false
      t.integer :grid_y, default: 0, null: false
      t.integer :current_hp, null: false
      t.integer :current_mp, default: 0
      t.integer :movement_range, default: 3
      t.integer :attack_range, default: 1
      t.boolean :alive, default: true, null: false

      t.jsonb :buffs, default: {}
      t.jsonb :buff_durations, default: {}

      t.timestamps
    end

    add_index :tactical_participants, [:tactical_match_id, :character_id], unique: true
    add_index :tactical_participants, [:tactical_match_id, :alive]
  end
end
