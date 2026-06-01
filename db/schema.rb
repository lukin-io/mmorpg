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

ActiveRecord::Schema[8.1].define(version: 2026_05_09_211000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "arena_applications", force: :cascade do |t|
    t.bigint "applicant_id"
    t.bigint "arena_match_id"
    t.bigint "arena_room_id", null: false
    t.datetime "created_at", null: false
    t.integer "enemy_count"
    t.integer "enemy_level_max"
    t.integer "enemy_level_min"
    t.datetime "expires_at"
    t.integer "fight_kind", default: 0, null: false
    t.integer "fight_type", default: 0, null: false
    t.datetime "matched_at"
    t.bigint "matched_with_id"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "npc_template_id"
    t.datetime "starts_at"
    t.integer "status", default: 0, null: false
    t.integer "team_count", default: 1
    t.integer "team_level_max"
    t.integer "team_level_min"
    t.integer "timeout_seconds", default: 180, null: false
    t.integer "trauma_percent", default: 30, null: false
    t.datetime "updated_at", null: false
    t.integer "wait_minutes", default: 10
    t.index ["applicant_id"], name: "index_arena_applications_on_applicant_id"
    t.index ["arena_match_id"], name: "index_arena_applications_on_arena_match_id"
    t.index ["arena_room_id", "npc_template_id"], name: "idx_arena_apps_npc", where: "(npc_template_id IS NOT NULL)"
    t.index ["arena_room_id", "status"], name: "index_arena_applications_on_arena_room_id_and_status"
    t.index ["arena_room_id"], name: "index_arena_applications_on_arena_room_id"
    t.index ["fight_type"], name: "index_arena_applications_on_fight_type"
    t.index ["matched_with_id"], name: "index_arena_applications_on_matched_with_id"
    t.index ["npc_template_id"], name: "index_arena_applications_on_npc_template_id"
    t.index ["status"], name: "index_arena_applications_on_status"
  end

  create_table "arena_matches", force: :cascade do |t|
    t.bigint "arena_room_id"
    t.string "bracket_position"
    t.datetime "created_at", null: false
    t.integer "current_turn_number", default: 0
    t.datetime "current_turn_started_at"
    t.string "current_turn_team"
    t.datetime "ended_at"
    t.integer "match_type", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.boolean "timed_out", default: false
    t.integer "trauma_percent", default: 30
    t.integer "turn_timeout_seconds", default: 300
    t.datetime "updated_at", null: false
    t.string "winning_team"
    t.bigint "zone_id"
    t.index ["arena_room_id"], name: "index_arena_matches_on_arena_room_id"
    t.index ["status", "current_turn_started_at"], name: "index_arena_matches_on_timeout_check", where: "(status = 2)"
    t.index ["status"], name: "index_arena_matches_on_status"
    t.index ["zone_id"], name: "index_arena_matches_on_zone_id"
  end

  create_table "arena_participations", force: :cascade do |t|
    t.bigint "arena_match_id", null: false
    t.bigint "character_id"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.datetime "joined_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "npc_template_id"
    t.integer "result", default: 0, null: false
    t.string "team", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["arena_match_id", "character_id"], name: "index_arena_participants_on_match_and_character", unique: true
    t.index ["arena_match_id"], name: "index_arena_participations_on_arena_match_id"
    t.index ["character_id"], name: "index_arena_participations_on_character_id"
    t.index ["npc_template_id"], name: "index_arena_participations_on_npc_template_id"
    t.index ["user_id"], name: "index_arena_participations_on_user_id"
  end

  create_table "arena_rooms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "alignment_restriction"
    t.datetime "created_at", null: false
    t.integer "level_max", default: 100, null: false
    t.integer "level_min", default: 0, null: false
    t.integer "max_concurrent_matches", default: 10, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "room_type", default: 1, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.index ["active"], name: "index_arena_rooms_on_active"
    t.index ["room_type"], name: "index_arena_rooms_on_room_type"
    t.index ["slug"], name: "index_arena_rooms_on_slug", unique: true
    t.index ["zone_id"], name: "index_arena_rooms_on_zone_id"
  end

  create_table "character_positions", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_action_at"
    t.integer "last_turn_number", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.bigint "zone_id", null: false
    t.index ["character_id"], name: "index_character_positions_on_character_id", unique: true
    t.index ["zone_id", "x", "y"], name: "index_character_positions_on_zone_id_and_x_and_y"
    t.index ["zone_id"], name: "index_character_positions_on_zone_id"
  end

  create_table "characters", force: :cascade do |t|
    t.string "alignment", default: "none", null: false
    t.jsonb "allocated_stats", default: {}, null: false
    t.integer "combat_skill_points", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "current_hp", default: 100, null: false
    t.integer "current_mp", default: 50, null: false
    t.bigint "experience", default: 0, null: false
    t.integer "fatigue_percent", default: 0, null: false
    t.integer "hp_regen_interval", default: 300, null: false
    t.boolean "in_combat", default: false, null: false
    t.datetime "last_combat_at"
    t.datetime "last_level_up_at"
    t.datetime "last_regen_tick_at"
    t.integer "level", default: 1, null: false
    t.integer "max_hp", default: 100, null: false
    t.integer "max_mp", default: 50, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "mp_regen_interval", default: 600, null: false
    t.string "name", null: false
    t.jsonb "passive_skills", default: {}, null: false
    t.integer "peace_skill_points", default: 0, null: false
    t.integer "stat_points_available", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["combat_skill_points"], name: "index_characters_on_combat_skill_points", where: "(combat_skill_points > 0)"
    t.index ["name"], name: "index_characters_on_name", unique: true
    t.index ["peace_skill_points"], name: "index_characters_on_peace_skill_points", where: "(peace_skill_points > 0)"
    t.index ["user_id"], name: "index_characters_on_user_id"
  end

  create_table "chat_channel_memberships", force: :cascade do |t|
    t.bigint "chat_channel_id", null: false
    t.datetime "created_at", null: false
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
    t.jsonb "metadata", default: {}, null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["chat_channel_id", "created_at"], name: "index_chat_messages_on_chat_channel_id_and_created_at"
    t.index ["chat_channel_id"], name: "index_chat_messages_on_chat_channel_id"
    t.index ["sender_id"], name: "index_chat_messages_on_sender_id"
  end

  create_table "city_hotspots", force: :cascade do |t|
    t.jsonb "action_params", default: {}
    t.string "action_type", default: "open_feature", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "destination_zone_id"
    t.integer "height"
    t.string "hotspot_type", default: "building", null: false
    t.string "image_hover"
    t.string "image_normal"
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position_x", null: false
    t.integer "position_y", null: false
    t.integer "required_level", default: 1
    t.datetime "updated_at", null: false
    t.integer "width"
    t.integer "z_index", default: 0
    t.bigint "zone_id", null: false
    t.index ["active"], name: "index_city_hotspots_on_active"
    t.index ["destination_zone_id"], name: "index_city_hotspots_on_destination_zone_id"
    t.index ["hotspot_type"], name: "index_city_hotspots_on_hotspot_type"
    t.index ["zone_id", "key"], name: "index_city_hotspots_on_zone_id_and_key", unique: true
    t.index ["zone_id"], name: "index_city_hotspots_on_zone_id"
  end

  create_table "combat_log_entries", force: :cascade do |t|
    t.string "action_key"
    t.bigint "actor_id"
    t.string "actor_team"
    t.string "actor_type"
    t.bigint "arena_match_id", null: false
    t.string "body_part"
    t.datetime "created_at", null: false
    t.integer "damage_amount", default: 0, null: false
    t.string "log_type", default: "action", null: false
    t.text "message", null: false
    t.datetime "occurred_at"
    t.string "outcome"
    t.jsonb "payload", default: {}, null: false
    t.integer "round_number", default: 1, null: false
    t.integer "sequence", default: 1, null: false
    t.string "tags", default: [], array: true
    t.bigint "target_id"
    t.string "target_team"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_combat_log_entries_on_actor_id"
    t.index ["arena_match_id", "log_type"], name: "index_combat_logs_on_arena_match_and_log_type"
    t.index ["arena_match_id", "round_number", "sequence"], name: "index_combat_logs_on_arena_match_round_sequence"
    t.index ["arena_match_id"], name: "index_combat_log_entries_on_arena_match_id"
    t.index ["log_type"], name: "index_combat_log_entries_on_log_type"
    t.index ["tags"], name: "index_combat_log_entries_on_tags", using: :gin
    t.index ["target_id"], name: "index_combat_log_entries_on_target_id"
  end

  create_table "currency_transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "balance_after", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.bigint "currency_wallet_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_currency_transactions_on_created_at"
    t.index ["currency_wallet_id"], name: "index_currency_transactions_on_currency_wallet_id"
  end

  create_table "currency_wallets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "nv_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_currency_wallets_on_user_id", unique: true
  end

  create_table "ignore_list_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ignored_user_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ignored_user_id"], name: "index_ignore_list_entries_on_ignored_user_id"
    t.index ["user_id", "ignored_user_id"], name: "index_ignore_entries_on_user_and_target", unique: true
    t.index ["user_id"], name: "index_ignore_list_entries_on_user_id"
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "currency_storage", default: {}, null: false
    t.integer "current_weight", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "slot_capacity", default: 30, null: false
    t.datetime "updated_at", null: false
    t.integer "weight_capacity", default: 100, null: false
    t.index ["character_id"], name: "index_inventories_on_character_id", unique: true
  end

  create_table "inventory_items", force: :cascade do |t|
    t.boolean "bound", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "enhancement_level", default: 0, null: false
    t.string "equipment_slot"
    t.boolean "equipped", default: false, null: false
    t.bigint "inventory_id", null: false
    t.bigint "item_template_id", null: false
    t.datetime "last_enhanced_at"
    t.jsonb "properties", default: {}, null: false
    t.integer "quantity", default: 1, null: false
    t.integer "slot_index"
    t.string "slot_kind"
    t.datetime "updated_at", null: false
    t.integer "weight", default: 0, null: false
    t.index ["inventory_id", "equipped", "equipment_slot"], name: "idx_inventory_equipped_slot"
    t.index ["inventory_id", "slot_kind"], name: "index_inventory_items_on_inventory_id_and_slot_kind"
    t.index ["inventory_id"], name: "index_inventory_items_on_inventory_id"
    t.index ["item_template_id"], name: "index_inventory_items_on_item_template_id"
  end

  create_table "item_templates", force: :cascade do |t|
    t.integer "base_price", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "durability_max", default: 0, null: false
    t.jsonb "enhancement_rules", default: {}, null: false
    t.string "item_type", default: "equipment"
    t.string "key"
    t.string "name", null: false
    t.jsonb "requirements", default: {}, null: false
    t.string "slot", null: false
    t.integer "stack_limit", default: 99, null: false
    t.jsonb "stat_modifiers", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 1, null: false
    t.index ["item_type"], name: "index_item_templates_on_item_type"
    t.index ["key"], name: "index_item_templates_on_key", unique: true
    t.index ["name"], name: "index_item_templates_on_name", unique: true
    t.index ["slot"], name: "index_item_templates_on_slot"
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

  create_table "movement_commands", force: :cascade do |t|
    t.string "action_key"
    t.bigint "character_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.datetime "ends_at"
    t.string "error_message"
    t.datetime "failed_at"
    t.integer "from_x", null: false
    t.integer "from_y", null: false
    t.integer "latency_ms", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "predicted_x"
    t.integer "predicted_y"
    t.datetime "processed_at"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "target_x", null: false
    t.integer "target_y", null: false
    t.integer "travel_seconds", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["action_key"], name: "index_movement_commands_on_action_key", unique: true
    t.index ["character_id", "status", "created_at"], name: "index_movement_commands_on_character_status_created"
    t.index ["character_id", "status", "ends_at"], name: "index_movement_commands_on_character_status_ends"
    t.index ["character_id"], name: "index_movement_commands_on_character_id"
    t.index ["created_at"], name: "index_movement_commands_on_created_at"
    t.index ["status"], name: "index_movement_commands_on_status"
    t.index ["zone_id"], name: "index_movement_commands_on_zone_id"
  end

  create_table "npc_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "dialogue", null: false
    t.integer "level", default: 1, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "npc_key"
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_npc_templates_on_name", unique: true
    t.index ["npc_key"], name: "index_npc_templates_on_npc_key", unique: true
    t.index ["role"], name: "index_npc_templates_on_role"
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

  create_table "spawn_points", force: :cascade do |t|
    t.string "city_key"
    t.datetime "created_at", null: false
    t.boolean "default_entry", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.bigint "zone_id", null: false
    t.index ["zone_id"], name: "index_spawn_points_on_zone_id"
  end

  create_table "tile_buildings", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "building_key", null: false
    t.string "building_type", default: "city", null: false
    t.datetime "created_at", null: false
    t.integer "destination_x"
    t.integer "destination_y"
    t.bigint "destination_zone_id"
    t.string "icon", default: "🏙️"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "required_level", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.string "zone", null: false
    t.index ["active"], name: "index_tile_buildings_on_active"
    t.index ["building_key"], name: "index_tile_buildings_on_building_key", unique: true
    t.index ["building_type"], name: "index_tile_buildings_on_building_type"
    t.index ["destination_zone_id"], name: "index_tile_buildings_on_destination_zone_id"
    t.index ["zone", "x", "y"], name: "index_tile_buildings_on_zone_and_x_and_y", unique: true
  end

  create_table "tile_npcs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_hp"
    t.datetime "defeated_at"
    t.bigint "defeated_by_id"
    t.integer "level", default: 1, null: false
    t.integer "max_hp"
    t.jsonb "metadata", default: {}, null: false
    t.string "npc_key", null: false
    t.string "npc_role", default: "hostile", null: false
    t.bigint "npc_template_id", null: false
    t.datetime "respawns_at"
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.string "zone", null: false
    t.index ["defeated_by_id"], name: "index_tile_npcs_on_defeated_by_id"
    t.index ["npc_role"], name: "index_tile_npcs_on_npc_role"
    t.index ["npc_template_id"], name: "index_tile_npcs_on_npc_template_id"
    t.index ["respawns_at"], name: "index_tile_npcs_on_respawns_at"
    t.index ["zone", "x", "y"], name: "index_tile_npcs_on_zone_and_x_and_y", unique: true
  end

  create_table "user_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "device_id", null: false
    t.datetime "last_seen_at"
    t.datetime "signed_in_at", null: false
    t.datetime "signed_out_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "device_id"], name: "index_user_sessions_on_user_id_and_device_id", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "chat_mute_reason"
    t.datetime "chat_muted_until"
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
    t.string "profile_name", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "suspended_until"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["profile_name"], name: "index_users_on_profile_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended_until"], name: "index_users_on_suspended_until"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "world_action_offers", force: :cascade do |t|
    t.datetime "accepted_at"
    t.string "action_key", null: false
    t.string "action_type", null: false
    t.bigint "character_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "error_message"
    t.datetime "expires_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.bigint "zone_id", null: false
    t.index ["action_key"], name: "index_world_action_offers_on_action_key", unique: true
    t.index ["character_id", "status", "expires_at"], name: "index_world_action_offers_on_character_status_expires"
    t.index ["character_id", "zone_id", "x", "y", "action_type", "status"], name: "index_world_action_offers_on_character_tile_action_status"
    t.index ["character_id"], name: "index_world_action_offers_on_character_id"
    t.index ["target_type", "target_id"], name: "index_world_action_offers_on_target"
    t.index ["zone_id"], name: "index_world_action_offers_on_zone_id"
  end

  create_table "zones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "height", default: 32, null: false
    t.string "location_type", default: "outdoor", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "turn_counter", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "width", default: 32, null: false
    t.index ["name"], name: "index_zones_on_name", unique: true
  end

  add_foreign_key "arena_applications", "arena_applications", column: "matched_with_id"
  add_foreign_key "arena_applications", "arena_matches"
  add_foreign_key "arena_applications", "arena_rooms"
  add_foreign_key "arena_applications", "characters", column: "applicant_id"
  add_foreign_key "arena_applications", "npc_templates"
  add_foreign_key "arena_matches", "arena_rooms"
  add_foreign_key "arena_matches", "zones"
  add_foreign_key "arena_participations", "arena_matches"
  add_foreign_key "arena_participations", "characters"
  add_foreign_key "arena_participations", "npc_templates"
  add_foreign_key "arena_participations", "users"
  add_foreign_key "arena_rooms", "zones"
  add_foreign_key "character_positions", "characters"
  add_foreign_key "character_positions", "zones"
  add_foreign_key "characters", "users"
  add_foreign_key "chat_channel_memberships", "chat_channels"
  add_foreign_key "chat_channel_memberships", "users"
  add_foreign_key "chat_channels", "users", column: "creator_id"
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "users", column: "sender_id"
  add_foreign_key "city_hotspots", "zones"
  add_foreign_key "city_hotspots", "zones", column: "destination_zone_id"
  add_foreign_key "combat_log_entries", "arena_matches"
  add_foreign_key "currency_transactions", "currency_wallets"
  add_foreign_key "currency_wallets", "users"
  add_foreign_key "ignore_list_entries", "users"
  add_foreign_key "ignore_list_entries", "users", column: "ignored_user_id"
  add_foreign_key "inventories", "characters"
  add_foreign_key "inventory_items", "inventories"
  add_foreign_key "inventory_items", "item_templates"
  add_foreign_key "movement_commands", "characters"
  add_foreign_key "movement_commands", "zones"
  add_foreign_key "spawn_points", "zones"
  add_foreign_key "tile_buildings", "zones", column: "destination_zone_id"
  add_foreign_key "tile_npcs", "characters", column: "defeated_by_id"
  add_foreign_key "tile_npcs", "npc_templates"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
  add_foreign_key "world_action_offers", "characters"
  add_foreign_key "world_action_offers", "zones"
end
