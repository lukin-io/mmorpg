# frozen_string_literal: true

# Adds Ashen premium Veil Marks (VM) for combat trauma/heal scrolls.
class AddVeilMarksToCurrencyWallets < ActiveRecord::Migration[8.1]
  def up
    add_column :currency_wallets, :veil_marks, :decimal, precision: 12, scale: 2, null: false, default: 0
    add_check_constraint :currency_wallets,
      "veil_marks >= 0 AND veil_marks < 10000000000",
      name: "currency_wallets_bounded_veil_marks"
  end

  def down
    remove_check_constraint :currency_wallets, name: "currency_wallets_bounded_veil_marks"
    remove_column :currency_wallets, :veil_marks
  end
end
