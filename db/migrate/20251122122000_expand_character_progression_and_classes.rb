# frozen_string_literal: true

class ExpandCharacterProgressionAndClasses < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :stat_points_available, :integer, null: false, default: 0
    add_column :characters, :skill_points_available, :integer, null: false, default: 0
    add_column :characters, :allocated_stats, :jsonb, null: false, default: {}
    add_column :characters, :reputation, :integer, null: false, default: 0
    add_column :characters, :faction_alignment, :string, null: false, default: "neutral"
    add_column :characters, :alignment_score, :integer, null: false, default: 0
    add_column :characters, :resource_pools, :jsonb, null: false, default: {}
    add_column :characters, :last_level_up_at, :datetime

    create_table :class_specializations do |t|
      t.references :character_class, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :unlock_requirements, null: false, default: {}
      t.timestamps
    end
    add_index :class_specializations, [:character_class_id, :name], unique: true

    add_reference :characters, :secondary_specialization, foreign_key: {to_table: :class_specializations}

    add_column :character_classes, :resource_type, :string, null: false, default: "stamina"
    add_column :character_classes, :equipment_tags, :jsonb, null: false, default: []
    add_column :character_classes, :combo_rules, :jsonb, null: false, default: {}

    create_table :skill_trees do |t|
      t.references :character_class, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :skill_nodes do |t|
      t.references :skill_tree, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :node_type, null: false, default: "passive"
      t.integer :tier, null: false, default: 1
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :effects, null: false, default: {}
      t.jsonb :resource_cost, null: false, default: {}
      t.integer :cooldown_seconds, null: false, default: 0
      t.timestamps
    end
    add_index :skill_nodes, [:skill_tree_id, :key], unique: true

    create_table :character_skills do |t|
      t.references :character, null: false, foreign_key: true
      t.references :skill_node, null: false, foreign_key: true
      t.datetime :unlocked_at, null: false
      t.timestamps
    end
    add_index :character_skills, [:character_id, :skill_node_id], unique: true

    create_table :abilities do |t|
      t.references :character_class, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false, default: "active"
      t.jsonb :resource_cost, null: false, default: {}
      t.integer :cooldown_seconds, null: false, default: 0
      t.jsonb :effects, null: false, default: {}
      t.jsonb :combo_tags, null: false, default: []
      t.timestamps
    end
    add_index :abilities, [:character_class_id, :name], unique: true
  end
end
