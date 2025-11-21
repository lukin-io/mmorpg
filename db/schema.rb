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

ActiveRecord::Schema[8.1].define(version: 2025_11_21_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievement_grants", force: :cascade do |t|
    t.bigint "achievement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "granted_at", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["achievement_id"], name: "index_achievement_grants_on_achievement_id"
    t.index ["user_id", "achievement_id"], name: "index_achievement_grants_on_user_and_achievement", unique: true
    t.index ["user_id"], name: "index_achievement_grants_on_user_id"
  end

  create_table "achievements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.integer "points", default: 0, null: false
    t.jsonb "reward_payload", default: {}, null: false
    t.string "reward_type"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_achievements_on_key", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_announcements_on_created_at"
  end

  create_table "auction_bids", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "auction_listing_id", null: false
    t.bigint "bidder_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auction_listing_id"], name: "index_auction_bids_on_auction_listing_id"
    t.index ["bidder_id"], name: "index_auction_bids_on_bidder_id"
  end

  create_table "auction_listings", force: :cascade do |t|
    t.integer "buyout_price"
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.datetime "ends_at", null: false
    t.jsonb "item_metadata", default: {}, null: false
    t.string "item_name", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "seller_id", null: false
    t.integer "starting_bid", null: false
    t.integer "status", default: 0, null: false
    t.float "tax_rate", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["ends_at"], name: "index_auction_listings_on_ends_at"
    t.index ["seller_id"], name: "index_auction_listings_on_seller_id"
    t.index ["status"], name: "index_auction_listings_on_status"
  end

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

  create_table "character_classes", force: :cascade do |t|
    t.jsonb "base_stats", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_character_classes_on_name", unique: true
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "character_class_id"
    t.bigint "clan_id"
    t.datetime "created_at", null: false
    t.bigint "experience", default: 0, null: false
    t.bigint "guild_id"
    t.integer "level", default: 1, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["character_class_id"], name: "index_characters_on_character_class_id"
    t.index ["clan_id"], name: "index_characters_on_clan_id"
    t.index ["guild_id"], name: "index_characters_on_guild_id"
    t.index ["name"], name: "index_characters_on_name", unique: true
    t.index ["user_id"], name: "index_characters_on_user_id"
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

  create_table "clan_memberships", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["clan_id", "user_id"], name: "index_clan_memberships_on_clan_id_and_user_id", unique: true
    t.index ["clan_id"], name: "index_clan_memberships_on_clan_id"
    t.index ["user_id"], name: "index_clan_memberships_on_user_id"
  end

  create_table "clan_territories", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_claimed_at"
    t.integer "tax_rate_basis_points", default: 0, null: false
    t.string "territory_key", null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id"], name: "index_clan_territories_on_clan_id"
    t.index ["territory_key"], name: "index_clan_territories_on_territory_key", unique: true
  end

  create_table "clan_wars", force: :cascade do |t|
    t.bigint "attacker_clan_id", null: false
    t.datetime "created_at", null: false
    t.bigint "defender_clan_id", null: false
    t.datetime "resolved_at"
    t.jsonb "result_payload", default: {}, null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0, null: false
    t.string "territory_key", null: false
    t.datetime "updated_at", null: false
    t.index ["attacker_clan_id", "defender_clan_id", "territory_key"], name: "index_clan_wars_on_participants_and_territory"
    t.index ["attacker_clan_id"], name: "index_clan_wars_on_attacker_clan_id"
    t.index ["defender_clan_id"], name: "index_clan_wars_on_defender_clan_id"
  end

  create_table "clans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "leader_id", null: false
    t.string "name", null: false
    t.integer "prestige", default: 0, null: false
    t.string "slug", null: false
    t.integer "treasury_gold", default: 0, null: false
    t.integer "treasury_premium_tokens", default: 0, null: false
    t.integer "treasury_silver", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["leader_id"], name: "index_clans_on_leader_id"
    t.index ["slug"], name: "index_clans_on_slug", unique: true
  end

  create_table "competition_brackets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_event_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["game_event_id"], name: "index_competition_brackets_on_game_event_id"
  end

  create_table "competition_matches", force: :cascade do |t|
    t.bigint "competition_bracket_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "participants", default: {}, null: false
    t.jsonb "result_payload", default: {}, null: false
    t.integer "round_number", default: 1, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_bracket_id"], name: "index_competition_matches_on_competition_bracket_id"
  end

  create_table "crafting_jobs", force: :cascade do |t|
    t.datetime "completes_at", null: false
    t.bigint "crafting_station_id", null: false
    t.datetime "created_at", null: false
    t.bigint "recipe_id", null: false
    t.jsonb "result_payload", default: {}, null: false
    t.datetime "started_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["crafting_station_id"], name: "index_crafting_jobs_on_crafting_station_id"
    t.index ["recipe_id"], name: "index_crafting_jobs_on_recipe_id"
    t.index ["user_id"], name: "index_crafting_jobs_on_user_id"
  end

  create_table "crafting_stations", force: :cascade do |t|
    t.integer "capacity", default: 5, null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "station_type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currency_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.bigint "currency_wallet_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_wallet_id"], name: "index_currency_transactions_on_currency_wallet_id"
  end

  create_table "currency_wallets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "gold_balance", default: 0, null: false
    t.integer "premium_tokens_balance", default: 0, null: false
    t.integer "silver_balance", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_currency_wallets_on_user_id", unique: true
  end

  create_table "event_schedules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_event_id", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "schedule_type", null: false
    t.datetime "updated_at", null: false
    t.index ["game_event_id"], name: "index_event_schedules_on_game_event_id"
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

  create_table "game_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at", null: false
    t.string "feature_flag_key"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_game_events_on_slug", unique: true
  end

  create_table "guild_applications", force: :cascade do |t|
    t.jsonb "answers", default: {}, null: false
    t.bigint "applicant_id", null: false
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["applicant_id"], name: "index_guild_applications_on_applicant_id"
    t.index ["guild_id", "applicant_id"], name: "index_guild_applications_on_guild_and_applicant", unique: true
    t.index ["guild_id"], name: "index_guild_applications_on_guild_id"
    t.index ["reviewed_by_id"], name: "index_guild_applications_on_reviewed_by_id"
  end

  create_table "guild_bank_entries", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.integer "entry_type", default: 0, null: false
    t.bigint "guild_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_guild_bank_entries_on_actor_id"
    t.index ["guild_id"], name: "index_guild_bank_entries_on_guild_id"
  end

  create_table "guild_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.datetime "joined_at"
    t.jsonb "permissions", default: {}, null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["guild_id", "user_id"], name: "index_guild_memberships_on_guild_id_and_user_id", unique: true
    t.index ["guild_id"], name: "index_guild_memberships_on_guild_id"
    t.index ["user_id"], name: "index_guild_memberships_on_user_id"
  end

  create_table "guilds", force: :cascade do |t|
    t.jsonb "banner_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "experience", default: 0, null: false
    t.bigint "leader_id", null: false
    t.integer "level", default: 1, null: false
    t.text "motto"
    t.string "name", null: false
    t.jsonb "recruitment_settings", default: {}, null: false
    t.string "slug", null: false
    t.integer "treasury_gold", default: 0, null: false
    t.integer "treasury_premium_tokens", default: 0, null: false
    t.integer "treasury_silver", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["leader_id"], name: "index_guilds_on_leader_id"
    t.index ["slug"], name: "index_guilds_on_slug", unique: true
  end

  create_table "housing_decor_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "housing_plot_id", null: false
    t.string "name", null: false
    t.jsonb "placement", default: {}, null: false
    t.boolean "trophy", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["housing_plot_id"], name: "index_housing_decor_items_on_housing_plot_id"
  end

  create_table "housing_plots", force: :cascade do |t|
    t.jsonb "access_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "location_key", null: false
    t.string "plot_type", null: false
    t.integer "storage_slots", default: 20, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_housing_plots_on_user_id"
  end

  create_table "item_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "rarity", null: false
    t.string "slot", null: false
    t.jsonb "stat_modifiers", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_item_templates_on_name", unique: true
    t.index ["rarity"], name: "index_item_templates_on_rarity"
    t.index ["slot"], name: "index_item_templates_on_slot"
  end

  create_table "leaderboard_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entity_id", null: false
    t.string "entity_type", null: false
    t.bigint "leaderboard_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "rank"
    t.integer "score", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["leaderboard_id", "entity_type", "entity_id"], name: "index_leaderboard_entries_on_scope", unique: true
    t.index ["leaderboard_id"], name: "index_leaderboard_entries_on_leaderboard_id"
  end

  create_table "leaderboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "name", null: false
    t.string "scope", null: false
    t.string "season", null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "map_tile_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.boolean "passable", default: true, null: false
    t.string "terrain_type", null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.string "zone", null: false
    t.index ["zone", "x", "y"], name: "index_map_tile_templates_on_zone_and_x_and_y", unique: true
  end

  create_table "marketplace_kiosks", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "item_name", null: false
    t.integer "price", null: false
    t.integer "quantity", null: false
    t.bigint "seller_id", null: false
    t.datetime "updated_at", null: false
    t.index ["seller_id"], name: "index_marketplace_kiosks_on_seller_id"
  end

  create_table "mounts", force: :cascade do |t|
    t.jsonb "appearance", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "mount_type", null: false
    t.string "name", null: false
    t.integer "speed_bonus", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_mounts_on_user_id"
  end

  create_table "npc_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "dialogue", null: false
    t.integer "level", default: 1, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_npc_templates_on_name", unique: true
    t.index ["role"], name: "index_npc_templates_on_role"
  end

  create_table "pet_companions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level", default: 1, null: false
    t.string "nickname"
    t.bigint "pet_species_id", null: false
    t.jsonb "stats", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["pet_species_id"], name: "index_pet_companions_on_pet_species_id"
    t.index ["user_id"], name: "index_pet_companions_on_user_id"
  end

  create_table "pet_species", force: :cascade do |t|
    t.jsonb "ability_payload", default: {}, null: false
    t.string "ability_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "rarity", default: "common", null: false
    t.datetime "updated_at", null: false
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

  create_table "profession_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "experience", default: 0, null: false
    t.integer "mastery_tier", default: 0, null: false
    t.bigint "profession_id", null: false
    t.integer "skill_level", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["profession_id"], name: "index_profession_progresses_on_profession_id"
    t.index ["user_id", "profession_id"], name: "index_profession_progresses_on_user_and_profession", unique: true
    t.index ["user_id"], name: "index_profession_progresses_on_user_id"
  end

  create_table "professions", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "gathering", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_professions_on_name", unique: true
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

  create_table "recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_seconds", default: 60, null: false
    t.string "name", null: false
    t.string "output_item_name", null: false
    t.bigint "profession_id", null: false
    t.jsonb "requirements", default: {}, null: false
    t.jsonb "rewards", default: {}, null: false
    t.integer "tier", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["profession_id"], name: "index_recipes_on_profession_id"
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

  create_table "titles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.boolean "premium_only", default: false, null: false
    t.string "requirement_key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trade_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "currency_amount"
    t.string "currency_type"
    t.jsonb "item_metadata", default: {}, null: false
    t.string "item_name"
    t.bigint "owner_id", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "trade_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_trade_items_on_owner_id"
    t.index ["trade_session_id"], name: "index_trade_items_on_trade_session_id"
  end

  create_table "trade_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "initiator_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "recipient_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id", "recipient_id", "status"], name: "index_trade_sessions_on_parties_and_status"
    t.index ["initiator_id"], name: "index_trade_sessions_on_initiator_id"
    t.index ["recipient_id"], name: "index_trade_sessions_on_recipient_id"
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
    t.integer "chat_privacy", default: 0, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.inet "current_sign_in_ip"
    t.integer "duel_privacy", default: 0, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "friend_request_privacy", default: 0, null: false
    t.datetime "last_seen_at"
    t.datetime "last_sign_in_at"
    t.inet "last_sign_in_ip"
    t.integer "premium_tokens_balance", default: 0, null: false
    t.string "profile_name", null: false
    t.datetime "remember_created_at"
    t.integer "reputation_score", default: 0, null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.jsonb "session_metadata", default: {}, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["profile_name"], name: "index_users_on_profile_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "achievement_grants", "achievements"
  add_foreign_key "achievement_grants", "users"
  add_foreign_key "auction_bids", "auction_listings"
  add_foreign_key "auction_bids", "users", column: "bidder_id"
  add_foreign_key "auction_listings", "users", column: "seller_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "characters", "character_classes"
  add_foreign_key "characters", "clans"
  add_foreign_key "characters", "guilds"
  add_foreign_key "characters", "users"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "chat_channels", "users", column: "creator_id"
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "chat_moderation_actions", "users", column: "actor_id"
  add_foreign_key "chat_moderation_actions", "users", column: "target_user_id"
  add_foreign_key "chat_reports", "chat_messages"
  add_foreign_key "chat_reports", "users", column: "reporter_id"
  add_foreign_key "clan_memberships", "clans"
  add_foreign_key "clan_memberships", "users"
  add_foreign_key "clan_territories", "clans"
  add_foreign_key "clan_wars", "clans", column: "attacker_clan_id"
  add_foreign_key "clan_wars", "clans", column: "defender_clan_id"
  add_foreign_key "clans", "users", column: "leader_id"
  add_foreign_key "competition_brackets", "game_events"
  add_foreign_key "competition_matches", "competition_brackets"
  add_foreign_key "crafting_jobs", "crafting_stations"
  add_foreign_key "crafting_jobs", "recipes"
  add_foreign_key "crafting_jobs", "users"
  add_foreign_key "currency_transactions", "currency_wallets"
  add_foreign_key "currency_wallets", "users"
  add_foreign_key "event_schedules", "game_events"
  add_foreign_key "friendships", "users", column: "receiver_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "guild_applications", "guilds"
  add_foreign_key "guild_applications", "users", column: "applicant_id"
  add_foreign_key "guild_applications", "users", column: "reviewed_by_id"
  add_foreign_key "guild_bank_entries", "guilds"
  add_foreign_key "guild_bank_entries", "users", column: "actor_id"
  add_foreign_key "guild_memberships", "guilds"
  add_foreign_key "guild_memberships", "users"
  add_foreign_key "guilds", "users", column: "leader_id"
  add_foreign_key "housing_decor_items", "housing_plots"
  add_foreign_key "housing_plots", "users"
  add_foreign_key "leaderboard_entries", "leaderboards"
  add_foreign_key "mail_messages", "users", column: "recipient_id"
  add_foreign_key "mail_messages", "users", column: "sender_id"
  add_foreign_key "marketplace_kiosks", "users", column: "seller_id"
  add_foreign_key "mounts", "users"
  add_foreign_key "pet_companions", "pet_species", column: "pet_species_id"
  add_foreign_key "pet_companions", "users"
  add_foreign_key "premium_token_ledger_entries", "users"
  add_foreign_key "profession_progresses", "professions"
  add_foreign_key "profession_progresses", "users"
  add_foreign_key "purchases", "users"
  add_foreign_key "recipes", "professions"
  add_foreign_key "trade_items", "trade_sessions"
  add_foreign_key "trade_items", "users", column: "owner_id"
  add_foreign_key "trade_sessions", "users", column: "initiator_id"
  add_foreign_key "trade_sessions", "users", column: "recipient_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
end
