class CreateMetaProgressionSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :achievements do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.integer :points, null: false, default: 0
      t.string :reward_type
      t.jsonb :reward_payload, null: false, default: {}
      t.string :category, null: false, default: "general"
      t.boolean :account_wide, null: false, default: true
      t.references :title_reward
      t.integer :display_priority, null: false, default: 0
      t.jsonb :share_payload, null: false, default: {}
      t.timestamps
    end
    add_index :achievements, :key, unique: true
    add_index :achievements, :category
    add_index :achievements, :display_priority

    create_table :achievement_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.datetime :granted_at, null: false
      t.string :source, null: false
      t.timestamps
    end
    add_index :achievement_grants, [:user_id, :achievement_id], unique: true, name: "index_achievement_grants_on_user_and_achievement"

    create_table :titles do |t|
      t.string :name, null: false
      t.string :requirement_key, null: false
      t.boolean :premium_only, null: false, default: false
      t.jsonb :perks, null: false, default: {}
      t.boolean :priority_party_finder, null: false, default: false
      t.timestamps
    end

    create_table :title_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :title, null: false, foreign_key: true
      t.boolean :equipped, null: false, default: false
      t.string :source, null: false
      t.datetime :granted_at, null: false
      t.timestamps
    end
    add_index :title_grants, [:user_id, :title_id], unique: true

    add_reference :users, :active_title, foreign_key: {to_table: :titles}

    create_table :housing_plots do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plot_type, null: false
      t.string :location_key, null: false
      t.string :plot_tier, null: false, default: "starter"
      t.string :exterior_style, null: false, default: "classic"
      t.integer :storage_slots, null: false, default: 20
      t.integer :room_slots, null: false, default: 1
      t.integer :utility_slots, null: false, default: 1
      t.string :visit_scope, null: false, default: "friends"
      t.references :visit_guild, foreign_key: {to_table: :guilds}, index: false
      t.boolean :showcase_enabled, null: false, default: false
      t.integer :upkeep_gold_cost, null: false, default: 200
      t.datetime :next_upkeep_due_at
      t.jsonb :access_rules, null: false, default: {}
      t.timestamps
    end
    add_index :housing_plots, :plot_tier
    add_index :housing_plots, :visit_scope
    add_index :housing_plots, :visit_guild_id

    create_table :housing_decor_items do |t|
      t.references :housing_plot, null: false, foreign_key: true
      t.string :name, null: false
      t.string :decor_type, null: false, default: "furniture"
      t.jsonb :placement, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.boolean :trophy, null: false, default: false
      t.integer :utility_slot
      t.timestamps
    end
    add_index :housing_decor_items, :decor_type

    create_table :pet_species do |t|
      t.string :name, null: false
      t.string :ability_type, null: false
      t.string :rarity, null: false, default: "common"
      t.jsonb :ability_payload, null: false, default: {}
      t.timestamps
    end

    create_table :pet_companions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pet_species, null: false, foreign_key: true
      t.string :nickname
      t.integer :level, null: false, default: 1
      t.integer :bonding_experience, null: false, default: 0
      t.string :affinity_stage, null: false, default: "neutral"
      t.jsonb :care_state, null: false, default: {}
      t.datetime :last_care_performed_at
      t.datetime :care_task_available_at
      t.string :passive_bonus_type
      t.integer :passive_bonus_value, null: false, default: 0
      t.integer :gathering_bonus, null: false, default: 0
      t.jsonb :stats, null: false, default: {}
      t.timestamps
    end
    add_index :pet_companions, :affinity_stage

    create_table :mounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :mount_type, null: false
      t.integer :speed_bonus, null: false, default: 0
      t.string :faction_key, null: false, default: "neutral"
      t.string :rarity, null: false, default: "common"
      t.references :mount_stable_slot
      t.string :summon_state, null: false, default: "stabled"
      t.string :cosmetic_variant, null: false, default: "default"
      t.jsonb :appearance, null: false, default: {}
      t.timestamps
    end
    add_index :mounts, :faction_key
    add_index :mounts, :rarity

    create_table :mount_stable_slots do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :slot_index, null: false
      t.string :status, null: false, default: "locked"
      t.references :current_mount, foreign_key: {to_table: :mounts}
      t.jsonb :cosmetics, null: false, default: {}
      t.datetime :unlocked_at
      t.timestamps
    end
    add_index :mount_stable_slots, [:user_id, :slot_index], unique: true

    add_foreign_key :achievements, :titles, column: :title_reward_id
    add_foreign_key :mounts, :mount_stable_slots
  end
end
