# frozen_string_literal: true

class CreateTacticalCombatLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :tactical_combat_log_entries do |t|
      t.references :tactical_match, null: false, foreign_key: true
      t.integer :round_number, null: false, default: 1
      t.integer :sequence, null: false, default: 1
      t.string :log_type, null: false, default: "action"
      t.text :message, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    add_index :tactical_combat_log_entries, [:tactical_match_id, :round_number]
  end
end
