# frozen_string_literal: true

class CreateModerationActions < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_actions do |t|
      t.references :ticket, null: false, foreign_key: {to_table: :moderation_tickets}
      t.references :actor, null: false, foreign_key: {to_table: :users}
      t.references :target_user, foreign_key: {to_table: :users}
      t.references :target_character, foreign_key: {to_table: :characters}
      t.string :action_type, null: false
      t.text :reason, null: false
      t.integer :duration_seconds
      t.datetime :expires_at
      t.jsonb :context, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :moderation_actions, :action_type
    add_index :moderation_actions, :expires_at
  end
end
