# frozen_string_literal: true

class CreateTradeHubTables < ActiveRecord::Migration[8.0]
  def change
    create_table :auction_listings do |t|
      t.references :seller_character, null: false, foreign_key: {to_table: :characters}
      t.references :item_template, null: false, foreign_key: true
      t.references :buyer_character, foreign_key: {to_table: :characters}
      t.integer :quantity, null: false, default: 1
      t.decimal :price_nv, null: false, precision: 14, scale: 2
      t.string :status, null: false, default: "open"
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :auction_listings, :status

    create_table :currency_exchange_offers do |t|
      t.references :seller, null: false, foreign_key: {to_table: :users}
      t.string :give_currency, null: false
      t.decimal :give_amount, null: false, precision: 14, scale: 2
      t.string :want_currency, null: false
      t.decimal :want_amount, null: false, precision: 14, scale: 2
      t.string :status, null: false, default: "open"
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :currency_exchange_offers, :status
  end
end
