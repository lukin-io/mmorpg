# frozen_string_literal: true

# Purpose: Authorization policy for PVP combat actions.
# Determines who can view, interact with, and perform actions in PVP battles.
#
# Inputs:
#   - user: Current user (may be nil for guests)
#   - battle: Battle record being accessed
#
# Returns:
#   Boolean indicating if action is permitted
#
# Usage:
#   authorize @battle, policy_class: PvpCombatPolicy
#   PvpCombatPolicy.new(current_user, @battle).action?
#
class PvpCombatPolicy < ApplicationPolicy
  # View the battle
  def show?
    return false if user.nil? || record.nil?

    participant?
  end

  # Perform a combat action (attack, defend, skill)
  def action?
    return false if user.nil? || record.nil?

    participant? && record.active? && alive_in_battle?
  end

  # Same as action
  def turn?
    action?
  end

  # Attempt to flee from combat
  def flee?
    action?
  end

  # Surrender the fight
  def surrender?
    return false if user.nil? || record.nil?

    participant? && record.active?
  end

  private

  # Check if user's character is a participant in this battle
  def participant?
    return false unless user&.characters&.any?

    character_ids = user.characters.pluck(:id)
    record.battle_participants.where(character_id: character_ids).exists?
  end

  # Check if user's character is still alive in battle
  def alive_in_battle?
    return false unless user&.characters&.any?

    character_ids = user.characters.pluck(:id)
    record.battle_participants
      .where(character_id: character_ids, is_alive: true)
      .exists?
  end
end
