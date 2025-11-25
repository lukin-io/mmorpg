# frozen_string_literal: true

class ExpandClanSystems < ActiveRecord::Migration[8.1]
  def change
    change_table :clans, bulk: true do |t|
      t.integer :level, null: false, default: 1
      t.integer :experience, null: false, default: 0
      t.jsonb :banner_data, null: false, default: {}
      t.jsonb :unlocked_buffs, null: false, default: []
      t.jsonb :recruitment_settings, null: false, default: {}
      t.jsonb :treasury_rules, null: false, default: {}
      t.jsonb :infrastructure_state, null: false, default: {}
      t.jsonb :fast_travel_nodes, null: false, default: []
      t.string :discord_webhook_url
    end

    change_table :clan_wars, bulk: true do |t|
      t.datetime :declaration_made_at
      t.datetime :preparation_begins_at
      t.jsonb :support_objectives, null: false, default: []
      t.references :battle, foreign_key: true
    end

    change_table :clan_territories, bulk: true do |t|
      t.string :world_region_key
      t.string :exclusive_dungeon_key
      t.string :fast_travel_node_key
      t.jsonb :benefits, null: false, default: {}
    end

    create_table :clan_role_permissions do |t|
      t.references :clan, null: false, foreign_key: true
      t.integer :role, null: false
      t.string :permission_key, null: false
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :clan_role_permissions,
      [:clan_id, :role, :permission_key],
      unique: true,
      name: "index_clan_role_permissions_on_role_and_permission"

    create_table :clan_xp_events do |t|
      t.references :clan, null: false, foreign_key: true
      t.string :source, null: false
      t.integer :amount, null: false
      t.datetime :recorded_at, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :clan_treasury_transactions do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: {to_table: :users}
      t.string :currency_type, null: false
      t.integer :amount, null: false
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :clan_stronghold_upgrades do |t|
      t.references :clan, null: false, foreign_key: true
      t.string :upgrade_key, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :progress, null: false, default: {}
      t.timestamps
    end
    add_index :clan_stronghold_upgrades,
      [:clan_id, :upgrade_key],
      unique: true,
      name: "index_clan_stronghold_upgrades_on_clan_and_key"

    create_table :clan_research_projects do |t|
      t.references :clan, null: false, foreign_key: true
      t.string :project_key, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :progress, null: false, default: {}
      t.jsonb :unlocks_payload, null: false, default: {}
      t.datetime :completed_at
      t.timestamps
    end
    add_index :clan_research_projects,
      [:clan_id, :project_key],
      unique: true,
      name: "index_clan_research_projects_on_clan_and_key"

    create_table :clan_applications do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :applicant, null: false, foreign_key: {to_table: :users}
      t.references :character, foreign_key: true
      t.references :referral_user, foreign_key: {to_table: :users}
      t.jsonb :vetting_answers, null: false, default: {}
      t.boolean :auto_accepted, null: false, default: false
      t.integer :status, null: false, default: 0
      t.references :reviewed_by, foreign_key: {to_table: :users}
      t.datetime :reviewed_at
      t.text :decision_reason
      t.timestamps
    end

    create_table :clan_quests do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :quest, foreign_key: true
      t.string :quest_key, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :progress, null: false, default: {}
      t.datetime :expires_at
      t.timestamps
    end
    add_index :clan_quests, [:clan_id, :quest_key], unique: true

    create_table :clan_quest_contributions do |t|
      t.references :clan_quest, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.string :contribution_type, null: false
      t.integer :amount, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :clan_message_board_posts do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: {to_table: :users}
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :pinned, null: false, default: false
      t.datetime :published_at, null: false
      t.datetime :broadcasted_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clan_message_board_posts, [:clan_id, :pinned]

    create_table :clan_log_entries do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :actor, foreign_key: {to_table: :users}
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :clan_log_entries, [:clan_id, :created_at]

    create_table :clan_moderation_actions do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :gm_user, null: false, foreign_key: {to_table: :users}
      t.string :action_type, null: false
      t.references :target, polymorphic: true
      t.text :notes
      t.datetime :rolled_back_at
      t.timestamps
    end
  end
end
