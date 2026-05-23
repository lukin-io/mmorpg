# frozen_string_literal: true

module Npc
  # Shared combat interface for source-backed combat NPC types.
  module Combatable
    extend ActiveSupport::Concern

    COMBAT_ROLES = %w[hostile arena_bot].freeze
    BEHAVIOR_TYPES = %i[aggressive passive].freeze

    # Check if this NPC can engage in combat
    #
    # @return [Boolean]
    def can_engage_combat?
      COMBAT_ROLES.include?(role)
    end

    # Check if NPC is hostile (will attack on sight)
    #
    # @return [Boolean]
    def hostile?
      role == "hostile"
    end

    # Check if NPC can be attacked
    #
    # @return [Boolean]
    def attackable?
      can_engage_combat?
    end

    # Get combat behavior type
    #
    # @return [Symbol] :aggressive, :balanced, :defensive, or :passive
    def combat_behavior
      behavior = metadata&.dig("ai_behavior") || metadata&.dig("behavior")
      return behavior.to_sym if behavior.present? && BEHAVIOR_TYPES.include?(behavior.to_sym)

      # Hostile outdoor NPC attacks are source-backed; arena NPC behavior should
      # come from captured metadata and otherwise remains passive.
      case role
      when "hostile"
        :aggressive
      else
        :passive
      end
    end

    # Get loot table for drops
    #
    # @return [Array<Hash>] loot entries with item_key and chance
    def loot_table
      metadata&.dig("loot_table") || metadata&.dig("loot") || []
    end

    # Get XP reward for defeating this NPC
    #
    # @return [Integer]
    def xp_reward
      (metadata&.dig("xp_reward") || metadata&.dig("xp") || 0).to_i
    end

    # Generate combat initiative for turn order
    #
    # @param rng [Random] seeded random for determinism
    # @return [Integer]
    def roll_initiative(rng: Random.new)
      agility = combat_stat(:agility)
      agility + rng.rand(1..10)
    end

    # Determine if NPC should defend this turn based on behavior and HP
    #
    # @param current_hp_ratio [Float] current HP percentage (0.0 - 1.0)
    # @param rng [Random] seeded random for determinism
    # @return [Boolean]
    def should_defend?(current_hp_ratio:, rng: Random.new)
      hp_threshold = metadata&.dig("defend_hp_below")
      chance = metadata&.dig("defend_chance")
      return false if hp_threshold.blank? || chance.blank?

      current_hp_ratio < hp_threshold.to_f && rng.rand < chance.to_f
    end
  end
end
