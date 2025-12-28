# frozen_string_literal: true

# BattleParticipant stores combatants (characters or NPC templates) in a battle.
#
# HP Fields:
# - current_hp: Canonical HP field (use this for all operations)
# - hp_remaining: Legacy field, kept in sync with current_hp for backwards compatibility
#
class BattleParticipant < ApplicationRecord
  belongs_to :battle
  belongs_to :character, optional: true
  belongs_to :npc_template, optional: true

  validates :role, :team, presence: true
  validates :hp_remaining, :initiative, numericality: {greater_than_or_equal_to: 0}
  validates :current_hp, numericality: {greater_than_or_equal_to: 0}, allow_nil: true

  # Keep hp_remaining in sync with current_hp (current_hp is canonical)
  before_save :sync_hp_fields

  scope :alive, -> { where(is_alive: true) }
  scope :dead, -> { where(is_alive: false) }
  scope :by_team, ->(team) { where(team: team) }

  def combatant_name
    character&.name || npc_template&.name || "Unknown"
  end

  # HP percentage for UI display
  #
  # @return [Float] 0-100
  def hp_percent
    return 0 if max_hp.nil? || max_hp.zero?
    ((current_hp.to_f / max_hp) * 100).round(1)
  end

  # Check if participant can act
  #
  # @return [Boolean]
  def can_act?
    is_alive && current_hp.to_i > 0
  end

  private

  def sync_hp_fields
    # Sync hp_remaining to current_hp when current_hp changes
    if current_hp_changed? && current_hp.present?
      self.hp_remaining = current_hp
    end
  end
end
