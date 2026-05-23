# frozen_string_literal: true

class ExtendCombatLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :combat_log_entries do |t|
      t.references :arena_match, null: false, foreign_key: true
      t.integer :round_number, null: false, default: 1
      t.integer :sequence, null: false, default: 1
      t.string :log_type, null: false, default: "action"
      t.text :message, null: false
      t.jsonb :payload, null: false, default: {}
      t.bigint :actor_id
      t.string :actor_type
      t.bigint :target_id
      t.string :target_type
      t.datetime :occurred_at
      t.string :action_key
      t.string :body_part
      t.string :outcome
      t.string :actor_team
      t.string :target_team
      t.integer :damage_amount, null: false, default: 0
      t.string :tags, array: true, default: []
      t.timestamps
    end
    add_index :combat_log_entries, :actor_id
    add_index :combat_log_entries, :target_id
    add_index :combat_log_entries, :tags, using: :gin
    add_index :combat_log_entries, :log_type
    add_index :combat_log_entries,
      [:arena_match_id, :round_number, :sequence],
      name: "index_combat_logs_on_arena_match_round_sequence"
    add_index :combat_log_entries,
      [:arena_match_id, :log_type],
      name: "index_combat_logs_on_arena_match_and_log_type"
  end
end
