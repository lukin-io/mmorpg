# frozen_string_literal: true

module Game
  module Skills
    # PassiveSkillCalculator exposes captured passive skill levels to game systems.
    #
    # Purpose:
    #   Keep a single access point for passive skill levels while formulas remain
    #   source-gated. Neverlands skill ids/rates are captured, but runtime effects
    #   such as Wanderer movement cooldown reduction are not yet captured.
    #
    # Inputs:
    #   - character: Character model with passive_skills JSONB
    #
    # Returns:
    #   Source-backed skill levels and zeroed modifiers for uncaptured formulas.
    #
    # Usage:
    #   calculator = Game::Skills::PassiveSkillCalculator.new(character)
    #   calculator.movement_cooldown_modifier  # => 0.0 until formula is captured
    #   calculator.apply_movement_cooldown(10) # => 10.0 seconds
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

      # Movement effects are not source-captured yet.
      #
      # @return [Float] reduction percentage
      def movement_cooldown_modifier
        0.0
      end

      # Return movement cooldown unchanged until a Neverlands formula is captured.
      #
      # @param base_cooldown [Numeric] base cooldown in seconds (default 10)
      # @return [Float] adjusted cooldown in seconds
      def apply_movement_cooldown(base_cooldown = BASE_MOVEMENT_COOLDOWN)
        base_cooldown.to_f.round(2)
      end

      # Calculate all source-backed active modifiers from passive skills.
      #
      # @return [Hash] modifier values keyed by effect type
      def all_modifiers
        {
          movement_cooldown_reduction: movement_cooldown_modifier
        }
      end

      # Get a summary of all passive skills with their captured metadata.
      #
      # @return [Array<Hash>] skill info with level and Neverlands source id
      def skill_summary
        PassiveSkillRegistry.all_keys.map do |key|
          definition = PassiveSkillRegistry.find(key)
          level = skill_level(key)

          {
            key: key,
            source_id: definition[:source_id],
            name: definition[:name],
            level: level,
            max_level: definition[:max_level],
            progression_rate: definition[:progression_rate],
            pool: definition[:pool],
            category: definition[:category],
            description: definition[:description]
          }
        end
      end
    end
  end
end
