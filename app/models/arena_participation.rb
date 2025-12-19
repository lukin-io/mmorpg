# frozen_string_literal: true

# ArenaParticipation tracks combatants in arena matches.
# Supports both player characters and NPC bots.
#
# @example Player participation
#   ArenaParticipation.create!(arena_match: match, character: char, user: user, team: "a")
#
# @example NPC participation
#   ArenaParticipation.create!(arena_match: match, npc_template: npc, team: "b")
#
class ArenaParticipation < ApplicationRecord
  RESULTS = {
    pending: 0,
    victory: 1,
    defeat: 2,
    draw: 3
  }.freeze

  enum :result, RESULTS

  belongs_to :arena_match
  belongs_to :character, optional: true
  belongs_to :user, optional: true
  belongs_to :npc_template, optional: true

  validates :team, presence: true
  validate :has_character_or_npc

  scope :players, -> { where.not(character_id: nil) }
  scope :npcs, -> { where.not(npc_template_id: nil) }

  # Check if this is an NPC participant
  #
  # @return [Boolean] true if participant is an NPC
  def npc?
    npc_template_id.present?
  end

  # Check if this is a player participant
  #
  # @return [Boolean] true if participant is a player
  def player?
    character_id.present?
  end

  # Get the participant name (works for both players and NPCs)
  #
  # @return [String] the participant's name
  def participant_name
    if npc?
      npc_template&.name || "Arena Bot"
    else
      character&.name || "Unknown"
    end
  end

  # Get the participant level (works for both players and NPCs)
  #
  # @return [Integer] the participant's level
  def participant_level
    if npc?
      npc_template&.level || 1
    else
      character&.level || 1
    end
  end

  # Get current HP for the participant
  # For NPCs, this is tracked in metadata since they don't have a Character record
  #
  # @return [Integer] current HP
  def current_hp
    if npc?
      (metadata || {})["current_hp"] || max_hp
    else
      character&.current_hp || 0
    end
  end

  # Set current HP for NPC participants
  #
  # @param hp [Integer] the new HP value
  def current_hp=(hp)
    if npc?
      self.metadata ||= {}
      self.metadata["current_hp"] = [hp, 0].max
    else
      character&.update!(current_hp: [hp, 0].max) if character
    end
  end

  # Get max HP for the participant
  #
  # @return [Integer] max HP
  def max_hp
    if npc?
      npc_template&.health || 100
    else
      character&.max_hp || 100
    end
  end

  # Get stats for the participant (for combat calculations)
  #
  # @return [Hash] stats hash with attack, defense, agility, etc.
  def combat_stats
    if npc?
      Game::World::ArenaNpcConfig.extract_stats(npc_config_hash)
    else
      character&.stats || Game::Systems::StatBlock.new(base: {})
    end
  end

  private

  def has_character_or_npc
    if character_id.blank? && npc_template_id.blank?
      errors.add(:base, "must have either a character or an NPC template")
    end
    if character_id.present? && npc_template_id.present?
      errors.add(:base, "cannot have both a character and an NPC template")
    end
  end

  # Get NPC config hash from ArenaNpcConfig (if available) or build from template
  def npc_config_hash
    return {} unless npc_template

    config = Game::World::ArenaNpcConfig.find_npc(npc_template.npc_key)
    return config if config

    # Fallback to building from NpcTemplate
    {
      key: npc_template.npc_key,
      name: npc_template.name,
      level: npc_template.level,
      hp: npc_template.health,
      damage: npc_template.metadata&.dig("base_damage"),
      metadata: npc_template.metadata
    }
  end
end
