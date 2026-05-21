class CreateEconomyAndTrading < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_wallets do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.integer :gold_balance, null: false, default: 0
      t.integer :silver_balance, null: false, default: 0
      t.integer :gold_soft_cap, null: false, default: 2_000_000
      t.integer :silver_soft_cap, null: false, default: 150_000
      t.jsonb :sink_totals, null: false, default: {}
      t.timestamps
    end

    create_table :currency_transactions do |t|
      t.references :currency_wallet, null: false, foreign_key: true
      t.string :currency_type, null: false
      t.integer :amount, null: false
      t.string :reason, null: false
      t.integer :balance_after, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :currency_transactions, :created_at
    add_index :currency_transactions, [:currency_type, :created_at], name: "index_currency_transactions_on_type_and_created_at"
  end
end
