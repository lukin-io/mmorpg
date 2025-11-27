# frozen_string_literal: true

class CreateChatViolations < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_violations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat_message, null: true, foreign_key: true
      t.string :violation_type, null: false
      t.string :severity, null: false
      t.integer :severity_points, null: false, default: 1
      t.string :reason
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :chat_violations, [:user_id, :created_at]
    add_index :chat_violations, :violation_type

    # Add chat mute columns to users if not present
    unless column_exists?(:users, :chat_muted_until)
      add_column :users, :chat_muted_until, :datetime
      add_column :users, :chat_mute_reason, :string
    end
  end
end
