class CreateChatMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_messages do |t|
      t.references :chat_channel, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: {to_table: :users}
      t.text :body, null: false
      t.text :filtered_body, null: false
      t.integer :visibility, null: false, default: 0
      t.boolean :flagged, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :chat_messages, [:chat_channel_id, :created_at]
    add_index :chat_messages, :flagged
  end
end
