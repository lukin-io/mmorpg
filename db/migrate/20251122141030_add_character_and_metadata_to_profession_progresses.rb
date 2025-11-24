class AddCharacterAndMetadataToProfessionProgresses < ActiveRecord::Migration[8.1]
  class MigrationProfessionProgress < ApplicationRecord
    self.table_name = "profession_progresses"

    belongs_to :profession, class_name: "AddCharacterAndMetadataToProfessionProgresses::MigrationProfession"
  end

  class MigrationCharacter < ApplicationRecord
    self.table_name = "characters"
  end

  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationProfession < ApplicationRecord
    self.table_name = "professions"
  end

  def up
    add_reference :profession_progresses, :character, foreign_key: true
    add_column :profession_progresses, :slot_kind, :string, null: false, default: "primary"
    add_column :profession_progresses, :metadata, :jsonb, null: false, default: {}

    say_with_time "Backfilling profession progress characters and slot kinds" do
      MigrationProfessionProgress.reset_column_information
      MigrationProfession.reset_column_information
      MigrationProfessionProgress.includes(:profession).find_each do |progress|
        backfill_character!(progress)
        backfill_slot_kind!(progress)
      end
    end

    change_column_null :profession_progresses, :character_id, false
    add_index :profession_progresses, [:character_id, :profession_id],
      unique: true,
      name: "idx_profession_progresses_on_character_and_profession"
  end

  def down
    remove_index :profession_progresses, name: "idx_profession_progresses_on_character_and_profession"
    remove_column :profession_progresses, :metadata
    remove_column :profession_progresses, :slot_kind
    remove_reference :profession_progresses, :character, foreign_key: true
  end

  private

  def backfill_character!(progress)
    return if progress.character_id.present?

    user = MigrationUser.find_by(id: progress.user_id)
    return unless user

    character = MigrationCharacter.where(user_id: user.id).order(:id).first
    character ||= MigrationCharacter.create!(
      user_id: user.id,
      name: "Crafter-#{user.id}-#{progress.id}",
      level: 1,
      experience: 0,
      metadata: {}
    )

    progress.update_columns(character_id: character.id)
  end

  def backfill_slot_kind!(progress)
    profession = MigrationProfession.find_by(id: progress.profession_id)
    kind =
      case profession&.category
      when "gathering"
        "gathering"
      when "support"
        "support"
      else
        "primary"
      end

    progress.update_columns(slot_kind: kind)
  end
end
