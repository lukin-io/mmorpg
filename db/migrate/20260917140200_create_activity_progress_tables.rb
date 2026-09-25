# frozen_string_literal: true

# Character progress for Ashen Veil achievements / daily activity contracts.
class CreateActivityProgressTables < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_achievements do |t|
      t.references :character, null: false, foreign_key: true
      t.string :achievement_key, null: false
      t.integer :progress, null: false, default: 0
      t.integer :required, null: false, default: 1
      t.datetime :completed_at
      t.datetime :claimed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :activity_achievements, [:character_id, :achievement_key], unique: true, name: "idx_activity_achievements_char_key"

    create_table :daily_activity_contracts do |t|
      t.references :character, null: false, foreign_key: true
      t.string :day_key, null: false
      t.string :contract_key, null: false
      t.string :kind, null: false
      t.integer :target, null: false, default: 1
      t.integer :progress, null: false, default: 0
      t.datetime :completed_at
      t.datetime :claimed_at
      t.jsonb :reward, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :daily_activity_contracts, [:character_id, :day_key, :contract_key], unique: true, name: "idx_daily_contracts_char_day_key"
  end
end
