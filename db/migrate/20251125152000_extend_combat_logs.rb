# frozen_string_literal: true

class ExtendCombatLogs < ActiveRecord::Migration[8.1]
  def change
    change_table :combat_log_entries, bulk: true do |t|
      t.bigint :actor_id
      t.string :actor_type
      t.bigint :target_id
      t.string :target_type
      t.references :ability, foreign_key: true
      t.integer :damage_amount, null: false, default: 0
      t.integer :healing_amount, null: false, default: 0
      t.string :tags, array: true, default: []
    end
    add_index :combat_log_entries, :actor_id
    add_index :combat_log_entries, :target_id
    add_index :combat_log_entries, :tags, using: :gin

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
