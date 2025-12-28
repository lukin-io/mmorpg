# frozen_string_literal: true

# Migration to improve PVP battle system:
# 1. Add rng_seed to battles for deterministic replay
# 2. Add unique index to prevent duplicate active battles
# 3. Sync hp_remaining with current_hp in battle_participants
class ImprovePvpBattleSystem < ActiveRecord::Migration[8.0]
  def change
    # Add RNG seed for deterministic combat replay
    add_column :battles, :rng_seed, :bigint, null: true

    # Add index for preventing duplicate active battles per initiator
    # A character can only have one active battle at a time
    add_index :battles, [:initiator_id, :status],
      name: "index_battles_on_initiator_active",
      unique: true,
      where: "status = 1" # status = 1 is :active enum value

    # Sync hp_remaining to current_hp values (current_hp is canonical)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE battle_participants
          SET hp_remaining = current_hp
          WHERE current_hp IS NOT NULL
        SQL
      end
    end
  end
end

