# frozen_string_literal: true

class RemoveLegacyTacticalArenaAndBetting < ActiveRecord::Migration[8.1]
  def up
    drop_table :arena_bets, if_exists: true
    drop_table :tactical_combat_log_entries, if_exists: true
    drop_table :tactical_participants, if_exists: true
    drop_table :tactical_matches, if_exists: true
  end

  def down
    # Legacy tactical grid and betting tables are intentionally not restored.
  end
end
