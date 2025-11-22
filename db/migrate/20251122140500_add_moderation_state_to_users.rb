# frozen_string_literal: true

class AddModerationStateToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.datetime :suspended_until
      t.datetime :trade_locked_until
    end

    add_index :users, :suspended_until
    add_index :users, :trade_locked_until
  end
end
