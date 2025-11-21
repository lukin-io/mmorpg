class CreateChatChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_channels do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :channel_type, null: false, default: 0
      t.boolean :system_owned, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.references :creator, null: true, foreign_key: {to_table: :users}
      t.timestamps
    end

    add_index :chat_channels, :slug, unique: true
    add_index :chat_channels, :channel_type

    create_table :chat_channel_memberships do |t|
      t.references :chat_channel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.datetime :muted_until
      t.timestamps
    end

    add_index :chat_channel_memberships, [:chat_channel_id, :user_id],
      unique: true,
      name: "index_chat_memberships_on_channel_and_user"
  end
end
