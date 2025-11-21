# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :device_id, null: false
      t.string :user_agent
      t.string :ip_address
      t.string :status, null: false, default: "online"
      t.datetime :signed_in_at, null: false
      t.datetime :last_seen_at
      t.datetime :signed_out_at
      t.datetime :revoked_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :user_sessions, [:user_id, :device_id], unique: true
    add_index :user_sessions, :status
  end
end
