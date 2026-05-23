# frozen_string_literal: true

module Game
  module Skills
    # PassiveSkillCalculator exposes captured passive skill levels to game systems.
    #
    # Purpose:
    #   Keep a single access point for passive skill levels and captured metadata.
    #   Neverlands skill ids/rates are captured, but runtime effect formulas are
    #   not implementation until they are captured separately.
    #
    # Inputs:
    #   - character: Character model with passive_skills JSONB
    #
    # Returns:
    #   Source-backed skill levels and captured metadata.
    #
    # Usage:
    #   calculator = Game::Skills::PassiveSkillCalculator.new(character)
    #   calculator.skill_level(:wanderer)
    class PassiveSkillCalculator
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
