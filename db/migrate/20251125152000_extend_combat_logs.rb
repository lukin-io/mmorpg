# frozen_string_literal: true

class ExtendCombatLogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :combat_log_entries, :battle_id, true

    change_table :combat_log_entries, bulk: true do |t|
      t.references :arena_match, foreign_key: true
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
      t.integer :healing_amount, null: false, default: 0
      t.string :tags, array: true, default: []
    end
    add_index :combat_log_entries, :actor_id
    add_index :combat_log_entries, :target_id
    add_index :combat_log_entries, :tags, using: :gin
    add_index :combat_log_entries,
      [:arena_match_id, :round_number, :sequence],
      name: "index_combat_logs_on_arena_match_round_sequence"
    add_index :combat_log_entries,
      [:arena_match_id, :log_type],
      name: "index_combat_logs_on_arena_match_and_log_type"

    create_table :combat_analytics_reports do |t|
      t.references :battle, null: false, foreign_key: true
      t.jsonb :payload, null: false, default: {}
      t.datetime :generated_at, null: false
      t.timestamps
    end
    add_index :combat_analytics_reports, :generated_at

    add_column :battles, :share_token, :string
    add_index :battles, :share_token, unique: true
  end
end
