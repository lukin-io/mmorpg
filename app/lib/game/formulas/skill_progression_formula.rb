# frozen_string_literal: true

module Game
  module Formulas
    # SkillProgressionFormula calculates skill level gains based on a
    # tiered progression system.
    #
    # Purpose:
    #   Determines how many skill points are gained when a player invests one "skill spend"
    #   into a skill. Higher level skills gain fewer points per spend (diminishing returns).
    #
    # Inputs:
    #   - current_level: Integer 0-99, current skill level
    #   - progression_rate: String like "10:8:6:4" or Array like [10, 8, 6, 4]
    #
    # Returns:
    #   Integer - points gained for this spend
    #
    # Usage:
    #   formula = Game::Formulas::SkillProgressionFormula.new
    #   formula.points_per_spend(current_level: 0, progression_rate: "10:8:6:4")
    #   # => 10 (at tier 0: levels 0-24)
    #
    #   formula.points_per_spend(current_level: 50, progression_rate: "10:8:6:4")
    #   # => 6 (at tier 2: levels 50-74)
    #
    # Tier System:
    #   Tier 0: levels  0-24 → use first rate
    #   Tier 1: levels 25-49 → use second rate
    #   Tier 2: levels 50-74 → use third rate
    #   Tier 3: levels 75-99 → use fourth rate
    #
    class SkillProgressionFormula
      MAX_LEVEL = 100
      TIER_SIZE = 25

      # Predefined progression rates for different skill types
      # Higher tiers yield fewer points per spend
      PROGRESSION_RATES = {
        fast: "10:8:6:4",      # Combat skills - quick leveling
        medium: "8:6:4:2",     # Magic skills - balanced
        balanced: "6:4:4:2",   # Resistance skills
        slow: "4:4:2:2",       # Specialized skills
        very_slow: "2:2:2:2"   # Peace skills - slowest
      }.freeze

      # Calculate points gained for a single skill spend
      #
      # @param current_level [Integer] current skill level (0-99)
      # @param progression_rate [String, Array, Symbol] rate definition
      # @return [Integer] points gained
      def points_per_spend(current_level:, progression_rate:)
        rates = parse_rates(progression_rate)
        tier = calculate_tier(current_level)
        points = rates[tier] || rates.last || 2

        # Ensure we don't exceed max level
        remaining = MAX_LEVEL - current_level
        [points, remaining].min
      end

      # Calculate how many spends are needed to reach a target level
      #
      # @param from_level [Integer] starting level
      # @param to_level [Integer] target level
      # @param progression_rate [String, Array, Symbol] rate definition
      # @return [Integer] number of spends required
      def spends_to_reach(from_level:, to_level:, progression_rate:)
        return 0 if from_level >= to_level

        current = from_level
        spends = 0

        while current < to_level && current < MAX_LEVEL
          points = points_per_spend(current_level: current, progression_rate: progression_rate)
          current += points
          spends += 1
        end

        spends
      end

      # Calculate the new level after applying a spend
      #
      # @param current_level [Integer] current skill level (0-99)
      # @param progression_rate [String, Array, Symbol] rate definition
      # @return [Integer] new level after spend
      def apply_spend(current_level:, progression_rate:)
        points = points_per_spend(current_level: current_level, progression_rate: progression_rate)
        [current_level + points, MAX_LEVEL].min
      end

      # Calculate the level after removing a spend (undo)
      # Uses the rate of the tier the level would fall into after removal
      #
      # @param current_level [Integer] current skill level
      # @param base_level [Integer] original level before any spends this session
      # @param progression_rate [String, Array, Symbol] rate definition
      # @return [Integer] new level after removing spend, or current if cannot remove
      def remove_spend(current_level:, base_level:, progression_rate:)
        return current_level if current_level <= base_level

        rates = parse_rates(progression_rate)

        # Try to find the previous level by testing what spend would have gotten us here
        # This handles tier boundaries correctly
        test_level = current_level
        (0..3).reverse_each do |tier|
          tier_start = tier * TIER_SIZE
          rate = rates[tier] || rates.last || 2

          # Check if subtracting this rate would land us in a valid position
          potential_previous = test_level - rate
          if potential_previous >= base_level && potential_previous >= tier_start
            return potential_previous
          end

          # Try the rate from the previous tier if we're at a boundary
          if tier > 0
            prev_rate = rates[tier - 1] || rate
            potential_previous = test_level - prev_rate
            prev_tier_start = (tier - 1) * TIER_SIZE
            if potential_previous >= base_level && potential_previous >= prev_tier_start
              return potential_previous
            end
          end
        end

        # Fallback: subtract current tier rate
        tier = calculate_tier(current_level)
        rate = rates[tier] || rates.last || 2
        [current_level - rate, base_level].max
      end

      # Get progression preview showing points at each tier
      #
      # @param progression_rate [String, Array, Symbol] rate definition
      # @return [Hash] tier => points mapping
      def progression_preview(progression_rate:)
        rates = parse_rates(progression_rate)
        {
          "0-24" => rates[0],
          "25-49" => rates[1],
          "50-74" => rates[2],
          "75-99" => rates[3]
        }
      end

      private

      # Calculate the tier (0-3) based on current level
      #
      # @param level [Integer] skill level 0-99
      # @return [Integer] tier 0-3
      def calculate_tier(level)
        return 3 if level >= 75
        return 2 if level >= 50
        return 1 if level >= 25

        0
      end

      # Parse progression rate into array of integers
      #
      # @param rate [String, Array, Symbol] rate definition
      # @return [Array<Integer>] array of 4 rates
      def parse_rates(rate)
        case rate
        when Array
          rate.map(&:to_i)
        when Symbol
          parse_rates(PROGRESSION_RATES[rate] || PROGRESSION_RATES[:medium])
        when String
          rate.split(":").map(&:to_i)
        else
          [8, 6, 4, 2] # Default to medium
        end
      end
    end
  end
end
