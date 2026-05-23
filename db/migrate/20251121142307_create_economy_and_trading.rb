class CreateEconomyAndTrading < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_wallets do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.integer :nv_balance, null: false, default: 0
      t.timestamps
    end

    create_table :currency_transactions do |t|
      t.references :currency_wallet, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :reason, null: false
      t.integer :balance_after, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :currency_transactions, :created_at
  end
end
