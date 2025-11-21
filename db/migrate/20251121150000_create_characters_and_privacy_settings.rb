# frozen_string_literal: true

class CreateCharactersAndPrivacySettings < ActiveRecord::Migration[8.1]
  # Minimal User model for data backfill
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :character_class, foreign_key: true
      t.references :guild, foreign_key: true
      t.references :clan, foreign_key: true
      t.string :name, null: false
      t.integer :level, null: false, default: 1
      t.bigint :experience, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :characters, :name, unique: true

    add_column :users, :profile_name, :string
    add_column :users, :reputation_score, :integer, null: false, default: 0
    add_column :users, :chat_privacy, :integer, null: false, default: 0
    add_column :users, :friend_request_privacy, :integer, null: false, default: 0
    add_column :users, :duel_privacy, :integer, null: false, default: 0

    MigrationUser.reset_column_information
    MigrationUser.find_each do |user|
      base = user.email.to_s.split("@").first.presence || "adventurer"
      candidate = base.parameterize.presence || "adventurer"
      counter = 1

      while MigrationUser.exists?(profile_name: candidate)
        counter += 1
        candidate = "#{base.parameterize}-#{counter}"
      end

      user.update_columns(profile_name: candidate)
    end

    change_column_null :users, :profile_name, false
    add_index :users, :profile_name, unique: true
  end

  def down
    remove_index :users, :profile_name
    remove_column :users, :profile_name
    remove_column :users, :reputation_score
    remove_column :users, :chat_privacy
    remove_column :users, :friend_request_privacy
    remove_column :users, :duel_privacy

    drop_table :characters
  end
end
