# frozen_string_literal: true

# Adds only the missing columns for enhanced combat system.
class AddMissingCombatColumns < ActiveRecord::Migration[8.1]
  def change
    # Battles table - add only missing columns
    unless column_exists?(:battles, :turn_timeout_seconds)
      add_column :battles, :turn_timeout_seconds, :integer, default: 300, null: false
    end

    unless column_exists?(:battles, :turn_timer_ends_at)
      add_column :battles, :turn_timer_ends_at, :datetime
    end

    unless column_exists?(:battles, :winning_team)
      add_column :battles, :winning_team, :string
    end

    # Battle participants table - add only missing columns
    unless column_exists?(:battle_participants, :active_effects)
      add_column :battle_participants, :active_effects, :jsonb, default: [], null: false
    end

    unless column_exists?(:battle_participants, :turn_submitted_at)
      add_column :battle_participants, :turn_submitted_at, :datetime
    end

    # Add indexes if they don't exist
    unless index_exists?(:battles, :turn_timer_ends_at)
      add_index :battles, :turn_timer_ends_at,
        where: "turn_timer_ends_at IS NOT NULL AND status = 1",
        name: "index_battles_on_turn_timer_ends_at"
    end

    unless index_exists?(:battle_participants, :turn_submitted_at)
      add_index :battle_participants, :turn_submitted_at,
        where: "turn_submitted_at IS NOT NULL",
        name: "index_battle_participants_on_turn_submitted"
    end
  end
end
