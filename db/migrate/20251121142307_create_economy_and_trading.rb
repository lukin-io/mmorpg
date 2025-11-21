class CreateEconomyAndTrading < ActiveRecord::Migration[8.1]
  def change
    create_table :currency_wallets do |t|
      t.references :user, null: false, foreign_key: true, index: {unique: true}
      t.integer :gold_balance, null: false, default: 0
      t.integer :silver_balance, null: false, default: 0
      t.integer :premium_tokens_balance, null: false, default: 0
      t.timestamps
    end

    create_table :currency_transactions do |t|
      t.references :currency_wallet, null: false, foreign_key: true
      t.string :currency_type, null: false
      t.integer :amount, null: false
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :auction_listings do |t|
      t.references :seller, null: false, foreign_key: {to_table: :users}
      t.string :item_name, null: false
      t.jsonb :item_metadata, null: false, default: {}
      t.integer :quantity, null: false, default: 1
      t.string :currency_type, null: false
      t.integer :starting_bid, null: false
      t.integer :buyout_price
      t.integer :status, null: false, default: 0
      t.float :tax_rate, null: false, default: 0.0
      t.datetime :ends_at, null: false
      t.timestamps
    end
    add_index :auction_listings, :status
    add_index :auction_listings, :ends_at

    create_table :auction_bids do |t|
      t.references :auction_listing, null: false, foreign_key: true
      t.references :bidder, null: false, foreign_key: {to_table: :users}
      t.integer :amount, null: false
      t.timestamps
    end

    create_table :trade_sessions do |t|
      t.references :initiator, null: false, foreign_key: {to_table: :users}
      t.references :recipient, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :trade_sessions, [:initiator_id, :recipient_id, :status], name: "index_trade_sessions_on_parties_and_status"

    create_table :trade_items do |t|
      t.references :trade_session, null: false, foreign_key: true
      t.references :owner, null: false, foreign_key: {to_table: :users}
      t.string :item_name
      t.jsonb :item_metadata, null: false, default: {}
      t.integer :quantity, null: false, default: 1
      t.string :currency_type
      t.integer :currency_amount
      t.timestamps
    end

    create_table :marketplace_kiosks do |t|
      t.string :city, null: false
      t.references :seller, null: false, foreign_key: {to_table: :users}
      t.string :item_name, null: false
      t.integer :quantity, null: false
      t.integer :price, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
