class CreatePartyArenaSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :parties do |t|
      t.string :name, null: false
      t.text :purpose
      t.integer :status, null: false, default: 0
      t.references :leader, null: false, foreign_key: {to_table: :users}
      t.references :chat_channel, foreign_key: true
      t.integer :ready_check_state, null: false, default: 0
      t.datetime :ready_check_started_at
      t.integer :max_size, null: false, default: 5
      t.jsonb :activity_metadata, default: {}, null: false
      t.timestamps
    end

    add_index :parties, :status

    create_table :party_memberships do |t|
      t.references :party, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :ready_state, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :joined_at, null: false
      t.datetime :left_at
      t.timestamps
    end

    add_index :party_memberships, [:party_id, :user_id], unique: true

    create_table :party_invitations do |t|
      t.references :party, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: {to_table: :users}
      t.references :recipient, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :party_invitations, :token, unique: true

    add_reference :group_listings, :party, foreign_key: true

    create_table :arena_seasons do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :status, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :arena_seasons, :slug, unique: true

    create_table :arena_matches do |t|
      t.references :arena_season, foreign_key: true
      t.references :arena_tournament, foreign_key: true
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
      t.integer :rating_delta, null: false, default: 0
      t.jsonb :reward_payload, default: {}, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :joined_at, null: false
      t.datetime :ended_at
      t.timestamps
    end

    add_index :arena_participations, [:arena_match_id, :character_id], unique: true, name: "index_arena_participants_on_match_and_character"
  end
end
