class ExpandCraftingAndEconomyTables < ActiveRecord::Migration[8.1]
  class MigrationCraftingJob < ApplicationRecord
    self.table_name = "crafting_jobs"
  end

  class MigrationCharacter < ApplicationRecord
    self.table_name = "characters"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    change_table :recipes do |t|
      t.string :source_kind, null: false, default: "quest"
      t.string :source_reference
      t.string :risk_level, null: false, default: "safe"
      t.integer :premium_token_cost, null: false, default: 0
      t.boolean :guild_bound, null: false, default: false
      t.jsonb :quality_modifiers, null: false, default: {}
      t.string :required_station_archetype, null: false, default: "city"
    end

    change_table :crafting_stations do |t|
      t.string :station_archetype, null: false, default: "city"
      t.decimal :time_penalty_multiplier, precision: 5, scale: 2, null: false, default: 1.0
      t.integer :success_penalty, null: false, default: 0
      t.boolean :portable, null: false, default: false
    end

    change_table :crafting_jobs do |t|
      t.references :character, foreign_key: true
      t.string :quality_tier, null: false, default: "common"
      t.integer :quality_score, null: false, default: 0
      t.integer :success_chance, null: false, default: 0
      t.boolean :portable_penalty_applied, null: false, default: false
      t.integer :batch_quantity, null: false, default: 1
    end

    say_with_time "Backfilling crafting job characters" do
      MigrationCraftingJob.reset_column_information
      MigrationCraftingJob.find_each do |job|
        next if job.character_id.present?

        user = MigrationUser.find_by(id: job.user_id)
        next unless user

        character = MigrationCharacter.where(user_id: user.id).order(:id).first
        character ||= MigrationCharacter.create!(
          user_id: user.id,
          name: "Crafter-#{user.id}-job#{job.id}",
          level: 1,
          experience: 0,
          metadata: {}
        )

        job.update_columns(character_id: character.id)
      end
    end

    change_column_null :crafting_jobs, :character_id, false
    add_index :crafting_jobs, [:character_id, :status]

    change_table :gathering_nodes do |t|
      t.datetime :last_harvested_at
      t.datetime :next_available_at
      t.integer :group_bonus_percent, null: false, default: 0
    end

    change_table :auction_listings do |t|
      t.references :required_profession, foreign_key: {to_table: :professions}
      t.integer :required_skill_level, null: false, default: 0
      t.string :commission_scope, null: false, default: "personal"
    end

    create_table :guild_missions do |t|
      t.references :guild, null: false, foreign_key: true
      t.references :required_profession, null: false, foreign_key: {to_table: :professions}
      t.string :required_item_name, null: false
      t.integer :required_quantity, null: false, default: 0
      t.integer :progress_quantity, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :guild_missions, [:guild_id, :status]
  end

  def down
    drop_table :guild_missions

    remove_reference :auction_listings, :required_profession, foreign_key: true
    remove_column :auction_listings, :required_skill_level
    remove_column :auction_listings, :commission_scope

    remove_column :gathering_nodes, :group_bonus_percent
    remove_column :gathering_nodes, :next_available_at
    remove_column :gathering_nodes, :last_harvested_at

    remove_index :crafting_jobs, [:character_id, :status]
    remove_column :crafting_jobs, :batch_quantity
    remove_column :crafting_jobs, :portable_penalty_applied
    remove_column :crafting_jobs, :success_chance
    remove_column :crafting_jobs, :quality_score
    remove_column :crafting_jobs, :quality_tier
    remove_reference :crafting_jobs, :character, foreign_key: true

    remove_column :crafting_stations, :portable
    remove_column :crafting_stations, :success_penalty
    remove_column :crafting_stations, :time_penalty_multiplier
    remove_column :crafting_stations, :station_archetype

    remove_column :recipes, :required_station_archetype
    remove_column :recipes, :quality_modifiers
    remove_column :recipes, :guild_bound
    remove_column :recipes, :premium_token_cost
    remove_column :recipes, :risk_level
    remove_column :recipes, :source_reference
    remove_column :recipes, :source_kind
  end
end
