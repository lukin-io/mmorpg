# frozen_string_literal: true

class CreateArenaRoomsAndApplications < ActiveRecord::Migration[8.1]
  def change
    # Arena rooms with level/faction restrictions
    create_table :arena_rooms do |t|
      t.references :zone, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :room_type, null: false, default: 0
      t.integer :level_min, null: false, default: 0
      t.integer :level_max, null: false, default: 100
      t.string :faction_restriction
      t.integer :max_concurrent_matches, null: false, default: 10
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :arena_rooms, :slug, unique: true
    add_index :arena_rooms, :room_type
    add_index :arena_rooms, :active

    # Arena applications (fight queue)
    create_table :arena_applications do |t|
      t.references :arena_room, null: false, foreign_key: true
      t.references :applicant, foreign_key: {to_table: :characters}
      t.references :npc_template, foreign_key: true
      t.references :matched_with, foreign_key: {to_table: :arena_applications}
      t.references :arena_match, foreign_key: true

      t.integer :fight_type, null: false, default: 0
      t.integer :fight_kind, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :timeout_seconds, null: false, default: 180
      t.integer :trauma_percent, null: false, default: 30

      # Group fight parameters
      t.integer :team_count, default: 1
      t.integer :team_level_min
      t.integer :team_level_max
      t.integer :enemy_count
      t.integer :enemy_level_min
      t.integer :enemy_level_max
      t.integer :wait_minutes, default: 10

      t.boolean :closed_fight, null: false, default: false
      t.datetime :expires_at
      t.datetime :matched_at
      t.datetime :starts_at

      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :arena_applications, :status
    add_index :arena_applications, :fight_type
    add_index :arena_applications, [:arena_room_id, :status]
    add_index :arena_applications, [:arena_room_id, :npc_template_id],
      where: "npc_template_id IS NOT NULL",
      name: "idx_arena_apps_npc"

    # Add arena_room reference to arena_matches
    add_reference :arena_matches, :arena_room, foreign_key: true
  end
end
