class CreateGuildsAndClans < ActiveRecord::Migration[8.1]
  def change
    create_table :guilds do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :motto
      t.integer :level, null: false, default: 1
      t.bigint :experience, null: false, default: 0
      t.jsonb :banner_data, null: false, default: {}
      t.jsonb :recruitment_settings, null: false, default: {}
      t.integer :treasury_gold, null: false, default: 0
      t.integer :treasury_silver, null: false, default: 0
      t.integer :treasury_premium_tokens, null: false, default: 0
      t.references :leader, null: false, foreign_key: {to_table: :users}
      t.timestamps
    end
    add_index :guilds, :slug, unique: true

    create_table :guild_memberships do |t|
      t.references :guild, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.jsonb :permissions, null: false, default: {}
      t.datetime :joined_at
      t.timestamps
    end
    add_index :guild_memberships, [:guild_id, :user_id], unique: true

    create_table :guild_applications do |t|
      t.references :guild, null: false, foreign_key: true
      t.references :applicant, null: false, foreign_key: {to_table: :users}
      t.integer :status, null: false, default: 0
      t.jsonb :answers, null: false, default: {}
      t.references :reviewed_by, null: true, foreign_key: {to_table: :users}
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :guild_applications, [:guild_id, :applicant_id], unique: true, name: "index_guild_applications_on_guild_and_applicant"

    create_table :guild_bank_entries do |t|
      t.references :guild, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: {to_table: :users}
      t.integer :entry_type, null: false, default: 0
      t.string :currency_type, null: false
      t.integer :amount, null: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    create_table :clans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :prestige, null: false, default: 0
      t.integer :treasury_gold, null: false, default: 0
      t.integer :treasury_silver, null: false, default: 0
      t.integer :treasury_premium_tokens, null: false, default: 0
      t.references :leader, null: false, foreign_key: {to_table: :users}
      t.timestamps
    end
    add_index :clans, :slug, unique: true

    create_table :clan_memberships do |t|
      t.references :clan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.datetime :joined_at
      t.timestamps
    end
    add_index :clan_memberships, [:clan_id, :user_id], unique: true

    create_table :clan_territories do |t|
      t.references :clan, null: false, foreign_key: true
      t.string :territory_key, null: false
      t.integer :tax_rate_basis_points, null: false, default: 0
      t.datetime :last_claimed_at
      t.timestamps
    end
    add_index :clan_territories, :territory_key, unique: true

    create_table :clan_wars do |t|
      t.references :attacker_clan, null: false, foreign_key: {to_table: :clans}
      t.references :defender_clan, null: false, foreign_key: {to_table: :clans}
      t.integer :status, null: false, default: 0
      t.string :territory_key, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :resolved_at
      t.jsonb :result_payload, null: false, default: {}
      t.timestamps
    end
    add_index :clan_wars, [:attacker_clan_id, :defender_clan_id, :territory_key], name: "index_clan_wars_on_participants_and_territory"
  end
end
