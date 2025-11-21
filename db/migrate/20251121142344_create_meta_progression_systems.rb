class CreateMetaProgressionSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :achievements do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.integer :points, null: false, default: 0
      t.string :reward_type
      t.jsonb :reward_payload, null: false, default: {}
      t.timestamps
    end
    add_index :achievements, :key, unique: true

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
      t.timestamps
    end

    create_table :housing_plots do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plot_type, null: false
      t.string :location_key, null: false
      t.integer :storage_slots, null: false, default: 20
      t.jsonb :access_rules, null: false, default: {}
      t.timestamps
    end

    create_table :housing_decor_items do |t|
      t.references :housing_plot, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :placement, null: false, default: {}
      t.boolean :trophy, null: false, default: false
      t.timestamps
    end

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
      t.jsonb :stats, null: false, default: {}
      t.timestamps
    end

    create_table :mounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :mount_type, null: false
      t.integer :speed_bonus, null: false, default: 0
      t.jsonb :appearance, null: false, default: {}
      t.timestamps
    end
  end
end
