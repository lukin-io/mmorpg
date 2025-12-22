# frozen_string_literal: true

module Npc
  # Shared combat interface for all NPC types
  # Provides common methods for determining combat behavior and capabilities
  #
  # Purpose: Standardize the combat interface across NPC types:
  #   - Hostile NPCs in the outside world
  #   - Arena bots for training
  #   - Guards who may attack trespassers
  #   - Trainers for sparring
  #
  # Usage:
  #   class NpcTemplate < ApplicationRecord
  #     include Npc::CombatStats
  #     include Npc::Combatable
  #   end
  #
  #   npc = NpcTemplate.find_by(key: "arena_training_dummy")
  #   npc.can_engage_combat?  # => true
  #   npc.combat_behavior     # => :defensive
  #
  module Combatable
    extend ActiveSupport::Concern

    COMBAT_ROLES = %w[hostile arena_bot guard trainer].freeze
    BEHAVIOR_TYPES = %i[aggressive balanced defensive passive].freeze

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

      # Default behaviors based on role
      case role
      when "hostile"
        :aggressive
      when "arena_bot"
        :balanced
      when "guard", "trainer"
        :defensive
      else
        :passive
      end
    end

    # Get difficulty rating for this NPC
    #
    # @return [Symbol] :easy, :medium, :hard, :elite, :boss
    def difficulty_rating
      difficulty = metadata&.dig("difficulty") || metadata&.dig("rarity")
      return difficulty.to_sym if difficulty.present?

      # Calculate difficulty from level
      case level
      when 1..5 then :easy
      when 6..15 then :medium
      when 16..30 then :hard
      when 31..50 then :elite
      else :boss
      end
    end

    # Check if NPC should flee when HP is low
    #
    # @return [Boolean]
    def can_flee?
      !%w[arena_bot guard].include?(role) && metadata&.dig("can_flee") != false
    end

    # Get the HP threshold at which NPC considers fleeing
    #
    # @return [Float] percentage (0.0 - 1.0)
    def flee_threshold
      metadata&.dig("flee_threshold")&.to_f || 0.15
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
      metadata&.dig("xp_reward") || metadata&.dig("xp") || (level * 10)
    end

    # Get gold reward for defeating this NPC
    #
    # @return [Integer]
    def gold_reward
      metadata&.dig("gold_reward") || metadata&.dig("gold") || (level * 2 + 5)
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
      thresholds = {
        defensive: { hp: 0.7, chance: 0.4 },
        balanced: { hp: 0.4, chance: 0.2 },
        aggressive: { hp: 0.2, chance: 0.1 },
        passive: { hp: 1.0, chance: 0.8 }
      }

      config = thresholds[combat_behavior] || thresholds[:balanced]

      current_hp_ratio < config[:hp] && rng.rand < config[:chance]
    end
  end
end
