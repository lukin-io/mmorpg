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

ActiveRecord::Schema[8.1].define(version: 2025_12_18_155628) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "abilities", force: :cascade do |t|
    t.bigint "character_class_id", null: false
    t.jsonb "combo_tags", default: [], null: false
    t.integer "cooldown_seconds", default: 0, null: false
    t.datetime "created_at", null: false
    t.jsonb "effects", default: {}, null: false
    t.string "kind", default: "active", null: false
    t.string "name", null: false
    t.jsonb "resource_cost", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["character_class_id", "name"], name: "index_abilities_on_character_class_id_and_name", unique: true
    t.index ["character_class_id"], name: "index_abilities_on_character_class_id"
  end

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
    t.boolean "account_wide", default: true, null: false
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_priority", default: 0, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "points", default: 0, null: false
    t.jsonb "reward_payload", default: {}, null: false
    t.string "reward_type"
    t.jsonb "share_payload", default: {}, null: false
    t.bigint "title_reward_id"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_achievements_on_category"
    t.index ["display_priority"], name: "index_achievements_on_display_priority"
    t.index ["key"], name: "index_achievements_on_key", unique: true
    t.index ["title_reward_id"], name: "index_achievements_on_title_reward_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_announcements_on_created_at"
  end

  create_table "arena_applications", force: :cascade do |t|
    t.bigint "applicant_id", null: false
    t.bigint "arena_match_id"
    t.bigint "arena_room_id", null: false
    t.boolean "closed_fight", default: false, null: false
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
    t.index ["arena_room_id", "status"], name: "index_arena_applications_on_arena_room_id_and_status"
    t.index ["arena_room_id"], name: "index_arena_applications_on_arena_room_id"
    t.index ["fight_type"], name: "index_arena_applications_on_fight_type"
    t.index ["matched_with_id"], name: "index_arena_applications_on_matched_with_id"
    t.index ["status"], name: "index_arena_applications_on_status"
  end

  create_table "arena_bets", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "arena_match_id", null: false
    t.datetime "created_at", null: false
    t.integer "currency_type", default: 0, null: false
    t.integer "payout_amount", default: 0
    t.bigint "predicted_winner_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["arena_match_id", "status"], name: "index_arena_bets_on_arena_match_id_and_status"
    t.index ["arena_match_id"], name: "index_arena_bets_on_arena_match_id"
    t.index ["predicted_winner_id"], name: "index_arena_bets_on_predicted_winner_id"
    t.index ["user_id", "arena_match_id"], name: "index_arena_bets_on_user_id_and_arena_match_id", unique: true
    t.index ["user_id"], name: "index_arena_bets_on_user_id"
  end

  create_table "arena_matches", force: :cascade do |t|
    t.bigint "arena_room_id"
    t.bigint "arena_season_id"
    t.bigint "arena_tournament_id"
    t.string "bracket_position"
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "match_type", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "spectator_code"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "winning_team"
    t.bigint "zone_id"
    t.index ["arena_room_id"], name: "index_arena_matches_on_arena_room_id"
    t.index ["arena_season_id"], name: "index_arena_matches_on_arena_season_id"
    t.index ["arena_tournament_id"], name: "index_arena_matches_on_arena_tournament_id"
    t.index ["spectator_code"], name: "index_arena_matches_on_spectator_code", unique: true
    t.index ["status"], name: "index_arena_matches_on_status"
    t.index ["zone_id"], name: "index_arena_matches_on_zone_id"
  end

  create_table "arena_participations", force: :cascade do |t|
    t.bigint "arena_match_id", null: false
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.integer "rating_delta", default: 0, null: false
    t.integer "result", default: 0, null: false
    t.jsonb "reward_payload", default: {}, null: false
    t.string "team", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["arena_match_id", "character_id"], name: "index_arena_participants_on_match_and_character", unique: true
    t.index ["arena_match_id"], name: "index_arena_participations_on_arena_match_id"
    t.index ["character_id"], name: "index_arena_participations_on_character_id"
    t.index ["user_id"], name: "index_arena_participations_on_user_id"
  end

  create_table "arena_rankings", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "ladder_metadata", default: {}, null: false
    t.string "ladder_type", default: "arena", null: false
    t.integer "losses", default: 0, null: false
    t.integer "rating", default: 1200, null: false
    t.integer "streak", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "wins", default: 0, null: false
    t.index ["character_id", "ladder_type"], name: "index_arena_rankings_on_character_id_and_ladder_type", unique: true
  end

  create_table "arena_rooms", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "faction_restriction"
    t.integer "level_max", default: 100, null: false
    t.integer "level_min", default: 0, null: false
    t.integer "max_concurrent_matches", default: 10, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "room_type", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.index ["active"], name: "index_arena_rooms_on_active"
    t.index ["room_type"], name: "index_arena_rooms_on_room_type"
    t.index ["slug"], name: "index_arena_rooms_on_slug", unique: true
    t.index ["zone_id"], name: "index_arena_rooms_on_zone_id"
  end

  create_table "arena_seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_arena_seasons_on_slug", unique: true
  end

  create_table "arena_tournaments", force: :cascade do |t|
    t.string "announcer_npc_key"
    t.bigint "competition_bracket_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_instance_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["competition_bracket_id"], name: "index_arena_tournaments_on_competition_bracket_id"
    t.index ["event_instance_id"], name: "index_arena_tournaments_on_event_instance_id"
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
    t.string "commission_scope", default: "personal", null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.datetime "ends_at", null: false
    t.jsonb "item_metadata", default: {}, null: false
    t.string "item_name", null: false
    t.string "location_key", default: "capital", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "required_profession_id"
    t.integer "required_skill_level", default: 0, null: false
    t.bigint "seller_id", null: false
    t.integer "starting_bid", null: false
    t.integer "status", default: 0, null: false
    t.float "tax_rate", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["ends_at"], name: "index_auction_listings_on_ends_at"
    t.index ["required_profession_id"], name: "index_auction_listings_on_required_profession_id"
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

  create_table "battle_participants", force: :cascade do |t|
    t.integer "action_points_used", default: 0
    t.bigint "battle_id", null: false
    t.jsonb "body_damage", default: {"head" => 0, "legs" => 0, "torso" => 0, "stomach" => 0}
    t.jsonb "buffs", default: {}, null: false
    t.bigint "character_id"
    t.jsonb "combat_buffs", default: []
    t.datetime "created_at", null: false
    t.integer "current_hp", default: 100
    t.integer "current_mp", default: 50
    t.jsonb "damage_dealt", default: {"air" => 0, "fire" => 0, "earth" => 0, "total" => 0, "water" => 0, "normal" => 0}
    t.jsonb "damage_received", default: {"air" => 0, "fire" => 0, "earth" => 0, "total" => 0, "water" => 0, "normal" => 0}
    t.decimal "fatigue", precision: 5, scale: 2, default: "100.0"
    t.integer "hits_blocked", default: 0
    t.integer "hits_landed", default: 0
    t.integer "hp_remaining", default: 0, null: false
    t.integer "initiative", default: 0, null: false
    t.boolean "is_alive", default: true
    t.boolean "is_defending", default: false
    t.integer "mana_used", default: 0
    t.integer "max_hp", default: 100
    t.integer "max_mp", default: 50
    t.bigint "npc_template_id"
    t.string "participant_type", default: "player"
    t.jsonb "pending_attacks", default: []
    t.jsonb "pending_blocks", default: []
    t.jsonb "pending_skills", default: []
    t.string "role", default: "combatant", null: false
    t.jsonb "stat_snapshot", default: {}, null: false
    t.string "team", default: "alpha", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id", "is_alive"], name: "index_battle_participants_on_battle_id_and_is_alive"
    t.index ["battle_id"], name: "index_battle_participants_on_battle_id"
    t.index ["character_id"], name: "index_battle_participants_on_character_id"
    t.index ["npc_template_id"], name: "index_battle_participants_on_npc_template_id"
  end

  create_table "battles", force: :cascade do |t|
    t.integer "action_points_per_turn", default: 80
    t.boolean "allow_spectators", default: true, null: false
    t.integer "battle_type", default: 0, null: false
    t.string "combat_mode", default: "standard"
    t.datetime "created_at", null: false
    t.integer "current_turn_character_id"
    t.datetime "ended_at"
    t.jsonb "initiative_order", default: [], null: false
    t.bigint "initiator_id", null: false
    t.integer "max_mana_per_turn", default: 50
    t.jsonb "metadata", default: {}, null: false
    t.boolean "moderation_override", default: false, null: false
    t.string "pvp_mode"
    t.integer "round_number", default: 1
    t.string "share_token"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "turn_number", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.index ["initiator_id"], name: "index_battles_on_initiator_id"
    t.index ["share_token"], name: "index_battles_on_share_token", unique: true
    t.index ["status"], name: "index_battles_on_status"
    t.index ["zone_id"], name: "index_battles_on_zone_id"
  end

  create_table "character_classes", force: :cascade do |t|
    t.jsonb "base_stats", default: {}, null: false
    t.jsonb "combo_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.jsonb "equipment_tags", default: [], null: false
    t.string "name", null: false
    t.string "resource_type", default: "stamina", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_character_classes_on_name", unique: true
  end

  create_table "character_positions", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_action_at"
    t.integer "last_turn_number", default: 0, null: false
    t.datetime "respawn_available_at"
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.bigint "zone_id", null: false
    t.index ["character_id"], name: "index_character_positions_on_character_id", unique: true
    t.index ["zone_id", "x", "y"], name: "index_character_positions_on_zone_id_and_x_and_y"
    t.index ["zone_id"], name: "index_character_positions_on_zone_id"
  end

  create_table "character_skills", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.bigint "skill_node_id", null: false
    t.datetime "unlocked_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "skill_node_id"], name: "index_character_skills_on_character_id_and_skill_node_id", unique: true
    t.index ["character_id"], name: "index_character_skills_on_character_id"
    t.index ["skill_node_id"], name: "index_character_skills_on_skill_node_id"
  end

  create_table "characters", force: :cascade do |t|
    t.integer "alignment_score", default: 0, null: false
    t.jsonb "allocated_stats", default: {}, null: false
    t.integer "chaos_score", default: 0, null: false
    t.bigint "character_class_id"
    t.bigint "clan_id"
    t.datetime "created_at", null: false
    t.integer "current_hp", default: 100, null: false
    t.integer "current_mp", default: 50, null: false
    t.bigint "experience", default: 0, null: false
    t.string "faction_alignment", default: "neutral", null: false
    t.bigint "guild_id"
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
    t.jsonb "progression_sources", default: {}, null: false
    t.integer "reputation", default: 0, null: false
    t.jsonb "resource_pools", default: {}, null: false
    t.bigint "secondary_specialization_id"
    t.integer "skill_points_available", default: 0, null: false
    t.integer "stat_points_available", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["character_class_id"], name: "index_characters_on_character_class_id"
    t.index ["clan_id"], name: "index_characters_on_clan_id"
    t.index ["guild_id"], name: "index_characters_on_guild_id"
    t.index ["name"], name: "index_characters_on_name", unique: true
    t.index ["secondary_specialization_id"], name: "index_characters_on_secondary_specialization_id"
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
    t.jsonb "moderation_labels", default: [], null: false
    t.integer "reported_count", default: 0, null: false
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
    t.bigint "moderation_ticket_id"
    t.text "reason", null: false
    t.bigint "reporter_id", null: false
    t.jsonb "source_context", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["chat_message_id"], name: "index_chat_reports_on_chat_message_id"
    t.index ["moderation_ticket_id"], name: "index_chat_reports_on_moderation_ticket_id"
    t.index ["reporter_id"], name: "index_chat_reports_on_reporter_id"
    t.index ["status"], name: "index_chat_reports_on_status"
  end

  create_table "chat_violations", force: :cascade do |t|
    t.bigint "chat_message_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason"
    t.string "severity", null: false
    t.integer "severity_points", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "violation_type", null: false
    t.index ["chat_message_id"], name: "index_chat_violations_on_chat_message_id"
    t.index ["user_id", "created_at"], name: "index_chat_violations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_chat_violations_on_user_id"
    t.index ["violation_type"], name: "index_chat_violations_on_violation_type"
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

  create_table "clan_applications", force: :cascade do |t|
    t.bigint "applicant_id", null: false
    t.boolean "auto_accepted", default: false, null: false
    t.bigint "character_id"
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.text "decision_reason"
    t.bigint "referral_user_id"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.jsonb "vetting_answers", default: {}, null: false
    t.index ["applicant_id"], name: "index_clan_applications_on_applicant_id"
    t.index ["character_id"], name: "index_clan_applications_on_character_id"
    t.index ["clan_id"], name: "index_clan_applications_on_clan_id"
    t.index ["referral_user_id"], name: "index_clan_applications_on_referral_user_id"
    t.index ["reviewed_by_id"], name: "index_clan_applications_on_reviewed_by_id"
  end

  create_table "clan_log_entries", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_clan_log_entries_on_actor_id"
    t.index ["clan_id", "created_at"], name: "index_clan_log_entries_on_clan_id_and_created_at"
    t.index ["clan_id"], name: "index_clan_log_entries_on_clan_id"
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

  create_table "clan_message_board_posts", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "broadcasted_at"
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_clan_message_board_posts_on_author_id"
    t.index ["clan_id", "pinned"], name: "index_clan_message_board_posts_on_clan_id_and_pinned"
    t.index ["clan_id"], name: "index_clan_message_board_posts_on_clan_id"
  end

  create_table "clan_moderation_actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.bigint "gm_user_id", null: false
    t.text "notes"
    t.datetime "rolled_back_at"
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["clan_id"], name: "index_clan_moderation_actions_on_clan_id"
    t.index ["gm_user_id"], name: "index_clan_moderation_actions_on_gm_user_id"
    t.index ["target_type", "target_id"], name: "index_clan_moderation_actions_on_target"
  end

  create_table "clan_quest_contributions", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.bigint "character_id", null: false
    t.bigint "clan_quest_id", null: false
    t.string "contribution_type", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_clan_quest_contributions_on_character_id"
    t.index ["clan_quest_id"], name: "index_clan_quest_contributions_on_clan_quest_id"
  end

  create_table "clan_quests", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.jsonb "progress", default: {}, null: false
    t.bigint "quest_id"
    t.string "quest_key", null: false
    t.jsonb "requirements", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id", "quest_key"], name: "index_clan_quests_on_clan_id_and_quest_key", unique: true
    t.index ["clan_id"], name: "index_clan_quests_on_clan_id"
    t.index ["quest_id"], name: "index_clan_quests_on_quest_id"
  end

  create_table "clan_research_projects", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "progress", default: {}, null: false
    t.string "project_key", null: false
    t.jsonb "requirements", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.jsonb "unlocks_payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id", "project_key"], name: "index_clan_research_projects_on_clan_and_key", unique: true
    t.index ["clan_id"], name: "index_clan_research_projects_on_clan_id"
  end

  create_table "clan_role_permissions", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "permission_key", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id", "role", "permission_key"], name: "index_clan_role_permissions_on_role_and_permission", unique: true
    t.index ["clan_id"], name: "index_clan_role_permissions_on_clan_id"
  end

  create_table "clan_stronghold_upgrades", force: :cascade do |t|
    t.bigint "clan_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "progress", default: {}, null: false
    t.jsonb "requirements", default: {}, null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "upgrade_key", null: false
    t.index ["clan_id", "upgrade_key"], name: "index_clan_stronghold_upgrades_on_clan_and_key", unique: true
    t.index ["clan_id"], name: "index_clan_stronghold_upgrades_on_clan_id"
  end

  create_table "clan_territories", force: :cascade do |t|
    t.jsonb "benefits", default: {}, null: false
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.string "exclusive_dungeon_key"
    t.string "fast_travel_node_key"
    t.datetime "last_claimed_at"
    t.integer "tax_rate_basis_points", default: 0, null: false
    t.string "territory_key", null: false
    t.datetime "updated_at", null: false
    t.string "world_region_key"
    t.index ["clan_id"], name: "index_clan_territories_on_clan_id"
    t.index ["territory_key"], name: "index_clan_territories_on_territory_key", unique: true
  end

  create_table "clan_treasury_transactions", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.integer "amount", null: false
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_clan_treasury_transactions_on_actor_id"
    t.index ["clan_id"], name: "index_clan_treasury_transactions_on_clan_id"
  end

  create_table "clan_wars", force: :cascade do |t|
    t.bigint "attacker_clan_id", null: false
    t.bigint "battle_id"
    t.datetime "created_at", null: false
    t.datetime "declaration_made_at"
    t.bigint "defender_clan_id", null: false
    t.datetime "preparation_begins_at"
    t.datetime "resolved_at"
    t.jsonb "result_payload", default: {}, null: false
    t.datetime "scheduled_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "support_objectives", default: [], null: false
    t.string "territory_key", null: false
    t.datetime "updated_at", null: false
    t.index ["attacker_clan_id", "defender_clan_id", "territory_key"], name: "index_clan_wars_on_participants_and_territory"
    t.index ["attacker_clan_id"], name: "index_clan_wars_on_attacker_clan_id"
    t.index ["battle_id"], name: "index_clan_wars_on_battle_id"
    t.index ["defender_clan_id"], name: "index_clan_wars_on_defender_clan_id"
  end

  create_table "clan_xp_events", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "clan_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "recorded_at", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["clan_id"], name: "index_clan_xp_events_on_clan_id"
  end

  create_table "clans", force: :cascade do |t|
    t.jsonb "banner_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "discord_webhook_url"
    t.integer "experience", default: 0, null: false
    t.jsonb "fast_travel_nodes", default: [], null: false
    t.jsonb "infrastructure_state", default: {}, null: false
    t.bigint "leader_id", null: false
    t.integer "level", default: 1, null: false
    t.string "name", null: false
    t.integer "prestige", default: 0, null: false
    t.jsonb "recruitment_settings", default: {}, null: false
    t.string "slug", null: false
    t.integer "treasury_gold", default: 0, null: false
    t.integer "treasury_premium_tokens", default: 0, null: false
    t.jsonb "treasury_rules", default: {}, null: false
    t.integer "treasury_silver", default: 0, null: false
    t.jsonb "unlocked_buffs", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["leader_id"], name: "index_clans_on_leader_id"
    t.index ["slug"], name: "index_clans_on_slug", unique: true
  end

  create_table "class_specializations", force: :cascade do |t|
    t.bigint "character_class_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.jsonb "unlock_requirements", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["character_class_id", "name"], name: "index_class_specializations_on_character_class_id_and_name", unique: true
    t.index ["character_class_id"], name: "index_class_specializations_on_character_class_id"
  end

  create_table "combat_analytics_reports", force: :cascade do |t|
    t.bigint "battle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "generated_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id"], name: "index_combat_analytics_reports_on_battle_id"
    t.index ["generated_at"], name: "index_combat_analytics_reports_on_generated_at"
  end

  create_table "combat_log_entries", force: :cascade do |t|
    t.bigint "ability_id"
    t.bigint "actor_id"
    t.string "actor_type"
    t.bigint "battle_id", null: false
    t.datetime "created_at", null: false
    t.integer "damage_amount", default: 0, null: false
    t.integer "healing_amount", default: 0, null: false
    t.string "log_type", default: "action"
    t.text "message", null: false
    t.jsonb "payload", default: {}, null: false
    t.integer "round_number", default: 1, null: false
    t.integer "sequence", default: 1, null: false
    t.string "tags", default: [], array: true
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["ability_id"], name: "index_combat_log_entries_on_ability_id"
    t.index ["actor_id"], name: "index_combat_log_entries_on_actor_id"
    t.index ["battle_id", "round_number"], name: "index_combat_log_entries_on_battle_id_and_round_number"
    t.index ["battle_id"], name: "index_combat_log_entries_on_battle_id"
    t.index ["log_type"], name: "index_combat_log_entries_on_log_type"
    t.index ["tags"], name: "index_combat_log_entries_on_tags", using: :gin
    t.index ["target_id"], name: "index_combat_log_entries_on_target_id"
  end

  create_table "community_objectives", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_amount", default: 0, null: false
    t.bigint "event_instance_id", null: false
    t.integer "goal_amount", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "resource_key", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["event_instance_id", "resource_key"], name: "index_objectives_on_event_and_resource"
    t.index ["event_instance_id"], name: "index_community_objectives_on_event_instance_id"
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
    t.integer "batch_quantity", default: 1, null: false
    t.bigint "character_id", null: false
    t.datetime "completes_at", null: false
    t.bigint "crafting_station_id", null: false
    t.datetime "created_at", null: false
    t.boolean "portable_penalty_applied", default: false, null: false
    t.integer "quality_score", default: 0, null: false
    t.string "quality_tier", default: "common", null: false
    t.bigint "recipe_id", null: false
    t.jsonb "result_payload", default: {}, null: false
    t.datetime "started_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "success_chance", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["character_id", "status"], name: "index_crafting_jobs_on_character_id_and_status"
    t.index ["character_id"], name: "index_crafting_jobs_on_character_id"
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
    t.boolean "portable", default: false, null: false
    t.string "station_archetype", default: "city", null: false
    t.string "station_type", null: false
    t.integer "success_penalty", default: 0, null: false
    t.decimal "time_penalty_multiplier", precision: 5, scale: 2, default: "1.0", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currency_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "balance_after", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.bigint "currency_wallet_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_currency_transactions_on_created_at"
    t.index ["currency_type", "created_at"], name: "index_currency_transactions_on_type_and_created_at"
    t.index ["currency_wallet_id"], name: "index_currency_transactions_on_currency_wallet_id"
  end

  create_table "currency_wallets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "gold_balance", default: 0, null: false
    t.integer "gold_soft_cap", default: 2000000, null: false
    t.integer "premium_tokens_balance", default: 0, null: false
    t.integer "premium_tokens_soft_cap", default: 5000, null: false
    t.integer "silver_balance", default: 0, null: false
    t.integer "silver_soft_cap", default: 150000, null: false
    t.jsonb "sink_totals", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_currency_wallets_on_user_id", unique: true
  end

  create_table "cutscene_events", force: :cascade do |t|
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "quest_id"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_cutscene_events_on_key", unique: true
    t.index ["quest_id"], name: "index_cutscene_events_on_quest_id"
  end

  create_table "dungeon_encounters", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.decimal "difficulty_modifier", precision: 4, scale: 2, default: "1.0"
    t.bigint "dungeon_instance_id", null: false
    t.integer "encounter_index", null: false
    t.integer "encounter_template_id"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["dungeon_instance_id", "encounter_index"], name: "idx_encounters_on_instance_and_index", unique: true
    t.index ["dungeon_instance_id"], name: "index_dungeon_encounters_on_dungeon_instance_id"
  end

  create_table "dungeon_instances", force: :cascade do |t|
    t.integer "attempts_remaining", default: 3
    t.integer "completion_time_seconds"
    t.datetime "created_at", null: false
    t.integer "current_encounter_index", default: 0
    t.integer "difficulty", default: 1, null: false
    t.bigint "dungeon_template_id", null: false
    t.datetime "ended_at"
    t.datetime "expires_at"
    t.string "instance_key", null: false
    t.bigint "leader_id", null: false
    t.bigint "party_id", null: false
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["dungeon_template_id"], name: "index_dungeon_instances_on_dungeon_template_id"
    t.index ["instance_key"], name: "index_dungeon_instances_on_instance_key", unique: true
    t.index ["leader_id"], name: "index_dungeon_instances_on_leader_id"
    t.index ["party_id", "status"], name: "index_dungeon_instances_on_party_id_and_status"
    t.index ["party_id"], name: "index_dungeon_instances_on_party_id"
  end

  create_table "dungeon_progress_checkpoints", force: :cascade do |t|
    t.integer "checkpoint_index", null: false
    t.datetime "created_at", null: false
    t.bigint "dungeon_instance_id", null: false
    t.integer "encounter_index", null: false
    t.jsonb "party_state", default: []
    t.datetime "updated_at", null: false
    t.index ["dungeon_instance_id", "checkpoint_index"], name: "idx_checkpoints_on_instance_and_index", unique: true
    t.index ["dungeon_instance_id"], name: "index_dungeon_progress_checkpoints_on_dungeon_instance_id"
  end

  create_table "dungeon_templates", force: :cascade do |t|
    t.string "biome"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", default: 120, null: false
    t.jsonb "encounters", default: [], null: false
    t.string "key", null: false
    t.integer "max_level", default: 100, null: false
    t.integer "max_party_size", default: 5, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "min_level", default: 1, null: false
    t.integer "min_party_size", default: 1, null: false
    t.string "name", null: false
    t.jsonb "rewards", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_dungeon_templates_on_key", unique: true
    t.index ["min_level", "max_level"], name: "index_dungeon_templates_on_min_level_and_max_level"
  end

  create_table "economic_snapshots", force: :cascade do |t|
    t.integer "active_listings", default: 0, null: false
    t.date "captured_on", null: false
    t.datetime "created_at", null: false
    t.decimal "currency_velocity_gold", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "currency_velocity_premium_tokens", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "currency_velocity_silver", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "daily_trade_volume_gold", default: 0, null: false
    t.integer "daily_trade_volume_premium_tokens", default: 0, null: false
    t.jsonb "item_price_index", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "suspicious_trade_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["captured_on"], name: "index_economic_snapshots_on_captured_on", unique: true
  end

  create_table "economy_alerts", force: :cascade do |t|
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.datetime "flagged_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "open", null: false
    t.bigint "trade_session_id"
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_economy_alerts_on_status"
    t.index ["trade_session_id"], name: "index_economy_alerts_on_trade_session_id"
  end

  create_table "event_instances", force: :cascade do |t|
    t.string "announcer_npc_key"
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.bigint "game_event_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "temporary_npc_keys", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["game_event_id", "starts_at"], name: "index_event_instances_on_game_event_id_and_starts_at"
    t.index ["game_event_id"], name: "index_event_instances_on_game_event_id"
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

  create_table "game_overview_snapshots", force: :cascade do |t|
    t.integer "active_clans_7d", default: 0, null: false
    t.integer "active_guilds_7d", default: 0, null: false
    t.decimal "avg_tokens_per_paying_user", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "captured_at", null: false
    t.integer "chat_senders_7d", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "daily_returning_players", default: 0, null: false
    t.integer "premium_purchases_30d", default: 0, null: false
    t.integer "seasonal_events_active", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "weekly_returning_players", default: 0, null: false
    t.decimal "whale_share_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["captured_at"], name: "index_game_overview_snapshots_on_captured_at", unique: true
  end

  create_table "gathering_nodes", force: :cascade do |t|
    t.boolean "contested", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "difficulty", default: 1, null: false
    t.integer "group_bonus_percent", default: 0, null: false
    t.datetime "last_harvested_at"
    t.datetime "next_available_at"
    t.bigint "profession_id", null: false
    t.string "rarity_tier", default: "common", null: false
    t.string "resource_key", null: false
    t.integer "respawn_seconds", default: 60, null: false
    t.jsonb "rewards", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["profession_id", "resource_key"], name: "index_gathering_nodes_on_profession_id_and_resource_key"
    t.index ["profession_id"], name: "index_gathering_nodes_on_profession_id"
    t.index ["zone_id"], name: "index_gathering_nodes_on_zone_id"
  end

  create_table "group_listings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "guild_id"
    t.integer "listing_type", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "owner_id", null: false
    t.bigint "party_id"
    t.bigint "profession_id"
    t.jsonb "requirements", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id"], name: "index_group_listings_on_guild_id"
    t.index ["listing_type"], name: "index_group_listings_on_listing_type"
    t.index ["owner_id"], name: "index_group_listings_on_owner_id"
    t.index ["party_id"], name: "index_group_listings_on_party_id"
    t.index ["profession_id"], name: "index_group_listings_on_profession_id"
    t.index ["status"], name: "index_group_listings_on_status"
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

  create_table "guild_bulletins", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_guild_bulletins_on_author_id"
    t.index ["guild_id", "pinned"], name: "index_guild_bulletins_on_guild_id_and_pinned"
    t.index ["guild_id"], name: "index_guild_bulletins_on_guild_id"
  end

  create_table "guild_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.bigint "guild_rank_id"
    t.datetime "joined_at"
    t.jsonb "permissions", default: {}, null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["guild_id", "user_id"], name: "index_guild_memberships_on_guild_id_and_user_id", unique: true
    t.index ["guild_id"], name: "index_guild_memberships_on_guild_id"
    t.index ["guild_rank_id"], name: "index_guild_memberships_on_guild_rank_id"
    t.index ["user_id"], name: "index_guild_memberships_on_user_id"
  end

  create_table "guild_missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "progress_quantity", default: 0, null: false
    t.string "required_item_name", null: false
    t.bigint "required_profession_id", null: false
    t.integer "required_quantity", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "status"], name: "index_guild_missions_on_guild_id_and_status"
    t.index ["guild_id"], name: "index_guild_missions_on_guild_id"
    t.index ["required_profession_id"], name: "index_guild_missions_on_required_profession_id"
  end

  create_table "guild_perks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "granted_by_id"
    t.bigint "guild_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "perk_key", null: false
    t.integer "source_level", default: 1, null: false
    t.datetime "unlocked_at", null: false
    t.datetime "updated_at", null: false
    t.index ["granted_by_id"], name: "index_guild_perks_on_granted_by_id"
    t.index ["guild_id", "perk_key"], name: "index_guild_perks_on_guild_id_and_perk_key", unique: true
    t.index ["guild_id"], name: "index_guild_perks_on_guild_id"
  end

  create_table "guild_ranks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "guild_id", null: false
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "name"], name: "index_guild_ranks_on_guild_id_and_name", unique: true
    t.index ["guild_id"], name: "index_guild_ranks_on_guild_id"
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
    t.string "decor_type", default: "furniture", null: false
    t.bigint "housing_plot_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.jsonb "placement", default: {}, null: false
    t.boolean "trophy", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "utility_slot"
    t.index ["decor_type"], name: "index_housing_decor_items_on_decor_type"
    t.index ["housing_plot_id"], name: "index_housing_decor_items_on_housing_plot_id"
  end

  create_table "housing_plots", force: :cascade do |t|
    t.jsonb "access_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "exterior_style", default: "classic", null: false
    t.string "location_key", null: false
    t.datetime "next_upkeep_due_at"
    t.string "plot_tier", default: "starter", null: false
    t.string "plot_type", null: false
    t.integer "room_slots", default: 1, null: false
    t.boolean "showcase_enabled", default: false, null: false
    t.integer "storage_slots", default: 20, null: false
    t.datetime "updated_at", null: false
    t.integer "upkeep_gold_cost", default: 200, null: false
    t.bigint "user_id", null: false
    t.integer "utility_slots", default: 1, null: false
    t.bigint "visit_guild_id"
    t.string "visit_scope", default: "friends", null: false
    t.index ["plot_tier"], name: "index_housing_plots_on_plot_tier"
    t.index ["user_id"], name: "index_housing_plots_on_user_id"
    t.index ["visit_guild_id"], name: "index_housing_plots_on_visit_guild_id"
    t.index ["visit_scope"], name: "index_housing_plots_on_visit_scope"
  end

  create_table "ignore_list_entries", force: :cascade do |t|
    t.string "context"
    t.datetime "created_at", null: false
    t.bigint "ignored_user_id", null: false
    t.string "notes"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["ignored_user_id"], name: "index_ignore_list_entries_on_ignored_user_id"
    t.index ["user_id", "ignored_user_id"], name: "index_ignore_entries_on_user_and_target", unique: true
    t.index ["user_id"], name: "index_ignore_list_entries_on_user_id"
  end

  create_table "integration_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "last_used_at"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "scopes", default: [], array: true
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_integration_tokens_on_created_by_id"
    t.index ["token"], name: "index_integration_tokens_on_token", unique: true
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
    t.boolean "premium", default: false, null: false
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

  create_table "item_price_points", force: :cascade do |t|
    t.integer "average_price", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency_type", null: false
    t.string "item_name", null: false
    t.integer "median_price", default: 0, null: false
    t.date "sampled_on", null: false
    t.datetime "updated_at", null: false
    t.integer "volume", default: 0, null: false
    t.index ["item_name", "sampled_on", "currency_type"], name: "index_item_price_points_on_item_and_sample"
  end

  create_table "item_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "enhancement_rules", default: {}, null: false
    t.string "item_type", default: "equipment"
    t.string "key"
    t.string "name", null: false
    t.boolean "premium", default: false, null: false
    t.string "rarity", null: false
    t.string "slot", null: false
    t.integer "stack_limit", default: 99, null: false
    t.jsonb "stat_modifiers", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 1, null: false
    t.index ["item_type"], name: "index_item_templates_on_item_type"
    t.index ["key"], name: "index_item_templates_on_key", unique: true
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

  create_table "live_ops_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "executed_at"
    t.text "notes"
    t.jsonb "payload", default: {}, null: false
    t.bigint "requested_by_id", null: false
    t.string "severity", default: "normal", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_live_ops_events_on_event_type"
    t.index ["requested_by_id"], name: "index_live_ops_events_on_requested_by_id"
    t.index ["severity"], name: "index_live_ops_events_on_severity"
    t.index ["status"], name: "index_live_ops_events_on_status"
  end

  create_table "mail_messages", force: :cascade do |t|
    t.jsonb "attachment_payload", default: {}, null: false
    t.datetime "attachments_claimed_at"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "delivered_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "origin_metadata", default: {}, null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.string "subject", null: false
    t.boolean "system_notification", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_id", "delivered_at"], name: "index_mail_messages_on_recipient_id_and_delivered_at"
    t.index ["recipient_id"], name: "index_mail_messages_on_recipient_id"
    t.index ["sender_id"], name: "index_mail_messages_on_sender_id"
  end

  create_table "map_tile_templates", force: :cascade do |t|
    t.string "biome", default: "plains", null: false
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

  create_table "market_demand_signals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "item_name", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "profession_id"
    t.integer "quantity", default: 0, null: false
    t.datetime "recorded_at", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.index ["item_name"], name: "index_market_demand_signals_on_item_name"
    t.index ["profession_id"], name: "index_market_demand_signals_on_profession_id"
    t.index ["recorded_at"], name: "index_market_demand_signals_on_recorded_at"
    t.index ["zone_id"], name: "index_market_demand_signals_on_zone_id"
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

  create_table "medical_supply_pools", force: :cascade do |t|
    t.integer "available_quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "item_name", null: false
    t.datetime "last_restocked_at"
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["zone_id", "item_name"], name: "index_medical_supply_pools_on_zone_and_item", unique: true
    t.index ["zone_id"], name: "index_medical_supply_pools_on_zone_id"
  end

  create_table "moderation_actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "actor_id", null: false
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.integer "duration_seconds"
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}, null: false
    t.text "reason", null: false
    t.bigint "target_character_id"
    t.bigint "target_user_id"
    t.bigint "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_moderation_actions_on_action_type"
    t.index ["actor_id"], name: "index_moderation_actions_on_actor_id"
    t.index ["expires_at"], name: "index_moderation_actions_on_expires_at"
    t.index ["target_character_id"], name: "index_moderation_actions_on_target_character_id"
    t.index ["target_user_id"], name: "index_moderation_actions_on_target_user_id"
    t.index ["ticket_id"], name: "index_moderation_actions_on_ticket_id"
  end

  create_table "moderation_appeals", force: :cascade do |t|
    t.bigint "appellant_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.text "resolution_notes"
    t.bigint "reviewer_id"
    t.datetime "sla_due_at"
    t.string "status", default: "submitted", null: false
    t.bigint "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["appellant_id"], name: "index_moderation_appeals_on_appellant_id"
    t.index ["reviewer_id"], name: "index_moderation_appeals_on_reviewer_id"
    t.index ["sla_due_at"], name: "index_moderation_appeals_on_sla_due_at"
    t.index ["status"], name: "index_moderation_appeals_on_status"
    t.index ["ticket_id"], name: "index_moderation_appeals_on_ticket_id"
  end

  create_table "moderation_tickets", force: :cascade do |t|
    t.string "appeal_status", default: "not_requested", null: false
    t.bigint "assigned_moderator_id"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.jsonb "evidence", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "origin_reference"
    t.datetime "penalty_expires_at"
    t.string "penalty_state", default: "none", null: false
    t.string "policy_key"
    t.text "policy_summary"
    t.string "priority", default: "normal", null: false
    t.bigint "reporter_id", null: false
    t.datetime "resolved_at"
    t.datetime "responded_at"
    t.string "source", null: false
    t.string "status", default: "open", null: false
    t.bigint "subject_character_id"
    t.bigint "subject_user_id"
    t.datetime "updated_at", null: false
    t.string "zone_key"
    t.index ["appeal_status"], name: "index_moderation_tickets_on_appeal_status"
    t.index ["assigned_moderator_id"], name: "index_moderation_tickets_on_assigned_moderator_id"
    t.index ["category"], name: "index_moderation_tickets_on_category"
    t.index ["created_at"], name: "index_moderation_tickets_on_created_at"
    t.index ["penalty_state"], name: "index_moderation_tickets_on_penalty_state"
    t.index ["policy_key"], name: "index_moderation_tickets_on_policy_key"
    t.index ["priority"], name: "index_moderation_tickets_on_priority"
    t.index ["reporter_id"], name: "index_moderation_tickets_on_reporter_id"
    t.index ["status"], name: "index_moderation_tickets_on_status"
    t.index ["subject_character_id"], name: "index_moderation_tickets_on_subject_character_id"
    t.index ["subject_user_id"], name: "index_moderation_tickets_on_subject_user_id"
    t.index ["zone_key"], name: "index_moderation_tickets_on_zone_key"
  end

  create_table "mount_stable_slots", force: :cascade do |t|
    t.jsonb "cosmetics", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "current_mount_id"
    t.integer "slot_index", null: false
    t.string "status", default: "locked", null: false
    t.datetime "unlocked_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["current_mount_id"], name: "index_mount_stable_slots_on_current_mount_id"
    t.index ["user_id", "slot_index"], name: "index_mount_stable_slots_on_user_id_and_slot_index", unique: true
    t.index ["user_id"], name: "index_mount_stable_slots_on_user_id"
  end

  create_table "mounts", force: :cascade do |t|
    t.jsonb "appearance", default: {}, null: false
    t.string "cosmetic_variant", default: "default", null: false
    t.datetime "created_at", null: false
    t.string "faction_key", default: "neutral", null: false
    t.bigint "mount_stable_slot_id"
    t.string "mount_type", null: false
    t.string "name", null: false
    t.string "rarity", default: "common", null: false
    t.integer "speed_bonus", default: 0, null: false
    t.string "summon_state", default: "stabled", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["faction_key"], name: "index_mounts_on_faction_key"
    t.index ["mount_stable_slot_id"], name: "index_mounts_on_mount_stable_slot_id"
    t.index ["rarity"], name: "index_mounts_on_rarity"
    t.index ["user_id"], name: "index_mounts_on_user_id"
  end

  create_table "movement_commands", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.string "error_message"
    t.integer "latency_ms", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "predicted_x"
    t.integer "predicted_y"
    t.datetime "processed_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["character_id"], name: "index_movement_commands_on_character_id"
    t.index ["created_at"], name: "index_movement_commands_on_created_at"
    t.index ["status"], name: "index_movement_commands_on_status"
    t.index ["zone_id"], name: "index_movement_commands_on_zone_id"
  end

  create_table "npc_reports", force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.bigint "character_id"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.jsonb "evidence", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "moderation_ticket_id"
    t.string "npc_key", null: false
    t.bigint "reporter_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_npc_reports_on_character_id"
    t.index ["moderation_ticket_id"], name: "index_npc_reports_on_moderation_ticket_id"
    t.index ["npc_key", "status"], name: "index_npc_reports_on_npc_key_and_status"
    t.index ["reporter_id"], name: "index_npc_reports_on_reporter_id"
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

  create_table "parties", force: :cascade do |t|
    t.jsonb "activity_metadata", default: {}, null: false
    t.bigint "chat_channel_id"
    t.datetime "created_at", null: false
    t.bigint "leader_id", null: false
    t.integer "max_size", default: 5, null: false
    t.string "name", null: false
    t.text "purpose"
    t.datetime "ready_check_started_at"
    t.integer "ready_check_state", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["chat_channel_id"], name: "index_parties_on_chat_channel_id"
    t.index ["leader_id"], name: "index_parties_on_leader_id"
    t.index ["status"], name: "index_parties_on_status"
  end

  create_table "party_invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "party_id", null: false
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["party_id"], name: "index_party_invitations_on_party_id"
    t.index ["recipient_id"], name: "index_party_invitations_on_recipient_id"
    t.index ["sender_id"], name: "index_party_invitations_on_sender_id"
    t.index ["token"], name: "index_party_invitations_on_token", unique: true
  end

  create_table "party_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.bigint "party_id", null: false
    t.integer "ready_state", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["party_id", "user_id"], name: "index_party_memberships_on_party_id_and_user_id", unique: true
    t.index ["party_id"], name: "index_party_memberships_on_party_id"
    t.index ["user_id"], name: "index_party_memberships_on_user_id"
  end

  create_table "pet_companions", force: :cascade do |t|
    t.string "affinity_stage", default: "neutral", null: false
    t.integer "bonding_experience", default: 0, null: false
    t.jsonb "care_state", default: {}, null: false
    t.datetime "care_task_available_at"
    t.datetime "created_at", null: false
    t.integer "gathering_bonus", default: 0, null: false
    t.datetime "last_care_performed_at"
    t.integer "level", default: 1, null: false
    t.string "nickname"
    t.string "passive_bonus_type"
    t.integer "passive_bonus_value", default: 0, null: false
    t.bigint "pet_species_id", null: false
    t.jsonb "stats", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["affinity_stage"], name: "index_pet_companions_on_affinity_stage"
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
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.bigint "equipped_tool_id"
    t.bigint "experience", default: 0, null: false
    t.integer "mastery_tier", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "profession_id", null: false
    t.integer "skill_level", default: 1, null: false
    t.string "slot_kind", default: "primary", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["character_id", "profession_id"], name: "idx_profession_progresses_on_character_and_profession", unique: true
    t.index ["character_id"], name: "index_profession_progresses_on_character_id"
    t.index ["equipped_tool_id"], name: "index_profession_progresses_on_equipped_tool_id"
    t.index ["profession_id"], name: "index_profession_progresses_on_profession_id"
    t.index ["user_id", "profession_id"], name: "index_profession_progresses_on_user_and_profession", unique: true
    t.index ["user_id"], name: "index_profession_progresses_on_user_id"
  end

  create_table "profession_tools", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "durability", default: 100, null: false
    t.boolean "equipped", default: true, null: false
    t.integer "max_durability", default: 100, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "profession_id", null: false
    t.integer "quality_rating", default: 0, null: false
    t.string "tool_type", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "tool_type"], name: "index_profession_tools_on_character_id_and_tool_type"
    t.index ["character_id"], name: "index_profession_tools_on_character_id"
    t.index ["profession_id"], name: "index_profession_tools_on_profession_id"
  end

  create_table "professions", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "gathering", default: false, null: false
    t.string "gathering_resource"
    t.integer "healing_bonus", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
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

  create_table "quest_analytics_snapshots", force: :cascade do |t|
    t.decimal "abandon_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.integer "avg_completion_minutes", default: 0, null: false
    t.string "bottleneck_step_key"
    t.integer "bottleneck_step_position"
    t.date "captured_on", null: false
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "quest_chain_key", null: false
    t.datetime "updated_at", null: false
    t.index ["captured_on", "quest_chain_key"], name: "index_quest_analytics_snapshots_on_date_and_chain", unique: true
  end

  create_table "quest_assignments", force: :cascade do |t|
    t.string "abandon_reason"
    t.datetime "abandoned_at"
    t.bigint "character_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "next_available_at"
    t.jsonb "progress", default: {}, null: false
    t.bigint "quest_id", null: false
    t.datetime "rewards_claimed_at"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_quest_assignments_on_character_id"
    t.index ["quest_id", "character_id"], name: "index_quest_assignments_on_quest_id_and_character_id", unique: true
    t.index ["quest_id"], name: "index_quest_assignments_on_quest_id"
  end

  create_table "quest_chains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_quest_chains_on_key", unique: true
  end

  create_table "quest_chapters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "faction_alignment"
    t.string "key", null: false
    t.integer "level_gate", default: 1, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "position", default: 1, null: false
    t.bigint "quest_chain_id", null: false
    t.integer "reputation_gate", default: 0, null: false
    t.text "synopsis"
    t.string "title", null: false
    t.string "unlock_cutscene_key"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_quest_chapters_on_key", unique: true
    t.index ["quest_chain_id", "position"], name: "index_quest_chapters_on_quest_chain_id_and_position", unique: true
    t.index ["quest_chain_id"], name: "index_quest_chapters_on_quest_chain_id"
  end

  create_table "quest_objectives", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "objective_type", null: false
    t.boolean "optional", default: false, null: false
    t.integer "position", default: 1, null: false
    t.bigint "quest_id", null: false
    t.jsonb "requirements", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["quest_id"], name: "index_quest_objectives_on_quest_id"
  end

  create_table "quest_steps", force: :cascade do |t|
    t.jsonb "branching_outcomes", default: {}, null: false
    t.jsonb "content", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "npc_key"
    t.integer "position", default: 1, null: false
    t.bigint "quest_id", null: false
    t.boolean "requires_confirmation", default: false, null: false
    t.string "step_type", null: false
    t.datetime "updated_at", null: false
    t.index ["quest_id", "position"], name: "index_quest_steps_on_quest_id_and_position", unique: true
    t.index ["quest_id"], name: "index_quest_steps_on_quest_id"
  end

  create_table "quests", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "chapter", default: 1, null: false
    t.integer "cooldown_seconds", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "daily_reset_slot"
    t.integer "difficulty_tier", default: 0, null: false
    t.jsonb "failure_consequence", default: {}, null: false
    t.string "key", null: false
    t.jsonb "map_overlays", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "min_level", default: 1, null: false
    t.integer "min_reputation", default: 0, null: false
    t.bigint "quest_chain_id"
    t.bigint "quest_chapter_id"
    t.integer "quest_type", default: 0, null: false
    t.integer "recommended_party_size", default: 1, null: false
    t.boolean "repeatable", default: false, null: false
    t.jsonb "requirements", default: {}, null: false
    t.jsonb "rewards", default: {}, null: false
    t.integer "sequence", default: 1, null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["difficulty_tier"], name: "index_quests_on_difficulty_tier"
    t.index ["key"], name: "index_quests_on_key", unique: true
    t.index ["min_level"], name: "index_quests_on_min_level"
    t.index ["quest_chain_id", "sequence"], name: "index_quests_on_quest_chain_id_and_sequence"
    t.index ["quest_chain_id"], name: "index_quests_on_quest_chain_id"
    t.index ["quest_chapter_id"], name: "index_quests_on_quest_chapter_id"
    t.index ["recommended_party_size"], name: "index_quests_on_recommended_party_size"
  end

  create_table "recipes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_seconds", default: 60, null: false
    t.boolean "guild_bound", default: false, null: false
    t.string "name", null: false
    t.string "output_item_name", null: false
    t.integer "premium_token_cost", default: 0, null: false
    t.bigint "profession_id", null: false
    t.jsonb "quality_modifiers", default: {}, null: false
    t.string "required_station_archetype", default: "city", null: false
    t.jsonb "requirements", default: {}, null: false
    t.jsonb "rewards", default: {}, null: false
    t.string "risk_level", default: "safe", null: false
    t.string "source_kind", default: "quest", null: false
    t.string "source_reference"
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

  create_table "skill_nodes", force: :cascade do |t|
    t.integer "cooldown_seconds", default: 0, null: false
    t.datetime "created_at", null: false
    t.jsonb "effects", default: {}, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "node_type", default: "passive", null: false
    t.jsonb "requirements", default: {}, null: false
    t.jsonb "resource_cost", default: {}, null: false
    t.bigint "skill_tree_id", null: false
    t.integer "tier", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["skill_tree_id", "key"], name: "index_skill_nodes_on_skill_tree_id_and_key", unique: true
    t.index ["skill_tree_id"], name: "index_skill_nodes_on_skill_tree_id"
  end

  create_table "skill_trees", force: :cascade do |t|
    t.bigint "character_class_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["character_class_id"], name: "index_skill_trees_on_character_class_id"
  end

  create_table "social_hub_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.string "host_npc_name"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "social_hub_id", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["social_hub_id"], name: "index_social_hub_events_on_social_hub_id"
    t.index ["starts_at"], name: "index_social_hub_events_on_starts_at"
    t.index ["status"], name: "index_social_hub_events_on_status"
  end

  create_table "social_hubs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hub_type", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id"
    t.index ["slug"], name: "index_social_hubs_on_slug", unique: true
    t.index ["zone_id"], name: "index_social_hubs_on_zone_id"
  end

  create_table "spawn_points", force: :cascade do |t|
    t.string "city_key"
    t.datetime "created_at", null: false
    t.boolean "default_entry", default: false, null: false
    t.string "faction_key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "respawn_seconds", default: 60, null: false
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.bigint "zone_id", null: false
    t.index ["zone_id", "faction_key"], name: "index_spawn_points_on_zone_id_and_faction_key"
    t.index ["zone_id"], name: "index_spawn_points_on_zone_id"
  end

  create_table "spawn_schedules", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "configured_by_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "monster_key", null: false
    t.string "rarity_override"
    t.string "region_key", null: false
    t.integer "respawn_seconds", default: 60, null: false
    t.datetime "updated_at", null: false
    t.index ["configured_by_id"], name: "index_spawn_schedules_on_configured_by_id"
    t.index ["region_key", "monster_key"], name: "index_spawn_schedules_on_region_key_and_monster_key", unique: true
  end

  create_table "tactical_matches", force: :cascade do |t|
    t.integer "actions_remaining", default: 3
    t.bigint "arena_room_id"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.bigint "current_turn_character_id"
    t.datetime "ended_at"
    t.datetime "expires_at"
    t.integer "grid_size", default: 8, null: false
    t.jsonb "grid_state", default: {}
    t.string "instance_key"
    t.bigint "opponent_id"
    t.datetime "started_at"
    t.integer "status", default: 0, null: false
    t.integer "turn_number", default: 1
    t.datetime "turn_started_at"
    t.integer "turn_time_limit", default: 60, null: false
    t.datetime "updated_at", null: false
    t.bigint "winner_id"
    t.index ["arena_room_id"], name: "index_tactical_matches_on_arena_room_id"
    t.index ["creator_id"], name: "index_tactical_matches_on_creator_id"
    t.index ["instance_key"], name: "index_tactical_matches_on_instance_key", unique: true
    t.index ["opponent_id"], name: "index_tactical_matches_on_opponent_id"
    t.index ["status"], name: "index_tactical_matches_on_status"
    t.index ["winner_id"], name: "index_tactical_matches_on_winner_id"
  end

  create_table "tactical_participants", force: :cascade do |t|
    t.boolean "alive", default: true, null: false
    t.integer "attack_range", default: 1
    t.jsonb "buff_durations", default: {}
    t.jsonb "buffs", default: {}
    t.bigint "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "current_hp", null: false
    t.integer "current_mp", default: 0
    t.integer "grid_x", default: 0, null: false
    t.integer "grid_y", default: 0, null: false
    t.integer "movement_range", default: 3
    t.bigint "tactical_match_id", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_tactical_participants_on_character_id"
    t.index ["tactical_match_id", "alive"], name: "index_tactical_participants_on_tactical_match_id_and_alive"
    t.index ["tactical_match_id", "character_id"], name: "idx_on_tactical_match_id_character_id_7b7c3cb512", unique: true
    t.index ["tactical_match_id"], name: "index_tactical_participants_on_tactical_match_id"
  end

  create_table "tile_buildings", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "building_key", null: false
    t.string "building_type", default: "castle", null: false
    t.datetime "created_at", null: false
    t.integer "destination_x"
    t.integer "destination_y"
    t.bigint "destination_zone_id"
    t.string "faction_key"
    t.string "icon", default: "🏰"
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
    t.string "biome"
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
    t.index ["biome"], name: "index_tile_npcs_on_biome"
    t.index ["defeated_by_id"], name: "index_tile_npcs_on_defeated_by_id"
    t.index ["npc_role"], name: "index_tile_npcs_on_npc_role"
    t.index ["npc_template_id"], name: "index_tile_npcs_on_npc_template_id"
    t.index ["respawns_at"], name: "index_tile_npcs_on_respawns_at"
    t.index ["zone", "x", "y"], name: "index_tile_npcs_on_zone_and_x_and_y", unique: true
  end

  create_table "tile_resources", force: :cascade do |t|
    t.integer "base_quantity", default: 1, null: false
    t.string "biome"
    t.datetime "created_at", null: false
    t.bigint "harvested_by_id"
    t.datetime "last_harvested_at"
    t.jsonb "metadata", default: {}, null: false
    t.integer "quantity", default: 1, null: false
    t.string "resource_key", null: false
    t.string "resource_type", default: "material", null: false
    t.datetime "respawns_at"
    t.datetime "updated_at", null: false
    t.integer "x", null: false
    t.integer "y", null: false
    t.string "zone", null: false
    t.index ["biome"], name: "index_tile_resources_on_biome"
    t.index ["harvested_by_id"], name: "index_tile_resources_on_harvested_by_id"
    t.index ["resource_type"], name: "index_tile_resources_on_resource_type"
    t.index ["respawns_at"], name: "index_tile_resources_on_respawns_at"
    t.index ["zone", "x", "y"], name: "index_tile_resources_on_zone_and_x_and_y", unique: true
  end

  create_table "title_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "equipped", default: false, null: false
    t.datetime "granted_at", null: false
    t.string "source", null: false
    t.bigint "title_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["title_id"], name: "index_title_grants_on_title_id"
    t.index ["user_id", "title_id"], name: "index_title_grants_on_user_id_and_title_id", unique: true
    t.index ["user_id"], name: "index_title_grants_on_user_id"
  end

  create_table "titles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "perks", default: {}, null: false
    t.boolean "premium_only", default: false, null: false
    t.boolean "priority_party_finder", default: false, null: false
    t.string "requirement_key", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trade_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "currency_amount"
    t.string "currency_type"
    t.jsonb "item_metadata", default: {}, null: false
    t.string "item_name"
    t.string "item_quality"
    t.bigint "owner_id", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "trade_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_trade_items_on_owner_id"
    t.index ["trade_session_id"], name: "index_trade_items_on_trade_session_id"
  end

  create_table "trade_sessions", force: :cascade do |t|
    t.datetime "completed_at"
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
    t.string "current_location_label"
    t.bigint "current_zone_id"
    t.string "current_zone_name"
    t.string "device_id", null: false
    t.string "ip_address"
    t.datetime "last_activity_at"
    t.bigint "last_character_id"
    t.string "last_character_name"
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
    t.bigint "active_title_id"
    t.string "chat_mute_reason"
    t.datetime "chat_muted_until"
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
    t.jsonb "social_settings", default: {}, null: false
    t.datetime "suspended_until"
    t.datetime "trade_locked_until"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["active_title_id"], name: "index_users_on_active_title_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["profile_name"], name: "index_users_on_profile_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["suspended_until"], name: "index_users_on_suspended_until"
    t.index ["trade_locked_until"], name: "index_users_on_trade_locked_until"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "event_types", default: [], array: true
    t.bigint "integration_token_id", null: false
    t.datetime "last_error_at"
    t.datetime "last_success_at"
    t.string "name", null: false
    t.string "secret", null: false
    t.string "target_url", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_token_id"], name: "index_webhook_endpoints_on_integration_token_id"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delivery_attempts", default: 0, null: false
    t.string "event_type", null: false
    t.datetime "last_attempted_at"
    t.jsonb "payload", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "webhook_endpoint_id", null: false
    t.index ["event_type"], name: "index_webhook_events_on_event_type"
    t.index ["status"], name: "index_webhook_events_on_status"
    t.index ["webhook_endpoint_id"], name: "index_webhook_events_on_webhook_endpoint_id"
  end

  create_table "zones", force: :cascade do |t|
    t.string "biome", null: false
    t.datetime "created_at", null: false
    t.jsonb "encounter_table", default: {}, null: false
    t.integer "height", default: 32, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.integer "turn_counter", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "width", default: 32, null: false
    t.index ["name"], name: "index_zones_on_name", unique: true
  end

  add_foreign_key "abilities", "character_classes"
  add_foreign_key "achievement_grants", "achievements"
  add_foreign_key "achievement_grants", "users"
  add_foreign_key "achievements", "titles", column: "title_reward_id"
  add_foreign_key "arena_applications", "arena_applications", column: "matched_with_id"
  add_foreign_key "arena_applications", "arena_matches"
  add_foreign_key "arena_applications", "arena_rooms"
  add_foreign_key "arena_applications", "characters", column: "applicant_id"
  add_foreign_key "arena_bets", "arena_matches"
  add_foreign_key "arena_bets", "characters", column: "predicted_winner_id"
  add_foreign_key "arena_bets", "users"
  add_foreign_key "arena_matches", "arena_rooms"
  add_foreign_key "arena_matches", "arena_seasons"
  add_foreign_key "arena_matches", "arena_tournaments"
  add_foreign_key "arena_matches", "zones"
  add_foreign_key "arena_participations", "arena_matches"
  add_foreign_key "arena_participations", "characters"
  add_foreign_key "arena_participations", "users"
  add_foreign_key "arena_rankings", "characters"
  add_foreign_key "arena_rooms", "zones"
  add_foreign_key "arena_tournaments", "competition_brackets"
  add_foreign_key "arena_tournaments", "event_instances"
  add_foreign_key "auction_bids", "auction_listings"
  add_foreign_key "auction_bids", "users", column: "bidder_id"
  add_foreign_key "auction_listings", "professions", column: "required_profession_id"
  add_foreign_key "auction_listings", "users", column: "seller_id"
  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "battle_participants", "battles"
  add_foreign_key "battle_participants", "characters"
  add_foreign_key "battle_participants", "npc_templates"
  add_foreign_key "battles", "characters", column: "initiator_id"
  add_foreign_key "battles", "zones"
  add_foreign_key "character_positions", "characters"
  add_foreign_key "character_positions", "zones"
  add_foreign_key "character_skills", "characters"
  add_foreign_key "character_skills", "skill_nodes"
  add_foreign_key "characters", "character_classes"
  add_foreign_key "characters", "clans"
  add_foreign_key "characters", "class_specializations", column: "secondary_specialization_id"
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
  add_foreign_key "chat_reports", "moderation_tickets"
  add_foreign_key "chat_reports", "users", column: "reporter_id"
  add_foreign_key "chat_violations", "chat_messages"
  add_foreign_key "chat_violations", "users"
  add_foreign_key "city_hotspots", "zones"
  add_foreign_key "city_hotspots", "zones", column: "destination_zone_id"
  add_foreign_key "clan_applications", "characters"
  add_foreign_key "clan_applications", "clans"
  add_foreign_key "clan_applications", "users", column: "applicant_id"
  add_foreign_key "clan_applications", "users", column: "referral_user_id"
  add_foreign_key "clan_applications", "users", column: "reviewed_by_id"
  add_foreign_key "clan_log_entries", "clans"
  add_foreign_key "clan_log_entries", "users", column: "actor_id"
  add_foreign_key "clan_memberships", "clans"
  add_foreign_key "clan_memberships", "users"
  add_foreign_key "clan_message_board_posts", "clans"
  add_foreign_key "clan_message_board_posts", "users", column: "author_id"
  add_foreign_key "clan_moderation_actions", "clans"
  add_foreign_key "clan_moderation_actions", "users", column: "gm_user_id"
  add_foreign_key "clan_quest_contributions", "characters"
  add_foreign_key "clan_quest_contributions", "clan_quests"
  add_foreign_key "clan_quests", "clans"
  add_foreign_key "clan_quests", "quests"
  add_foreign_key "clan_research_projects", "clans"
  add_foreign_key "clan_role_permissions", "clans"
  add_foreign_key "clan_stronghold_upgrades", "clans"
  add_foreign_key "clan_territories", "clans"
  add_foreign_key "clan_treasury_transactions", "clans"
  add_foreign_key "clan_treasury_transactions", "users", column: "actor_id"
  add_foreign_key "clan_wars", "battles"
  add_foreign_key "clan_wars", "clans", column: "attacker_clan_id"
  add_foreign_key "clan_wars", "clans", column: "defender_clan_id"
  add_foreign_key "clan_xp_events", "clans"
  add_foreign_key "clans", "users", column: "leader_id"
  add_foreign_key "class_specializations", "character_classes"
  add_foreign_key "combat_analytics_reports", "battles"
  add_foreign_key "combat_log_entries", "abilities"
  add_foreign_key "combat_log_entries", "battles"
  add_foreign_key "community_objectives", "event_instances"
  add_foreign_key "competition_brackets", "game_events"
  add_foreign_key "competition_matches", "competition_brackets"
  add_foreign_key "crafting_jobs", "characters"
  add_foreign_key "crafting_jobs", "crafting_stations"
  add_foreign_key "crafting_jobs", "recipes"
  add_foreign_key "crafting_jobs", "users"
  add_foreign_key "currency_transactions", "currency_wallets"
  add_foreign_key "currency_wallets", "users"
  add_foreign_key "cutscene_events", "quests"
  add_foreign_key "dungeon_encounters", "dungeon_instances"
  add_foreign_key "dungeon_instances", "characters", column: "leader_id"
  add_foreign_key "dungeon_instances", "dungeon_templates"
  add_foreign_key "dungeon_instances", "parties"
  add_foreign_key "dungeon_progress_checkpoints", "dungeon_instances"
  add_foreign_key "economy_alerts", "trade_sessions"
  add_foreign_key "event_instances", "game_events"
  add_foreign_key "event_schedules", "game_events"
  add_foreign_key "friendships", "users", column: "receiver_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "gathering_nodes", "professions"
  add_foreign_key "gathering_nodes", "zones"
  add_foreign_key "group_listings", "guilds"
  add_foreign_key "group_listings", "parties"
  add_foreign_key "group_listings", "professions"
  add_foreign_key "group_listings", "users", column: "owner_id"
  add_foreign_key "guild_applications", "guilds"
  add_foreign_key "guild_applications", "users", column: "applicant_id"
  add_foreign_key "guild_applications", "users", column: "reviewed_by_id"
  add_foreign_key "guild_bank_entries", "guilds"
  add_foreign_key "guild_bank_entries", "users", column: "actor_id"
  add_foreign_key "guild_bulletins", "guilds"
  add_foreign_key "guild_bulletins", "users", column: "author_id"
  add_foreign_key "guild_memberships", "guild_ranks"
  add_foreign_key "guild_memberships", "guilds"
  add_foreign_key "guild_memberships", "users"
  add_foreign_key "guild_missions", "guilds"
  add_foreign_key "guild_missions", "professions", column: "required_profession_id"
  add_foreign_key "guild_perks", "guilds"
  add_foreign_key "guild_perks", "users", column: "granted_by_id"
  add_foreign_key "guild_ranks", "guilds"
  add_foreign_key "guilds", "users", column: "leader_id"
  add_foreign_key "housing_decor_items", "housing_plots"
  add_foreign_key "housing_plots", "guilds", column: "visit_guild_id"
  add_foreign_key "housing_plots", "users"
  add_foreign_key "ignore_list_entries", "users"
  add_foreign_key "ignore_list_entries", "users", column: "ignored_user_id"
  add_foreign_key "integration_tokens", "users", column: "created_by_id"
  add_foreign_key "inventories", "characters"
  add_foreign_key "inventory_items", "inventories"
  add_foreign_key "inventory_items", "item_templates"
  add_foreign_key "leaderboard_entries", "leaderboards"
  add_foreign_key "live_ops_events", "users", column: "requested_by_id"
  add_foreign_key "mail_messages", "users", column: "recipient_id"
  add_foreign_key "mail_messages", "users", column: "sender_id"
  add_foreign_key "market_demand_signals", "professions"
  add_foreign_key "market_demand_signals", "zones"
  add_foreign_key "marketplace_kiosks", "users", column: "seller_id"
  add_foreign_key "medical_supply_pools", "zones"
  add_foreign_key "moderation_actions", "characters", column: "target_character_id"
  add_foreign_key "moderation_actions", "moderation_tickets", column: "ticket_id"
  add_foreign_key "moderation_actions", "users", column: "actor_id"
  add_foreign_key "moderation_actions", "users", column: "target_user_id"
  add_foreign_key "moderation_appeals", "moderation_tickets", column: "ticket_id"
  add_foreign_key "moderation_appeals", "users", column: "appellant_id"
  add_foreign_key "moderation_appeals", "users", column: "reviewer_id"
  add_foreign_key "moderation_tickets", "characters", column: "subject_character_id"
  add_foreign_key "moderation_tickets", "users", column: "assigned_moderator_id"
  add_foreign_key "moderation_tickets", "users", column: "reporter_id"
  add_foreign_key "moderation_tickets", "users", column: "subject_user_id"
  add_foreign_key "mount_stable_slots", "mounts", column: "current_mount_id"
  add_foreign_key "mount_stable_slots", "users"
  add_foreign_key "mounts", "mount_stable_slots"
  add_foreign_key "mounts", "users"
  add_foreign_key "movement_commands", "characters"
  add_foreign_key "movement_commands", "zones"
  add_foreign_key "npc_reports", "characters"
  add_foreign_key "npc_reports", "moderation_tickets"
  add_foreign_key "npc_reports", "users", column: "reporter_id"
  add_foreign_key "parties", "chat_channels"
  add_foreign_key "parties", "users", column: "leader_id"
  add_foreign_key "party_invitations", "parties"
  add_foreign_key "party_invitations", "users", column: "recipient_id"
  add_foreign_key "party_invitations", "users", column: "sender_id"
  add_foreign_key "party_memberships", "parties"
  add_foreign_key "party_memberships", "users"
  add_foreign_key "pet_companions", "pet_species", column: "pet_species_id"
  add_foreign_key "pet_companions", "users"
  add_foreign_key "premium_token_ledger_entries", "users"
  add_foreign_key "profession_progresses", "characters"
  add_foreign_key "profession_progresses", "profession_tools", column: "equipped_tool_id"
  add_foreign_key "profession_progresses", "professions"
  add_foreign_key "profession_progresses", "users"
  add_foreign_key "profession_tools", "characters"
  add_foreign_key "profession_tools", "professions"
  add_foreign_key "purchases", "users"
  add_foreign_key "quest_assignments", "characters"
  add_foreign_key "quest_assignments", "quests"
  add_foreign_key "quest_chapters", "quest_chains"
  add_foreign_key "quest_objectives", "quests"
  add_foreign_key "quest_steps", "quests"
  add_foreign_key "quests", "quest_chains"
  add_foreign_key "quests", "quest_chapters"
  add_foreign_key "recipes", "professions"
  add_foreign_key "skill_nodes", "skill_trees"
  add_foreign_key "skill_trees", "character_classes"
  add_foreign_key "social_hub_events", "social_hubs"
  add_foreign_key "social_hubs", "zones"
  add_foreign_key "spawn_points", "zones"
  add_foreign_key "spawn_schedules", "users", column: "configured_by_id"
  add_foreign_key "tactical_matches", "arena_rooms"
  add_foreign_key "tactical_matches", "characters", column: "creator_id"
  add_foreign_key "tactical_matches", "characters", column: "opponent_id"
  add_foreign_key "tactical_matches", "characters", column: "winner_id"
  add_foreign_key "tactical_participants", "characters"
  add_foreign_key "tactical_participants", "tactical_matches"
  add_foreign_key "tile_buildings", "zones", column: "destination_zone_id"
  add_foreign_key "tile_npcs", "characters", column: "defeated_by_id"
  add_foreign_key "tile_npcs", "npc_templates"
  add_foreign_key "tile_resources", "characters", column: "harvested_by_id"
  add_foreign_key "title_grants", "titles"
  add_foreign_key "title_grants", "users"
  add_foreign_key "trade_items", "trade_sessions"
  add_foreign_key "trade_items", "users", column: "owner_id"
  add_foreign_key "trade_sessions", "users", column: "initiator_id"
  add_foreign_key "trade_sessions", "users", column: "recipient_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "titles", column: "active_title_id"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
  add_foreign_key "webhook_endpoints", "integration_tokens"
  add_foreign_key "webhook_events", "webhook_endpoints"
end
