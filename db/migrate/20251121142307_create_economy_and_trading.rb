class CreateEconomyAndTrading < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_wallets do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.integer :gold_balance, null: false, default: 0
      t.integer :silver_balance, null: false, default: 0
      t.integer :premium_tokens_balance, null: false, default: 0
      t.integer :gold_soft_cap, null: false, default: 2_000_000
      t.integer :silver_soft_cap, null: false, default: 150_000
      t.integer :premium_tokens_soft_cap, null: false, default: 5_000
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

    create_table :trade_sessions do |t|
      t.references :initiator, null: false, foreign_key: {to_table: :users}
      t.references :recipient, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :completed_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :trade_sessions, [:initiator_id, :recipient_id, :status], name: "index_trade_sessions_on_participants"

    create_table :trade_items do |t|
      t.references :trade_session, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: {to_table: :users}
      t.string :item_name
      t.jsonb :item_metadata, null: false, default: {}
      t.integer :quantity, null: false, default: 1
      t.string :item_quality
      t.string :currency_type
      t.integer :currency_amount
      t.timestamps
    end
  end
end
