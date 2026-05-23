# frozen_string_literal: true

module Game
  module Formulas
    # Applies captured Neverlands `addskill_v02.js` tier rates such as "8:6:4:2".
    # No symbolic aliases or default rates are invented for missing data.
    class SkillProgressionFormula
      MAX_LEVEL = 100
      TIER_SIZE = 25
      RATE_PATTERN = /\A\d+:\d+:\d+:\d+\z/

      # Calculate points gained for a single skill spend
      #
      # @param current_level [Integer] current skill level (0-99)
      # @param progression_rate [String] captured rate definition
      # @return [Integer] points gained
      def points_per_spend(current_level:, progression_rate:)
        level = normalize_level(current_level)
        rates = parse_rates(progression_rate)
        points = rates.fetch(calculate_tier(level))

        remaining = MAX_LEVEL - level
        [points, remaining].min
      end

      # Calculate the new level after applying a spend
      #
      # @param current_level [Integer] current skill level (0-99)
      # @param progression_rate [String] captured rate definition
      # @return [Integer] new level after spend
      def apply_spend(current_level:, progression_rate:)
        level = normalize_level(current_level)
        points = points_per_spend(current_level: level, progression_rate: progression_rate)
        [level + points, MAX_LEVEL].min
      end

      # Calculate the level after removing a spend (undo)
      # Uses the rate of the tier the level would fall into after removal
      #
      # @param current_level [Integer] current skill level
      # @param base_level [Integer] original level before any spends this session
      # @param progression_rate [String] captured rate definition
      # @return [Integer] new level after removing spend, or current if cannot remove
      def remove_spend(current_level:, base_level:, progression_rate:)
        level = normalize_level(current_level)
        base = normalize_level(base_level)
        return level if level <= base

        rates = parse_rates(progression_rate)

        (0..3).reverse_each do |tier|
          tier_start = tier * TIER_SIZE
          rate = rates.fetch(tier)

          potential_previous = level - rate
          if potential_previous >= base && potential_previous >= tier_start
            return potential_previous
          end

          if tier > 0
            prev_rate = rates.fetch(tier - 1)
            potential_previous = level - prev_rate
            prev_tier_start = (tier - 1) * TIER_SIZE
            if potential_previous >= base && potential_previous >= prev_tier_start
              return potential_previous
            end
          end
        end

        [level - rates.fetch(calculate_tier(level)), base].max
      end

      private

      def calculate_tier(level)
        return 3 if level >= 75
        return 2 if level >= 50
        return 1 if level >= 25

        0
      end

      def parse_rates(rate)
        unless rate.is_a?(String) && rate.match?(RATE_PATTERN)
          raise ArgumentError, "progression_rate must be a captured Neverlands rate string"
        end

        rate.split(":").map(&:to_i)
      end

      def normalize_level(level)
        level = Integer(level)
        raise ArgumentError, "current level must be between 0 and #{MAX_LEVEL}" unless level.between?(0, MAX_LEVEL)

        level
      end
    end
  end
end
