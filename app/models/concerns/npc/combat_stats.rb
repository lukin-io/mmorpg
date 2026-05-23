# frozen_string_literal: true

module Npc
  # Shared stat access for source-backed NPCs. Stats are read from captured
  # metadata only; no level-derived generic formulas are invented here.
  module CombatStats
    extend ActiveSupport::Concern

    STAT_KEYS = %i[
      attack defense agility hp crit_chance dodge_chance dexterity evasion
      accuracy luck armor_penetration
    ].freeze

    # Get all combat stats as a unified hash
    #
    # @param override_level [Integer, nil] optional level override for scaling
    # @return [HashWithIndifferentAccess] combat stats
    def combat_stats(override_level: nil)
      normalize_stats(explicit_stat_metadata).with_indifferent_access
    end

    # Get a single combat stat
    #
    # @param stat_name [Symbol, String] the stat to retrieve (:attack, :defense, etc.)
    # @param override_level [Integer, nil] optional level override
    # @return [Integer] the stat value
    def combat_stat(stat_name, override_level: nil)
      combat_stats(override_level: override_level)[stat_name.to_sym].to_i
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
      return 0..0 if base <= 0

      variance = [base / 4, 1].max
      (base - variance)..(base + variance)
    end

    private

    def explicit_stat_metadata
      stats = (metadata&.dig("stats") || {}).to_h.symbolize_keys
      stats[:attack] ||= metadata&.dig("base_damage") || metadata&.dig("damage")
      stats[:hp] ||= metadata&.dig("health") || metadata&.dig("hp")
      stats[:defense] ||= metadata&.dig("base_defense") || metadata&.dig("defense")
      stats[:agility] ||= metadata&.dig("base_agility") || metadata&.dig("agility")
      stats[:crit_chance] ||= metadata&.dig("crit_chance")
      stats[:dodge_chance] ||= metadata&.dig("dodge_chance")
      stats.compact
    end

    def normalize_stats(raw_stats)
      STAT_KEYS.each_with_object({}) do |stat, result|
        result[stat] = (raw_stats[stat.to_s] || raw_stats[stat] || 0).to_i
      end
    end
  end
end
