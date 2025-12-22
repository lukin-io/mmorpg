# frozen_string_literal: true

module Npc
  # Shared stat calculation logic for all NPC types
  # Provides a unified interface for extracting combat stats from NpcTemplate
  #
  # Purpose: Centralize NPC stat calculation to ensure consistency across:
  #   - Outside world PvE combat (TileNpc via NpcTemplate)
  #   - Arena bot combat (ArenaApplication via NpcTemplate)
  #   - Any future NPC combat contexts
  #
  # Usage:
  #   class NpcTemplate < ApplicationRecord
  #     include Npc::CombatStats
  #   end
  #
  #   npc = NpcTemplate.find_by(key: "forest_wolf")
  #   npc.combat_stats  # => { attack: 15, defense: 8, agility: 10, hp: 100, ... }
  #
  module CombatStats
    extend ActiveSupport::Concern

    # Default stat formulas based on NPC level
    STAT_FORMULAS = {
      attack: ->(level) { level * 3 + 5 },
      defense: ->(level) { level * 2 + 3 },
      agility: ->(level) { level + 5 },
      hp: ->(level) { level * 10 + 20 },
      crit_chance: ->(_level) { 10 },
      dodge_chance: ->(level) { [level / 2, 25].min }
    }.freeze

    # Role-specific stat modifiers (multipliers)
    ROLE_MODIFIERS = {
      "hostile" => {attack: 1.0, defense: 1.0, hp: 1.0},
      "arena_bot" => {attack: 0.9, defense: 0.9, hp: 0.95},  # Slightly weaker for training
      "guard" => {attack: 1.2, defense: 1.5, hp: 1.3},
      "trainer" => {attack: 1.1, defense: 1.1, hp: 1.0},
      "quest_giver" => {attack: 0.5, defense: 0.5, hp: 0.8},
      "vendor" => {attack: 0.3, defense: 0.3, hp: 0.5}
    }.freeze

    # Get all combat stats as a unified hash
    #
    # @param override_level [Integer, nil] optional level override for scaling
    # @return [HashWithIndifferentAccess] combat stats
    def combat_stats(override_level: nil)
      effective_level = override_level || level || 1

      # Priority: explicit metadata stats > calculated from metadata fields > formula defaults
      base_stats = calculate_base_stats(effective_level)
      role_stats = apply_role_modifiers(base_stats)

      role_stats.with_indifferent_access
    end

    # Get a single combat stat
    #
    # @param stat_name [Symbol, String] the stat to retrieve (:attack, :defense, etc.)
    # @param override_level [Integer, nil] optional level override
    # @return [Integer] the stat value
    def combat_stat(stat_name, override_level: nil)
      combat_stats(override_level: override_level)[stat_name.to_sym] || 0
    end

    # Get max HP for this NPC (convenience method)
    #
    # @return [Integer]
    def max_hp
      combat_stat(:hp)
    end

    # Get attack power (convenience method)
    #
    # @return [Integer]
    def attack_power
      combat_stat(:attack)
    end

    # Get defense value (convenience method)
    #
    # @return [Integer]
    def defense_value
      combat_stat(:defense)
    end

    # Calculate damage range for attacks
    #
    # @return [Range] min..max damage
    def attack_damage_range
      base = attack_power
      variance = [base / 4, 1].max
      (base - variance)..(base + variance)
    end

    private

    def calculate_base_stats(effective_level)
      # First, check if metadata has explicit "stats" hash (highest priority)
      if (explicit_stats = metadata&.dig("stats"))
        return normalize_stats(explicit_stats)
      end

      # Second, build from individual metadata fields
      stats_from_metadata = build_stats_from_metadata(effective_level)

      # Third, fill in any missing stats with formula defaults
      STAT_FORMULAS.each_key do |stat|
        next if stats_from_metadata[stat].present?
        stats_from_metadata[stat] = STAT_FORMULAS[stat].call(effective_level)
      end

      stats_from_metadata
    end

    def build_stats_from_metadata(effective_level)
      stats = {}

      # Map common metadata fields to stats
      stats[:attack] = metadata&.dig("base_damage") || metadata&.dig("damage")
      stats[:hp] = metadata&.dig("health") || metadata&.dig("hp")
      stats[:defense] = metadata&.dig("base_defense") || metadata&.dig("defense")
      stats[:agility] = metadata&.dig("base_agility") || metadata&.dig("agility")
      stats[:crit_chance] = metadata&.dig("crit_chance")
      stats[:dodge_chance] = metadata&.dig("dodge_chance")

      # Filter out nil values
      stats.compact
    end

    def normalize_stats(raw_stats)
      STAT_FORMULAS.keys.each_with_object({}) do |stat, result|
        result[stat] = raw_stats[stat.to_s] || raw_stats[stat] || STAT_FORMULAS[stat].call(level || 1)
      end
    end

    def apply_role_modifiers(base_stats)
      modifiers = ROLE_MODIFIERS[role] || ROLE_MODIFIERS["hostile"]

      base_stats.transform_values.with_index do |value, index|
        stat_name = base_stats.keys[index]
        modifier = modifiers[stat_name] || 1.0
        (value * modifier).to_i
      end

      # More explicit approach to avoid index issues
      result = {}
      base_stats.each do |stat_name, value|
        modifier = modifiers[stat_name.to_sym] || 1.0
        result[stat_name] = (value * modifier).to_i
      end
      result
    end
  end
end
