# frozen_string_literal: true

# NpcTemplate is the central model for all NPC definitions in the game.
# It uses a unified architecture where all NPCs share common attributes and behaviors,
# with role-specific extensions via metadata and concerns.
#
# Architecture (similar to STI but using role + metadata):
#   - Base attributes: name, level, role, dialogue, metadata (JSONB)
#   - Shared behaviors: Npc::CombatStats (stat calculation), Npc::Combatable (combat interface)
#   - Role determines behavior: hostile, arena_bot, quest_giver, vendor, guard, etc.
#   - Metadata stores role-specific data (AI behavior, loot tables, shop inventory, etc.)
#
# Usage:
#   # Outside world hostile NPC
#   wolf = NpcTemplate.find_by(npc_key: "forest_wolf")
#   wolf.hostile?           # => true
#   wolf.combat_stats       # => { attack: 15, defense: 8, hp: 100, ... }
#
#   # Arena training bot
#   bot = NpcTemplate.find_by(npc_key: "arena_training_dummy")
#   bot.arena_bot?          # => true
#   bot.combat_behavior     # => :defensive
#   bot.difficulty_rating   # => :easy
#
class NpcTemplate < ApplicationRecord
  include Npc::CombatStats
  include Npc::Combatable

  ROLES = %w[quest_giver vendor trainer guard innkeeper banker auctioneer crafter hostile lore arena_bot friendly].freeze

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

  # Get NPC's passive skill level (for combat formula integration)
  # NPCs can have passive skills defined in metadata for balanced fights
  #
  # @param skill_key [Symbol, String] the skill identifier (e.g., :melee_combat)
  # @return [Integer] skill level (0-100, defaults to level-based value)
  def passive_skill_level(skill_key)
    key = skill_key.to_s

    # First, check explicit passive_skills in metadata
    if (skills = metadata&.dig("passive_skills"))
      return (skills[key] || skills[skill_key.to_sym]).to_i if skills[key] || skills[skill_key.to_sym]
    end

    # Second, calculate default based on NPC level and role
    calculate_default_skill_level(skill_key)
  end

  # Get all passive skills for this NPC
  #
  # @return [Hash] skill_key => level
  def passive_skills
    metadata&.dig("passive_skills") || calculate_default_passive_skills
  end

  private

  # Calculate default skill level based on NPC level
  # Higher level NPCs get proportionally higher skill levels
  # Combat NPCs get higher combat skills, etc.
  def calculate_default_skill_level(skill_key)
    key = skill_key.to_sym
    base_level = (level || 1) * 2  # Level 10 NPC = ~20 skill

    # Combat roles get bonus to combat skills
    combat_skills = %i[melee_combat ranged_combat critical_strikes evasion block_mastery]
    magic_skills = %i[elemental_magic healing_arts arcane_power spell_mastery]
    resistance_skills = %i[fire_resistance cold_resistance lightning_resistance physical_fortitude]

    multiplier = 1.0

    if hostile? || arena_bot?
      multiplier = 1.2 if combat_skills.include?(key)
      multiplier = 0.8 if magic_skills.include?(key)
      multiplier = 1.0 if resistance_skills.include?(key)
    end

    # Difficulty scaling for arena bots
    if arena_bot?
      case difficulty_rating
      when :easy then multiplier *= 0.6
      when :medium then multiplier *= 0.85
      when :hard then multiplier *= 1.1
      end
    end

    (base_level * multiplier).to_i.clamp(0, 100)
  end

  def calculate_default_passive_skills
    skills = {}
    %i[
      melee_combat ranged_combat critical_strikes evasion block_mastery
      elemental_magic fire_resistance cold_resistance lightning_resistance
      physical_fortitude
    ].each do |skill|
      skills[skill.to_s] = calculate_default_skill_level(skill)
    end
    skills
  end

  # ============================================================================
  # Public API (legacy methods and public accessors)
  # ============================================================================
  public

  # Legacy method - delegates to combat_stats for backward compatibility
  # @deprecated Use #max_hp instead
  def health
    max_hp
  end

  # Legacy method - delegates to attack_damage_range for backward compatibility
  # @deprecated Use #attack_damage_range instead
  def damage_range
    attack_damage_range
  end

  # Check if NPC is an arena bot
  def arena_bot?
    role == "arena_bot"
  end

  # Get arena-specific AI behavior (string version for backward compatibility)
  #
  # @return [String] AI behavior type (defensive, balanced, aggressive)
  # @see #combat_behavior for Symbol version from Npc::Combatable
  def ai_behavior
    combat_behavior.to_s
  end

  # Get arena difficulty level (string version for backward compatibility)
  #
  # @return [String] difficulty (easy, medium, hard)
  # @see #difficulty_rating for Symbol version from Npc::Combatable
  def arena_difficulty
    difficulty_rating.to_s
  end

  # Get arena rooms this NPC can appear in
  #
  # @return [Array<String>] array of room slugs
  def arena_rooms
    metadata&.dig("arena_rooms") || []
  end

  # Get NPC avatar emoji for display (legacy, for backward compatibility)
  #
  # @return [String] emoji avatar
  def avatar_emoji
    metadata&.dig("avatar") || "⚔️"
  end

  # Get NPC avatar image filename for display
  # Arena bots use scarecrow, open world NPCs use monster images
  #
  # @return [String] avatar image filename (without path, with extension)
  def avatar_image
    # Explicit override in metadata takes priority
    if metadata&.dig("avatar_image").present?
      return metadata["avatar_image"]
    end

    # Arena bots always use scarecrow
    return "scarecrow.png" if arena_bot?

    # Match NPC key to available monster images
    key = npc_key.to_s.downcase
    available_npc_images = %w[wolf boar skeleton zombie]

    available_npc_images.each do |img|
      return "#{img}.png" if key.include?(img)
    end

    # Fallback based on role/type
    hostile? ? available_npc_images.sample + ".png" : "skeleton.png"
  end

  # Get full asset path for NPC avatar image
  #
  # @return [String] full asset path
  def avatar_image_path
    "npc/#{avatar_image}"
  end
end
