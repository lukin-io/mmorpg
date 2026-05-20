class CreateMarketDemandAndMedicalSupply < ActiveRecord::Migration[8.1]
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

  end
end
