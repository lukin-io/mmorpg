# frozen_string_literal: true

class CreateArenaBets < ActiveRecord::Migration[8.0]
  def change
    create_table :arena_bets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :arena_match, null: false, foreign_key: true
      t.references :predicted_winner, null: false, foreign_key: {to_table: :characters}

      t.integer :amount, null: false
      t.integer :currency_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.integer :payout_amount, default: 0

      t.timestamps
    end

    add_index :arena_bets, [:user_id, :arena_match_id], unique: true
    add_index :arena_bets, [:arena_match_id, :status]
  end
end
