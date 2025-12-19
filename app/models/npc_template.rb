# frozen_string_literal: true

class NpcTemplate < ApplicationRecord
  ROLES = %w[quest_giver vendor trainer guard innkeeper banker auctioneer crafter hostile lore arena_bot].freeze

  validates :name, presence: true, uniqueness: true
  validates :level, numericality: {greater_than: 0}
  validates :role, presence: true, inclusion: {in: ROLES}
  validates :dialogue, presence: true

  # Scope to find NPCs that can appear in a specific zone
  # Using jsonb_exists() instead of ? operator to avoid Rails bind variable conflicts
  scope :in_zone, ->(zone_name) {
    where("metadata->>'zone' = :zone OR jsonb_exists(metadata->'zones', :zone)", zone: zone_name)
  }

  # Scope to find NPCs by role
  scope :with_role, ->(role) { where(role: role) }

  # Scope for hostile NPCs only
  scope :hostile, -> { where(role: "hostile") }

  # Scope for non-hostile NPCs
  scope :friendly, -> { where.not(role: "hostile") }

  # Scope for arena bot NPCs
  scope :arena_bots, -> { where(role: "arena_bot") }

  # Check if NPC can spawn at a specific position
  def can_spawn_at?(zone:, x: nil, y: nil)
    zone_name = zone.respond_to?(:name) ? zone.name : zone.to_s

    # Check if NPC is allowed in this zone
    allowed_zone = metadata&.dig("zone") == zone_name ||
      metadata&.dig("zones")&.include?(zone_name) ||
      metadata&.dig("zones").nil?

    return false unless allowed_zone

    # Check position restrictions if any
    if x && y && metadata&.dig("spawn_area")
      area = metadata["spawn_area"]
      return false if x < (area["min_x"] || 0) || x > (area["max_x"] || 999)
      return false if y < (area["min_y"] || 0) || y > (area["max_y"] || 999)
    end

    # Check biome restrictions
    if zone.respond_to?(:biome) && metadata&.dig("biomes")
      return false unless metadata["biomes"].include?(zone.biome)
    end

    true
  end

  # Get greeting based on NPC metadata
  def greeting
    greetings = metadata&.dig("greetings") || []
    greetings.sample || dialogue
  end

  # Check if NPC has shop inventory
  def vendor?
    role == "vendor" && metadata&.dig("inventory").present?
  end

  # Check if NPC can train skills
  def trainer?
    role == "trainer" && metadata&.dig("teaches").present?
  end

  # Get NPC's faction
  def faction
    metadata&.dig("faction")
  end

  # Get NPC's description
  def description
    metadata&.dig("description") || dialogue
  end

  # Get NPC health for combat
  def health
    metadata&.dig("health") || (level * 20) + 50
  end

  # Get NPC damage range for combat
  def damage_range
    base = level * 2 + 5
    (base..base + level)
  end

  # Check if NPC is an arena bot
  def arena_bot?
    role == "arena_bot"
  end

  # Get arena-specific AI behavior
  #
  # @return [String] AI behavior type (defensive, balanced, aggressive)
  def ai_behavior
    metadata&.dig("ai_behavior") || "balanced"
  end

  # Get arena difficulty level
  #
  # @return [String] difficulty (easy, medium, hard)
  def arena_difficulty
    metadata&.dig("difficulty") || "medium"
  end

  # Get arena rooms this NPC can appear in
  #
  # @return [Array<String>] array of room slugs
  def arena_rooms
    metadata&.dig("arena_rooms") || []
  end

  # Get NPC avatar emoji for display
  #
  # @return [String] emoji avatar
  def avatar_emoji
    metadata&.dig("avatar") || "⚔️"
  end
end
