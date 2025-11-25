class AddSocialMessagingFields < ActiveRecord::Migration[8.1]
  def change
    change_table :chat_messages, bulk: true do |t|
      t.integer :reported_count, default: 0, null: false
      t.jsonb :moderation_labels, default: [], null: false
    end

    change_table :chat_reports, bulk: true do |t|
      t.jsonb :source_context, default: {}, null: false
    end

    change_table :users, bulk: true do |t|
      t.jsonb :social_settings, default: {}, null: false
    end

    change_table :user_sessions, bulk: true do |t|
      t.bigint :current_zone_id
      t.string :current_zone_name
      t.string :current_location_label
      t.bigint :last_character_id
      t.string :last_character_name
      t.datetime :last_activity_at
    end

    change_table :mail_messages, bulk: true do |t|
      t.boolean :system_notification, default: false, null: false
      t.jsonb :origin_metadata, default: {}, null: false
      t.datetime :attachments_claimed_at
    end

    create_table :ignore_list_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ignored_user, null: false, foreign_key: {to_table: :users}
      t.string :context
      t.string :notes
      t.timestamps
    end

    add_index :ignore_list_entries, [:user_id, :ignored_user_id], unique: true, name: "index_ignore_entries_on_user_and_target"
  end
end
