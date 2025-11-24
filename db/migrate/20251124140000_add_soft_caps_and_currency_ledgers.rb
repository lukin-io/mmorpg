class AddSoftCapsAndCurrencyLedgers < ActiveRecord::Migration[8.1]
  def change
    change_table :currency_wallets, bulk: true do |t|
      t.integer :gold_soft_cap, null: false, default: 2_000_000
      t.integer :silver_soft_cap, null: false, default: 150_000
      t.integer :premium_tokens_soft_cap, null: false, default: 5_000
      t.jsonb :sink_totals, null: false, default: {}
    end

    add_column :currency_transactions, :balance_after, :integer, null: false, default: 0
    add_index :currency_transactions, :created_at
    add_index :currency_transactions, [:currency_type, :created_at], name: "index_currency_transactions_on_type_and_created_at"
  end
end
