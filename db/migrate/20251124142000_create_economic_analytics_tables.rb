class CreateEconomicAnalyticsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :market_demand_signals do |t|
      t.string :source, null: false
      t.string :item_name, null: false
      t.integer :quantity, null: false, default: 0
      t.references :profession, foreign_key: true
      t.references :zone, foreign_key: true
      t.jsonb :metadata, null: false, default: {}
      t.datetime :recorded_at, null: false
      t.timestamps
    end
    add_index :market_demand_signals, :recorded_at
    add_index :market_demand_signals, :item_name

    create_table :medical_supply_pools do |t|
      t.references :zone, null: false, foreign_key: true
      t.string :item_name, null: false
      t.integer :available_quantity, null: false, default: 0
      t.datetime :last_restocked_at
      t.timestamps
    end
    add_index :medical_supply_pools, [:zone_id, :item_name], unique: true, name: "index_medical_supply_pools_on_zone_and_item"

    create_table :economic_snapshots do |t|
      t.date :captured_on, null: false
      t.integer :active_listings, null: false, default: 0
      t.integer :daily_trade_volume_gold, null: false, default: 0
      t.integer :daily_trade_volume_premium_tokens, null: false, default: 0
      t.decimal :currency_velocity_gold, precision: 10, scale: 2, null: false, default: 0
      t.decimal :currency_velocity_silver, precision: 10, scale: 2, null: false, default: 0
      t.decimal :currency_velocity_premium_tokens, precision: 10, scale: 2, null: false, default: 0
      t.integer :suspicious_trade_count, null: false, default: 0
      t.jsonb :item_price_index, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :economic_snapshots, :captured_on, unique: true

    create_table :item_price_points do |t|
      t.date :sampled_on, null: false
      t.string :item_name, null: false
      t.string :currency_type, null: false
      t.integer :average_price, null: false, default: 0
      t.integer :median_price, null: false, default: 0
      t.integer :volume, null: false, default: 0
      t.timestamps
    end
    add_index :item_price_points, [:item_name, :sampled_on, :currency_type], name: "index_item_price_points_on_item_and_sample"

    create_table :economy_alerts do |t|
      t.string :alert_type, null: false
      t.string :status, null: false, default: "open"
      t.references :trade_session, foreign_key: true
      t.jsonb :payload, null: false, default: {}
      t.datetime :flagged_at, null: false
      t.timestamps
    end
    add_index :economy_alerts, :status
  end
end
