class CreateGuildPartyArenaSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :guild_ranks do |t|
      t.references :guild, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.jsonb :permissions, default: {}, null: false
      t.timestamps
    end

    add_index :guild_ranks, [:guild_id, :name], unique: true

    change_table :guild_memberships, bulk: true do |t|
      t.references :guild_rank, foreign_key: true
    end

    create_table :guild_bulletins do |t|
      t.references :guild, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: {to_table: :users}
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :pinned, null: false, default: false
      t.datetime :published_at, null: false
      t.timestamps
    end

    add_index :guild_bulletins, [:guild_id, :pinned]

    create_table :guild_perks do |t|
      t.references :guild, null: false, foreign_key: true
      t.string :perk_key, null: false
      t.integer :source_level, null: false, default: 1
      t.datetime :unlocked_at, null: false
      t.references :granted_by, foreign_key: {to_table: :users}
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :guild_perks, [:guild_id, :perk_key], unique: true

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
      t.string :spectator_code
      t.string :winning_team
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end

    add_index :arena_matches, :status
    add_index :arena_matches, :spectator_code, unique: true

    create_table :arena_participations do |t|
      t.references :arena_match, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :team, null: false
      t.integer :result, null: false, default: 0
      t.integer :rating_delta, null: false, default: 0
      t.jsonb :reward_payload, default: {}, null: false
      t.datetime :joined_at, null: false
      t.timestamps
    end

    add_index :arena_participations, [:arena_match_id, :character_id], unique: true, name: "index_arena_participants_on_match_and_character"
  end
end
