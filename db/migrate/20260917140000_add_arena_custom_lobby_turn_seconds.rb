# frozen_string_literal: true

# Custom PvP lobby: separate turn timer from lobby wait; allow peaceful trauma.
class AddArenaCustomLobbyTurnSeconds < ActiveRecord::Migration[8.1]
  def change
    add_column :arena_applications, :turn_seconds, :integer
    add_index :arena_applications, :turn_seconds
  end
end
