class CreateEventsAndCommunitySystems < ActiveRecord::Migration[8.1]
  def change
    create_table :game_events do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :feature_flag_key
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :game_events, :slug, unique: true

    create_table :event_schedules do |t|
      t.references :game_event, null: false, foreign_key: true
      t.string :schedule_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    create_table :leaderboards do |t|
      t.string :name, null: false
      t.string :scope, null: false
      t.string :season, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.timestamps
    end

    create_table :leaderboard_entries do |t|
      t.references :leaderboard, null: false, foreign_key: true
      t.string :entity_type, null: false
      t.bigint :entity_id, null: false
      t.integer :score, null: false, default: 0
      t.integer :rank
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :leaderboard_entries, [:leaderboard_id, :entity_type, :entity_id], unique: true, name: "index_leaderboard_entries_on_scope"

    create_table :competition_brackets do |t|
      t.references :game_event, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :competition_matches do |t|
      t.references :competition_bracket, null: false, foreign_key: true
      t.integer :round_number, null: false, default: 1
      t.jsonb :participants, null: false, default: {}
      t.datetime :scheduled_at, null: false
      t.jsonb :result_payload, null: false, default: {}
      t.timestamps
    end
  end
end
