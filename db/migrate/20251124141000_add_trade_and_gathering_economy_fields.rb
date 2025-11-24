class AddTradeAndGatheringEconomyFields < ActiveRecord::Migration[8.1]
  def change
    change_table :trade_sessions, bulk: true do |t|
      t.datetime :completed_at
    end

    change_table :trade_items, bulk: true do |t|
      t.string :item_quality
    end

    change_table :gathering_nodes, bulk: true do |t|
      t.string :rarity_tier, null: false, default: "common"
      t.boolean :contested, null: false, default: false
    end
  end
end
