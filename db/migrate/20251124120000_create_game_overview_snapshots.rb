# frozen_string_literal: true

class CreateGameOverviewSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :game_overview_snapshots do |t|
      t.datetime :captured_at, null: false
      t.integer :daily_returning_players, null: false, default: 0
      t.integer :weekly_returning_players, null: false, default: 0
      t.integer :chat_senders_7d, null: false, default: 0
      t.integer :active_guilds_7d, null: false, default: 0
      t.integer :active_clans_7d, null: false, default: 0
      t.integer :seasonal_events_active, null: false, default: 0
      t.integer :premium_purchases_30d, null: false, default: 0
      t.decimal :avg_tokens_per_paying_user, null: false, default: 0, precision: 10, scale: 2
      t.decimal :whale_share_percent, null: false, default: 0, precision: 5, scale: 2
      t.timestamps
    end

    add_index :game_overview_snapshots, :captured_at, unique: true
  end
end
