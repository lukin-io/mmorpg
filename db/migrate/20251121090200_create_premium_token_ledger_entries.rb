# frozen_string_literal: true

class CreatePremiumTokenLedgerEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :premium_token_ledger_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.integer :delta, null: false
      t.integer :balance_after, null: false
      t.references :reference, polymorphic: true, index: true
      t.string :reason
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :premium_token_ledger_entries, :entry_type
    add_index :premium_token_ledger_entries, :created_at
  end
end
