# frozen_string_literal: true

module Players
  module Progression
    # LevelUpService awards XP, handles level ups, and grants stat/skill points.
    #
    # Usage:
    #   Players::Progression::LevelUpService.new(character:).apply_experience!(250)
    #
    # Returns:
    #   Character with updated level and point pools.
    class LevelUpService
      STAT_POINTS_PER_LEVEL = 5
      SKILL_POINTS_PER_LEVEL = 1

      def initialize(character:)
        @character = character
      end

      def apply_experience!(amount)
        Character.transaction do
          character.increment!(:experience, amount)
          process_level_ups
        end
        character
      end

      private

      attr_reader :character

      def process_level_ups
        while character.experience >= xp_required_for(character.level + 1)
          character.increment!(:level)
          character.increment!(:stat_points_available, STAT_POINTS_PER_LEVEL)
          character.increment!(:skill_points_available, SKILL_POINTS_PER_LEVEL)
          character.update!(last_level_up_at: Time.current)
        end
      end

      def xp_required_for(level)
        (level**2) * 100
      end
    end
  end
end

