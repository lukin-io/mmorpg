# frozen_string_literal: true

class CreateArenaRoomsAndApplications < ActiveRecord::Migration[8.1]
  def change
    # Arena rooms with level/faction restrictions (Neverlands-inspired)
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
      t.references :applicant, null: false, foreign_key: { to_table: :characters }
      t.references :matched_with, foreign_key: { to_table: :arena_applications }
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

    # Add arena_room reference to arena_matches
    add_reference :arena_matches, :arena_room, foreign_key: true

    # Add vitals columns to characters
    change_table :characters, bulk: true do |t|
      t.integer :current_hp, null: false, default: 100
      t.integer :max_hp, null: false, default: 100
      t.integer :current_mp, null: false, default: 50
      t.integer :max_mp, null: false, default: 50
      t.integer :hp_regen_interval, null: false, default: 300
      t.integer :mp_regen_interval, null: false, default: 600
      t.boolean :in_combat, null: false, default: false
      t.datetime :last_combat_at
      t.datetime :last_regen_tick_at
    end
  end
end

