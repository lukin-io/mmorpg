# frozen_string_literal: true

class ExpandQuestStoryStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :quest_chapters do |t|
      t.references :quest_chain, null: false, foreign_key: true
      t.string :key, null: false
      t.string :title, null: false
      t.text :synopsis
      t.integer :position, null: false, default: 1
      t.integer :level_gate, null: false, default: 1
      t.integer :reputation_gate, null: false, default: 0
      t.string :faction_alignment
      t.string :unlock_cutscene_key
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :quest_chapters, [:quest_chain_id, :position], unique: true
    add_index :quest_chapters, :key, unique: true

    create_table :quest_steps do |t|
      t.references :quest, null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string :step_type, null: false
      t.string :npc_key
      t.jsonb :content, null: false, default: {}
      t.jsonb :branching_outcomes, null: false, default: {}
      t.boolean :requires_confirmation, null: false, default: false
      t.timestamps
    end
    add_index :quest_steps, [:quest_id, :position], unique: true

    change_table :quests, bulk: true do |t|
      t.references :quest_chapter, foreign_key: true
      t.integer :difficulty_tier, null: false, default: 0
      t.integer :recommended_party_size, null: false, default: 1
      t.integer :min_level, null: false, default: 1
      t.integer :min_reputation, null: false, default: 0
      t.jsonb :failure_consequence, null: false, default: {}
      t.jsonb :map_overlays, null: false, default: {}
      t.boolean :active, null: false, default: true
    end

    add_index :quests, :difficulty_tier
    add_index :quests, :recommended_party_size
    add_index :quests, :min_level

    add_column :quest_assignments, :rewards_claimed_at, :datetime
  end
end
