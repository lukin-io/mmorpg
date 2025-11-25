# frozen_string_literal: true

class CreateQuestAnalyticsSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :quest_analytics_snapshots do |t|
      t.date :captured_on, null: false
      t.string :quest_chain_key, null: false
      t.decimal :completion_rate, precision: 5, scale: 2, null: false, default: 0
      t.decimal :abandon_rate, precision: 5, scale: 2, null: false, default: 0
      t.integer :avg_completion_minutes, null: false, default: 0
      t.integer :bottleneck_step_position
      t.string :bottleneck_step_key
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :quest_analytics_snapshots,
      [:captured_on, :quest_chain_key],
      unique: true,
      name: "index_quest_analytics_snapshots_on_date_and_chain"

    change_table :quest_assignments, bulk: true do |t|
      t.datetime :abandoned_at
      t.string :abandon_reason
    end
  end
end
