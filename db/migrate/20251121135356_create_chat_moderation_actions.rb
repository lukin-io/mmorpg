class CreateChatModerationActions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_moderation_actions do |t|
      t.references :target_user, null: false, foreign_key: {to_table: :users}
      t.references :actor, null: false, foreign_key: {to_table: :users}
      t.integer :action_type, null: false, default: 0
      t.datetime :expires_at
      t.jsonb :context, null: false, default: {}
      t.timestamps
    end

    add_index :chat_moderation_actions, [:target_user_id, :expires_at], name: "index_chat_moderation_actions_on_target_and_expiration"
  end
end
