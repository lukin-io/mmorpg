# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_id, null: false
      t.datetime :signed_in_at, null: false
      t.datetime :last_seen_at
      t.datetime :signed_out_at

      t.timestamps
    end

    add_index :user_sessions, [:user_id, :device_id], unique: true
  end
end
