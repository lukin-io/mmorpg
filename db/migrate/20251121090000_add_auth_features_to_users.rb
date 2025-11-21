# frozen_string_literal: true

class AddAuthFeaturesToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      ## Trackable
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet :current_sign_in_ip
      t.inet :last_sign_in_ip

      ## Confirmable
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email

      ## Account metadata
      t.datetime :last_seen_at
      t.integer :premium_tokens_balance, null: false, default: 0
      t.jsonb :session_metadata, null: false, default: {}
    end

    add_index :users, :confirmation_token, unique: true
  end
end
