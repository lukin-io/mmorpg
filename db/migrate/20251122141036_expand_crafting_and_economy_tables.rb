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
    change_table :crafting_jobs do |t|
      t.references :character, foreign_key: true
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

    change_table :auction_listings do |t|
      t.references :required_profession, foreign_key: {to_table: :professions}
      t.integer :required_skill_level, null: false, default: 0
      t.string :commission_scope, null: false, default: "personal"
    end
  end

  def down
    remove_reference :auction_listings, :required_profession, foreign_key: true
    remove_column :auction_listings, :required_skill_level
    remove_column :auction_listings, :commission_scope

    remove_index :crafting_jobs, [:character_id, :status]
    remove_reference :crafting_jobs, :character, foreign_key: true
  end
end
