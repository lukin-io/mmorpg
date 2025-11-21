# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_21_135356) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target"
  end

  create_table "chat_channel_memberships", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "muted_until"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chat_channel_id", "user_id"], name: "index_chat_memberships_on_channel_and_user", unique: true
    t.index ["chat_channel_id"], name: "index_chat_channel_memberships_on_chat_channel_id"
    t.index ["user_id"], name: "index_chat_channel_memberships_on_user_id"
  end

  create_table "chat_channels", force: :cascade do |t|
    t.integer "channel_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "system_owned", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["channel_type"], name: "index_chat_channels_on_channel_type"
    t.index ["creator_id"], name: "index_chat_channels_on_creator_id"
    t.index ["slug"], name: "index_chat_channels_on_slug", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
    t.text "filtered_body", null: false
    t.boolean "flagged", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["chat_channel_id", "created_at"], name: "index_chat_messages_on_chat_channel_id_and_created_at"
    t.index ["chat_channel_id"], name: "index_chat_messages_on_chat_channel_id"
    t.index ["flagged"], name: "index_chat_messages_on_flagged"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "chat_moderation_actions", force: :cascade do |t|
    t.integer "action_type", default: 0, null: false
    t.bigint "actor_id", null: false
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "target_user_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_chat_moderation_actions_on_actor_id"
    t.index ["target_user_id", "expires_at"], name: "index_chat_moderation_actions_on_target_and_expiration"
    t.index ["target_user_id"], name: "index_chat_moderation_actions_on_target_user_id"
  end

  create_table "chat_reports", force: :cascade do |t|
    t.bigint "chat_message_id"
    t.datetime "created_at", null: false
    t.jsonb "evidence", default: {}, null: false
    t.text "reason", null: false
    t.bigint "reporter_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["chat_message_id"], name: "index_chat_reports_on_chat_message_id"
    t.index ["reporter_id"], name: "index_chat_reports_on_reporter_id"
    t.index ["status"], name: "index_chat_reports_on_status"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "friendships", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.bigint "receiver_id", null: false
    t.bigint "requester_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_friendships_on_receiver_id"
    t.index ["requester_id", "receiver_id"], name: "index_friendships_on_requester_id_and_receiver_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
  end

  create_table "mail_messages", force: :cascade do |t|
    t.jsonb "attachment_payload", default: {}, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "delivered_at"], name: "index_mail_messages_on_recipient_id_and_delivered_at"
    t.index ["recipient_id"], name: "index_mail_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_mail_messages_on_sender_id"
  end

  create_table "premium_token_ledger_entries", force: :cascade do |t|
    t.integer "balance_after", null: false
    t.datetime "created_at", null: false
    t.integer "delta", null: false
    t.string "entry_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason"
    t.bigint "reference_id"
    t.string "reference_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_premium_token_ledger_entries_on_created_at"
    t.index ["entry_type"], name: "index_premium_token_ledger_entries_on_entry_type"
    t.index ["reference_type", "reference_id"], name: "index_premium_token_ledger_entries_on_reference"
    t.index ["user_id"], name: "index_premium_token_ledger_entries_on_user_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.string "external_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "provider", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_purchases_on_external_id", unique: true
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id", null: false
    t.string "ip_address"
    t.datetime "last_seen_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "revoked_at"
    t.datetime "signed_in_at", null: false
    t.datetime "signed_out_at"
    t.string "status", default: "online", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_user_sessions_on_status"
    t.index ["user_id", "device_id"], name: "index_user_sessions_on_user_id_and_device_id", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_seen_at"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.integer "premium_tokens_balance", default: 0, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "session_metadata", default: {}, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "chat_channels", "users", column: "creator_id"
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "chat_moderation_actions", "users", column: "actor_id"
  add_foreign_key "chat_moderation_actions", "users", column: "target_user_id"
  add_foreign_key "chat_reports", "chat_messages"
  add_foreign_key "chat_reports", "users", column: "reporter_id"
  add_foreign_key "friendships", "users", column: "receiver_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "mail_messages", "users", column: "recipient_id"
  add_foreign_key "mail_messages", "users", column: "sender_id"
  add_foreign_key "premium_token_ledger_entries", "users"
  add_foreign_key "purchases", "users"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
end
