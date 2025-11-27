# frozen_string_literal: true

class AddCombatFields < ActiveRecord::Migration[8.0]
  def change
    # Add combat mode and action point tracking to battles
    add_column :battles, :combat_mode, :string, default: "standard" unless column_exists?(:battles, :combat_mode)
    add_column :battles, :round_number, :integer, default: 1 unless column_exists?(:battles, :round_number)
    add_column :battles, :current_turn_character_id, :integer unless column_exists?(:battles, :current_turn_character_id)
    add_column :battles, :action_points_per_turn, :integer, default: 80 unless column_exists?(:battles, :action_points_per_turn)
    add_column :battles, :max_mana_per_turn, :integer, default: 50 unless column_exists?(:battles, :max_mana_per_turn)

    # Add body-part HP tracking to participants
    add_column :battle_participants, :current_hp, :integer, default: 100 unless column_exists?(:battle_participants, :current_hp)
    add_column :battle_participants, :current_mp, :integer, default: 50 unless column_exists?(:battle_participants, :current_mp)
    add_column :battle_participants, :max_hp, :integer, default: 100 unless column_exists?(:battle_participants, :max_hp)
    add_column :battle_participants, :max_mp, :integer, default: 50 unless column_exists?(:battle_participants, :max_mp)

    # Body part damage tracking
    unless column_exists?(:battle_participants, :body_damage)
      add_column :battle_participants, :body_damage, :jsonb, default: {
        "head" => 0,
        "torso" => 0,
        "stomach" => 0,
        "legs" => 0
      }
    end

    # Combat buffs/debuffs per body part
    add_column :battle_participants, :combat_buffs, :jsonb, default: [] unless column_exists?(:battle_participants, :combat_buffs)

    # Pending actions for current turn
    add_column :battle_participants, :pending_attacks, :jsonb, default: [] unless column_exists?(:battle_participants, :pending_attacks)
    add_column :battle_participants, :pending_blocks, :jsonb, default: [] unless column_exists?(:battle_participants, :pending_blocks)
    add_column :battle_participants, :pending_skills, :jsonb, default: [] unless column_exists?(:battle_participants, :pending_skills)

    # Action points used this turn
    add_column :battle_participants, :action_points_used, :integer, default: 0 unless column_exists?(:battle_participants, :action_points_used)
    add_column :battle_participants, :mana_used, :integer, default: 0 unless column_exists?(:battle_participants, :mana_used)

    # Participant status
    add_column :battle_participants, :participant_type, :string, default: "player" unless column_exists?(:battle_participants, :participant_type)
    add_column :battle_participants, :is_alive, :boolean, default: true unless column_exists?(:battle_participants, :is_alive)
    add_column :battle_participants, :fatigue, :decimal, precision: 5, scale: 2, default: 100.0 unless column_exists?(:battle_participants, :fatigue)

    # Combat statistics
    unless column_exists?(:battle_participants, :damage_dealt)
      add_column :battle_participants, :damage_dealt, :jsonb, default: {
        "normal" => 0,
        "fire" => 0,
        "water" => 0,
        "earth" => 0,
        "air" => 0,
        "total" => 0
      }
    end
    unless column_exists?(:battle_participants, :damage_received)
      add_column :battle_participants, :damage_received, :jsonb, default: {
        "normal" => 0,
        "fire" => 0,
        "water" => 0,
        "earth" => 0,
        "air" => 0,
        "total" => 0
      }
    end
    add_column :battle_participants, :hits_landed, :integer, default: 0 unless column_exists?(:battle_participants, :hits_landed)
    add_column :battle_participants, :hits_blocked, :integer, default: 0 unless column_exists?(:battle_participants, :hits_blocked)

    # Add log_type to combat_log_entries
    add_column :combat_log_entries, :log_type, :string, default: "action" unless column_exists?(:combat_log_entries, :log_type)
    add_column :combat_log_entries, :actor_id, :integer unless column_exists?(:combat_log_entries, :actor_id)
    add_column :combat_log_entries, :target_id, :integer unless column_exists?(:combat_log_entries, :target_id)

    add_index :battle_participants, [:battle_id, :is_alive] unless index_exists?(:battle_participants, [:battle_id, :is_alive])
    add_index :combat_log_entries, :log_type unless index_exists?(:combat_log_entries, :log_type)
  end
end
