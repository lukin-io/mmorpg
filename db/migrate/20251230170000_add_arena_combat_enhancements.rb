# frozen_string_literal: true

# Add combat enhancements for arena system
# - Turn timeout tracking
# - Trauma system fields
# - Attack type tracking
class AddArenaCombatEnhancements < ActiveRecord::Migration[8.0]
  def change
    # Turn timeout tracking for ArenaMatch
    add_column :arena_matches, :turn_timeout_seconds, :integer, default: 300 # 5 min default
    add_column :arena_matches, :current_turn_started_at, :datetime
    add_column :arena_matches, :current_turn_number, :integer, default: 0
    add_column :arena_matches, :timed_out, :boolean, default: false

    # Trauma system for ArenaMatch (already have trauma_percent in applications)
    add_column :arena_matches, :trauma_percent, :integer, default: 30

    # Track who's turn it is (for turn-based combat)
    add_column :arena_matches, :current_turn_team, :string

    # Index for finding timed out matches
    add_index :arena_matches, [:status, :current_turn_started_at],
      name: "index_arena_matches_on_timeout_check",
      where: "status = 2" # live status
  end
end
