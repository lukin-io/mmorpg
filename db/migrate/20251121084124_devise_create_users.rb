# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

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

      ## Game account metadata
      t.string :profile_name, null: false
      t.integer :reputation_score, null: false, default: 0
      t.integer :chat_privacy, null: false, default: 0
      t.integer :duel_privacy, null: false, default: 0
      t.datetime :last_seen_at
      t.jsonb :session_metadata, null: false, default: {}
      t.jsonb :social_settings, null: false, default: {}
      t.datetime :suspended_until
      t.datetime :chat_muted_until
      t.string :chat_mute_reason

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :profile_name, unique: true
    add_index :users, :suspended_until
    # add_index :users, :unlock_token,         unique: true
  end
end
