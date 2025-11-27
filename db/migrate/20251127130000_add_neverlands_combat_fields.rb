# frozen_string_literal: true

class AddNeverlandsCombatFields < ActiveRecord::Migration[8.0]
  def change
    # Add combat mode and action point tracking to battles
    add_column :battles, :combat_mode, :string, default: "standard"
    add_column :battles, :round_number, :integer, default: 1
    add_column :battles, :current_turn_character_id, :integer
    add_column :battles, :action_points_per_turn, :integer, default: 80
    add_column :battles, :max_mana_per_turn, :integer, default: 50

    # Add body-part HP tracking to participants
    add_column :battle_participants, :current_hp, :integer, default: 100
    add_column :battle_participants, :current_mp, :integer, default: 50
    add_column :battle_participants, :max_hp, :integer, default: 100
    add_column :battle_participants, :max_mp, :integer, default: 50

    # Body part damage tracking
    add_column :battle_participants, :body_damage, :jsonb, default: {
      "head" => 0,
      "torso" => 0,
      "stomach" => 0,
      "legs" => 0
    }

    # Combat buffs/debuffs per body part
    add_column :battle_participants, :combat_buffs, :jsonb, default: []

    # Pending actions for current turn
    add_column :battle_participants, :pending_attacks, :jsonb, default: []
    add_column :battle_participants, :pending_blocks, :jsonb, default: []
    add_column :battle_participants, :pending_skills, :jsonb, default: []

    # Action points used this turn
    add_column :battle_participants, :action_points_used, :integer, default: 0
    add_column :battle_participants, :mana_used, :integer, default: 0

    # Participant status
    add_column :battle_participants, :participant_type, :string, default: "player"
    add_column :battle_participants, :is_alive, :boolean, default: true
    add_column :battle_participants, :fatigue, :decimal, precision: 5, scale: 2, default: 100.0

    # Combat statistics
    add_column :battle_participants, :damage_dealt, :jsonb, default: {
      "normal" => 0,
      "fire" => 0,
      "water" => 0,
      "earth" => 0,
      "air" => 0,
      "total" => 0
    }
    add_column :battle_participants, :damage_received, :jsonb, default: {
      "normal" => 0,
      "fire" => 0,
      "water" => 0,
      "earth" => 0,
      "air" => 0,
      "total" => 0
    }
    add_column :battle_participants, :hits_landed, :integer, default: 0
    add_column :battle_participants, :hits_blocked, :integer, default: 0

    # Add log_type to combat_log_entries
    add_column :combat_log_entries, :log_type, :string, default: "action"
    add_column :combat_log_entries, :actor_id, :integer
    add_column :combat_log_entries, :target_id, :integer

    add_index :battle_participants, [:battle_id, :is_alive]
    add_index :combat_log_entries, :log_type
  end
end
