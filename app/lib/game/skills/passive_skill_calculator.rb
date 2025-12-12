# frozen_string_literal: true

module Game
  module Skills
    # PassiveSkillCalculator computes actual game effects from passive skill levels.
    #
    # Purpose:
    #   Apply passive skill modifiers to game mechanics (movement, combat, etc.)
    #
    # Inputs:
    #   - character: Character model with passive_skills JSONB
    #
    # Returns:
    #   Computed modifier values for various game mechanics
    #
    # Usage:
    #   calculator = Game::Skills::PassiveSkillCalculator.new(character)
    #   calculator.movement_cooldown_modifier  # => 0.35 (35% reduction)
    #   calculator.apply_movement_cooldown(10) # => 6.5 seconds
    #
    class PassiveSkillCalculator
      BASE_MOVEMENT_COOLDOWN = 10 # seconds

      def initialize(character)
        @character = character
        @passive_skills = character&.passive_skills || {}
      end

      # Get the level of a specific passive skill
      #
      # @param skill_key [Symbol, String] the skill identifier
      # @return [Integer] skill level (0 if not set)
      def skill_level(skill_key)
        (@passive_skills[skill_key.to_s] || 0).to_i
      end

      # Calculate movement cooldown reduction from Wanderer skill
      #
      # @return [Float] reduction percentage (0.0 to 0.70)
      def movement_cooldown_modifier
        PassiveSkillRegistry.calculate_effect(:wanderer, skill_level(:wanderer))
      end

      # Apply Wanderer skill to base movement cooldown
      #
      # Formula: base_cooldown * (1 - wanderer_reduction)
      # At Wanderer 0:   10 * (1 - 0.00) = 10.0 seconds
      # At Wanderer 50:  10 * (1 - 0.35) = 6.5 seconds
      # At Wanderer 100: 10 * (1 - 0.70) = 3.0 seconds
      #
      # @param base_cooldown [Numeric] base cooldown in seconds (default 10)
      # @return [Float] adjusted cooldown in seconds
      def apply_movement_cooldown(base_cooldown = BASE_MOVEMENT_COOLDOWN)
        reduction = movement_cooldown_modifier
        (base_cooldown * (1.0 - reduction)).round(2)
      end

      # Calculate all active modifiers from passive skills
      #
      # @return [Hash] modifier values keyed by effect type
      def all_modifiers
        {
          movement_cooldown_reduction: movement_cooldown_modifier
          # Future modifiers will be added here:
          # hp_bonus: hp_bonus_modifier,
          # discovery_bonus: discovery_bonus_modifier,
        }
      end

      # Get a summary of all passive skills with their levels and effects
      #
      # @return [Array<Hash>] skill info with level and calculated effect
      def skill_summary
        PassiveSkillRegistry.all_keys.map do |key|
          definition = PassiveSkillRegistry.find(key)
          level = skill_level(key)
          effect = PassiveSkillRegistry.calculate_effect(key, level)

          {
            key: key,
            name: definition[:name],
            level: level,
            max_level: definition[:max_level],
            effect_value: effect,
            effect_type: definition[:effect_type],
            description: definition[:description]
          }
        end
      end
    end
  end
end
