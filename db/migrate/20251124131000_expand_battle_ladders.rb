# frozen_string_literal: true

class ExpandBattleLadders < ActiveRecord::Migration[8.1]
  def change
    add_column :battles, :pvp_mode, :string

    add_column :arena_rankings, :ladder_type, :string, null: false, default: "arena"
    remove_index :arena_rankings, :character_id
    add_index :arena_rankings, [:character_id, :ladder_type], unique: true
  end
end
