# frozen_string_literal: true

module Players
  module Progression
    # Distributes available stat points across primary attributes with validation.
    #
    # Usage:
    #   Players::Progression::StatAllocationService.new(character:).allocate!(strength: 2)
    #
    # Returns:
    #   Character after allocation.
    class StatAllocationService
      PERMITTED_STATS = %w[strength agility intellect stamina spirit].freeze

      def initialize(character:)
        @character = character
      end

      def allocate!(allocations)
        allocations.symbolize_keys!
        total_requested = allocations.values.sum
        raise ArgumentError, "Not enough stat points" if total_requested > character.stat_points_available

        allocations.each_key do |stat|
          raise ArgumentError, "Unknown stat #{stat}" unless PERMITTED_STATS.include?(stat.to_s)
        end

        character.stat_points_available -= total_requested
        allocations.each do |stat, value|
          next if value.zero?

          character.allocated_stats_will_change!
          current = character.allocated_stats.fetch(stat.to_s, 0)
          character.allocated_stats[stat.to_s] = current + value
        end

        character.save!
        character
      end

      private

      attr_reader :character
    end
  end
end

