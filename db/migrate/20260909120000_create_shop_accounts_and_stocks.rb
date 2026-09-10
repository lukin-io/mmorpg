class CreateShopAccountsAndStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_accounts do |t|
      t.references :location, polymorphic: true, null: false, index: {unique: true}
      t.decimal :nv_balance, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_check_constraint :shop_accounts,
      "location_type IN ('CityHotspot', 'TileBuilding')",
      name: "shop_accounts_location_type"
    add_check_constraint :shop_accounts,
      "nv_balance >= 0 AND nv_balance < 10000000000",
      name: "shop_accounts_bounded_balance"

    create_table :shop_stocks do |t|
      t.references :shop_account, null: false, foreign_key: true
      t.references :item_template, null: false, foreign_key: true
      t.integer :current, null: false
      t.integer :maximum
      t.timestamps
    end
    add_index :shop_stocks, [:shop_account_id, :item_template_id], unique: true
    add_check_constraint :shop_stocks, "current >= 0", name: "shop_stocks_nonnegative_current"
    add_check_constraint :shop_stocks,
      "maximum IS NULL OR (maximum >= 0 AND current <= maximum)",
      name: "shop_stocks_bounded_capacity"
  end
end
