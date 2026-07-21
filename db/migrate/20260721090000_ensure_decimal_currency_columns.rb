# frozen_string_literal: true

class EnsureDecimalCurrencyColumns < ActiveRecord::Migration[8.1]
  def up
    change_column :currency_wallets,
      :nv_balance,
      :decimal,
      precision: 12,
      scale: 2,
      default: "0.0",
      null: false
    change_column :currency_transactions,
      :amount,
      :decimal,
      precision: 12,
      scale: 2,
      null: false
    change_column :currency_transactions,
      :balance_after,
      :decimal,
      precision: 12,
      scale: 2,
      default: "0.0",
      null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
      "Converting NV amounts back to integers would discard fractional balances"
  end
end
