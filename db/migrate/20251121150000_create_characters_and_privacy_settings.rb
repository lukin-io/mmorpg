# frozen_string_literal: true

class CreateCharactersAndPrivacySettings < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :level, null: false, default: 1
      t.bigint :experience, null: false, default: 0
      t.integer :stat_points_available, null: false, default: 0
      t.integer :skill_points_available, null: false, default: 0
      t.integer :combat_skill_points, null: false, default: 0
      t.integer :peace_skill_points, null: false, default: 0
      t.jsonb :allocated_stats, null: false, default: {}
      t.jsonb :passive_skills, null: false, default: {}
      t.jsonb :progression_sources, null: false, default: {}
      t.string :alignment, null: false, default: "none"
      t.jsonb :resource_pools, null: false, default: {}
      t.datetime :last_level_up_at
      t.integer :current_hp, null: false, default: 100
      t.integer :max_hp, null: false, default: 100
      t.integer :current_mp, null: false, default: 50
      t.integer :max_mp, null: false, default: 50
      t.integer :hp_regen_interval, null: false, default: 300
      t.integer :mp_regen_interval, null: false, default: 600
      t.boolean :in_combat, null: false, default: false
      t.datetime :last_combat_at
      t.datetime :last_regen_tick_at
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :characters, :name, unique: true
    add_index :characters, :combat_skill_points, where: "combat_skill_points > 0"
    add_index :characters, :peace_skill_points, where: "peace_skill_points > 0"
  end
end
