# frozen_string_literal: true

# NpcTemplate is the central model for all NPC definitions in the game.
# It stores source-backed combat NPC definitions.
#
# Metadata stores combat, loot, image, and spawn data captured from Neverlands.
#
# Usage:
#   # Outside world hostile NPC
#   rat = NpcTemplate.find_by(npc_key: "plague_rat")
#   rat.hostile?           # => true
#   rat.combat_stats       # => { attack: 15, defense: 8, hp: 100, ... }
#
#   # Arena training bot
#   bot = NpcTemplate.find_by(npc_key: "arena_training_dummy")
#   bot.arena_bot?          # => true
#   bot.combat_behavior     # => :passive
#
class NpcTemplate < ApplicationRecord
  include Npc::CombatStats
  include Npc::Combatable

  ROLES = %w[hostile arena_bot].freeze

  validates :name, presence: true, uniqueness: true
  validates :level, numericality: {greater_than: 0}
  validates :role, presence: true, inclusion: {in: ROLES}
  validates :dialogue, presence: true

  # Scope to find NPCs by role
  scope :with_role, ->(role) { where(role: role) }

  # Scope for hostile NPCs only
  scope :hostile, -> { where(role: "hostile") }

  # Scope for arena bot NPCs
  scope :arena_bots, -> { where(role: "arena_bot") }

  def description
    metadata&.dig("description")
  end

  # Get NPC's passive skill level when explicitly captured in metadata.
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :knife_mastery)
  # @return [Integer] skill level (0-100, defaults to 0)
  def passive_skill_level(skill_key)
    key = skill_key.to_s
    skills = metadata&.dig("passive_skills")
    return 0 unless skills

    (skills[key] || skills[skill_key.to_sym]).to_i
  end

  # Get all passive skills for this NPC
  #
  # @return [Hash] skill_key => level
  def passive_skills
    metadata&.dig("passive_skills") || {}
  end

  def health
    max_hp
  end

  # Check if NPC is an arena bot
  def arena_bot?
    role == "arena_bot"
  end

  def ai_behavior
    combat_behavior.to_s
  end

  # Get arena rooms this NPC can appear in
  #
  # @return [Array<String>] array of room slugs
  def arena_rooms
    metadata&.dig("arena_rooms") || []
  end

  def respawn_seconds
    configured_respawn_seconds
  end

  def configured_respawn_seconds
    positive_metadata_integer("respawn_seconds") ||
      positive_metadata_integer("spawn_respawn_seconds")
  end

  def respawn_variance_seconds
    metadata_integer("respawn_variance_seconds") ||
      metadata_integer("spawn_respawn_variance_seconds")
  end

  def avatar_emoji
    metadata&.dig("avatar").presence || name.to_s.first.presence || "N"
  end

  private

  def positive_metadata_integer(key)
    value = metadata_integer(key)
    value if value&.positive?
  end

  def metadata_integer(key)
    value = metadata&.dig(key)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end
end
