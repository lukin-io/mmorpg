# frozen_string_literal: true

# BattleParticipant stores combatants (characters or NPC templates) in a battle.
#
# HP Fields:
# - current_hp: Canonical HP field (use this for all operations)
# - hp_remaining: Legacy field, kept in sync with current_hp for backwards compatibility
#
# Combat Actions:
# - pending_attacks: Array of attack selections for current turn
# - pending_blocks: Array of block selections for current turn
# - pending_skills: Array of skill/magic selections for current turn
#
# Effects:
# - active_effects: Array of active buffs/debuffs with duration tracking
# - combat_buffs: Legacy buff storage for backward compatibility
#
class BattleParticipant < ApplicationRecord
  PARTICIPANT_TYPES = %w[player npc].freeze

  belongs_to :battle
  belongs_to :character, optional: true
  belongs_to :npc_template, optional: true

  validates :role, :team, presence: true
  validates :hp_remaining, :initiative, numericality: {greater_than_or_equal_to: 0}
  validates :current_hp, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validates :participant_type, inclusion: {in: PARTICIPANT_TYPES}, allow_nil: true

  # Keep hp_remaining in sync with current_hp (current_hp is canonical)
  before_save :sync_hp_fields
  before_create :set_participant_type

  scope :alive, -> { where(is_alive: true) }
  scope :dead, -> { where(is_alive: false) }
  scope :by_team, ->(team) { where(team: team) }
  scope :players, -> { where(participant_type: "player") }
  scope :npcs, -> { where(participant_type: "npc") }
  scope :with_pending_actions, -> { where.not(pending_attacks: []).or(where.not(pending_blocks: [])).or(where.not(pending_skills: [])) }
  scope :turn_submitted, -> { where.not(turn_submitted_at: nil) }

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

  # MP percentage for UI display
  #
  # @return [Float] 0-100
  def mp_percent
    return 0 if max_mp.nil? || max_mp.zero?
    ((current_mp.to_f / max_mp) * 100).round(1)
  end

  # Check if participant can act
  #
  # @return [Boolean]
  def can_act?
    is_alive && current_hp.to_i > 0 && !stunned?
  end

  # Check if participant is an NPC
  #
  # @return [Boolean]
  def npc?
    participant_type == "npc" || npc_template.present?
  end

  # Check if participant is a player
  #
  # @return [Boolean]
  def player?
    participant_type == "player" || character.present?
  end

  # Check if participant has submitted turn
  #
  # @return [Boolean]
  def turn_submitted?
    turn_submitted_at.present?
  end

  # Check if participant is stunned (cannot act)
  #
  # @return [Boolean]
  def stunned?
    effects = active_effects || []
    effects.any? { |e| e["type"] == "stun" && (e["remaining_duration"] || e["duration"]).to_i > 0 }
  end

  # Submit turn actions
  #
  # @param attacks [Array<Hash>] attack selections
  # @param blocks [Array<Hash>] block selections
  # @param skills [Array<Hash>] skill selections
  # @param ap_used [Integer] action points used
  def submit_turn!(attacks: [], blocks: [], skills: [], ap_used: 0)
    update!(
      pending_attacks: attacks,
      pending_blocks: blocks,
      pending_skills: skills,
      action_points_used: ap_used,
      turn_submitted_at: Time.current
    )
  end

  # Clear turn submission (after resolution)
  def clear_turn!
    update!(
      pending_attacks: [],
      pending_blocks: [],
      pending_skills: [],
      action_points_used: 0,
      turn_submitted_at: nil
    )
  end

  # Add an effect to this participant
  #
  # @param effect [Hash] effect data
  def add_effect!(effect)
    effects = active_effects || []
    effects << effect.stringify_keys
    update!(active_effects: effects)
  end

  # Remove expired effects
  def tick_effects!
    effects = active_effects || []
    updated = effects.map do |e|
      e["remaining_duration"] = (e["remaining_duration"] || e["duration"]).to_i - 1
      e
    end.select { |e| e["remaining_duration"] > 0 }
    update!(active_effects: updated)
  end

  # Get total damage reduction from active shield effects
  #
  # @return [Float] 0-1
  def total_damage_reduction
    effects = active_effects || []
    shield_effects = effects.select { |e| %w[shield barrier immunity].include?(e["type"]) }
    return 0.0 if shield_effects.empty?

    # Stack multiplicatively
    shield_effects.reduce(0.0) do |total, effect|
      reduction = effect["damage_reduction"].to_f
      total + (1 - total) * reduction
    end
  end

  # Get the entity (Character or NpcTemplate) for stat access
  #
  # @return [Character, NpcTemplate, nil]
  def entity
    character || npc_template
  end

  private

  def sync_hp_fields
    # Sync hp_remaining to current_hp when current_hp changes
    if current_hp_changed? && current_hp.present?
      self.hp_remaining = current_hp
    end
  end

  def set_participant_type
    self.participant_type ||= if character_id.present?
      "player"
    elsif npc_template_id.present?
      "npc"
    else
      "player"
    end
  end
end
