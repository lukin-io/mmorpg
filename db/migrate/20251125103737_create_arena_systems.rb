class CreateArenaSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :arena_matches do |t|
      t.references :zone, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :match_type, null: false, default: 0
      t.string :bracket_position
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :turn_timeout_seconds, default: 300
      t.datetime :current_turn_started_at
      t.integer :current_turn_number, default: 0
      t.boolean :timed_out, default: false
      t.integer :trauma_percent, default: 30
      t.string :current_turn_team
      t.string :spectator_code
      t.string :winning_team
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :arena_matches, :status
    add_index :arena_matches, :spectator_code, unique: true
    add_index :arena_matches, [:status, :current_turn_started_at],
      name: "index_arena_matches_on_timeout_check",
      where: "status = 2"

    create_table :arena_participations do |t|
      t.references :arena_match, null: false, foreign_key: true
      t.references :character, foreign_key: true
      t.references :user, foreign_key: true
      t.references :npc_template, foreign_key: true
      t.string :team, null: false
      t.integer :result, null: false, default: 0
      t.jsonb :metadata, default: {}, null: false
      t.datetime :joined_at, null: false
      t.datetime :ended_at
      t.timestamps
    end

    add_index :arena_participations, [:arena_match_id, :character_id], unique: true, name: "index_arena_participants_on_match_and_character"
  end
end
