class CreateQuestingSystem < ActiveRecord::Migration[8.1]
  def change
    create_table :quest_chains do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :quest_chains, :key, unique: true

    create_table :quests do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.text :summary
      t.integer :quest_type, null: false, default: 0
      t.references :quest_chain, foreign_key: true
      t.integer :sequence, null: false, default: 1
      t.integer :chapter, null: false, default: 1
      t.boolean :repeatable, null: false, default: false
      t.integer :cooldown_seconds, null: false, default: 0
      t.string :daily_reset_slot
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :rewards, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :quests, :key, unique: true
    add_index :quests, [:quest_chain_id, :sequence]

    create_table :quest_objectives do |t|
      t.references :quest, null: false, foreign_key: true
      t.integer :position, null: false, default: 1
      t.string :objective_type, null: false
      t.boolean :optional, null: false, default: false
      t.jsonb :requirements, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :quest_assignments do |t|
      t.references :quest, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.jsonb :progress, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :expires_at
      t.datetime :next_available_at
      t.timestamps
    end
    add_index :quest_assignments, [:quest_id, :character_id], unique: true

    create_table :cutscene_events do |t|
      t.string :key, null: false
      t.references :quest, foreign_key: true
      t.jsonb :content, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :cutscene_events, :key, unique: true
  end
end
