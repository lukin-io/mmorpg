# frozen_string_literal: true

module Game
  module Skills
    # PassiveSkillRegistry defines all available passive skills and their effects.
    #
    # Passive skills are abilities that:
    # - Level from 0 to 100
    # - Provide ongoing bonuses/modifiers
    # - Can grow with character level or experience
    #
    # Purpose:
    #   Central registry for passive skill definitions. Each skill defines its
    #   key, name, description, max level, and effect calculation.
    #
    # Inputs:
    #   - skill_key: Symbol key identifying the skill (e.g., :wanderer)
    #
    # Returns:
    #   Skill definition hash with all configuration
    #
    # Usage:
    #   definition = Game::Skills::PassiveSkillRegistry.find(:wanderer)
    #   # => { key: :wanderer, name: "Wanderer", max_level: 100, ... }
    #
    #   Game::Skills::PassiveSkillRegistry.all_keys
    #   # => [:wanderer, :endurance, ...]
    #
    class PassiveSkillRegistry
      MAX_LEVEL = 100

      # Skill definitions with their effects and formulas
      # Each skill has:
      #   - key: unique identifier
      #   - name: display name
      #   - description: what the skill does
      #   - max_level: maximum level (default 100)
      #   - category: grouping for UI (movement, combat, survival, etc.)
      #   - effect_type: what game mechanic this affects
      #   - effect_formula: lambda that calculates the effect value
      #
      SKILLS = {
        wanderer: {
          key: :wanderer,
          name: "Wanderer",
          description: "Increases movement speed on the world map. Reduces travel time between tiles.",
          max_level: MAX_LEVEL,
          category: :movement,
          effect_type: :movement_cooldown_reduction,
          # Formula: At level 0 = 0% reduction, at level 100 = 70% reduction
          # This means: 10s base * (1 - 0.70) = 3s at max level
          effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.70 }
        }

        # Future skills can be added here:
        #
        # endurance: {
        #   key: :endurance,
        #   name: "Endurance",
        #   description: "Increases maximum HP and HP regeneration rate.",
        #   max_level: MAX_LEVEL,
        #   category: :survival,
        #   effect_type: :hp_bonus,
        #   effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.50 }
        # },
        #
        # perception: {
        #   key: :perception,
        #   name: "Perception",
        #   description: "Increases chance to find rare resources and hidden paths.",
        #   max_level: MAX_LEVEL,
        #   category: :exploration,
        #   effect_type: :discovery_bonus,
        #   effect_formula: ->(level) { (level.to_f / MAX_LEVEL) * 0.30 }
        # }
      }.freeze

      class << self
        # Find a skill definition by key
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Hash, nil] skill definition or nil if not found
        def find(skill_key)
          SKILLS[skill_key.to_sym]
        end

        # Get all registered skill keys
        #
        # @return [Array<Symbol>] list of all skill keys
        def all_keys
          SKILLS.keys
        end

        # Get all skill definitions
        #
        # @return [Hash] all skill definitions
        def all
          SKILLS
        end

        # Get skills by category
        #
        # @param category [Symbol] the category to filter by
        # @return [Array<Hash>] skills in that category
        def by_category(category)
          SKILLS.values.select { |skill| skill[:category] == category.to_sym }
        end

        # Check if a skill key is valid
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Boolean] true if skill exists
        def valid?(skill_key)
          SKILLS.key?(skill_key.to_sym)
        end

        # Calculate the effect value for a skill at a given level
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @param level [Integer] the skill level (0-100)
        # @return [Float] the calculated effect value
        def calculate_effect(skill_key, level)
          definition = find(skill_key)
          return 0.0 unless definition

          clamped_level = level.to_i.clamp(0, definition[:max_level])
          definition[:effect_formula].call(clamped_level)
        end

        # Get the max level for a skill
        #
        # @param skill_key [Symbol, String] the skill identifier
        # @return [Integer] max level (default 100)
        def max_level(skill_key)
          find(skill_key)&.dig(:max_level) || MAX_LEVEL
        end
      end
    end
  end
end
