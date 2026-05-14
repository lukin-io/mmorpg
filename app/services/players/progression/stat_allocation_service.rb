# frozen_string_literal: true

module Players
  module Progression
    # Distributes available stat points across Neverlands-style primary attributes.
    #
    # Usage:
    #   Players::Progression::StatAllocationService.new(character:).allocate!(strength: 2)
    #
    # Returns:
    #   Character after allocation.
    class StatAllocationService
      def initialize(character:)
        @character = character
      end

      def allocate!(allocations)
        normalized_allocations = normalize_allocations(allocations)
        total_requested = normalized_allocations.values.sum
        raise ArgumentError, "Not enough stat points" if total_requested > character.stat_points_available

        character.stat_points_available -= total_requested
        normalized_allocations.each do |stat, value|
          next if value.zero?

          character.allocated_stats_will_change!
          current = character.allocated_stats.fetch(stat, 0)
          character.allocated_stats[stat] = current + value
        end

        character.save!
        character
      end

      private

      attr_reader :character

      def normalize_allocations(allocations)
        allocations.each_with_object(Hash.new(0)) do |(stat, value), result|
          key = Character.normalize_stat_key(stat)
          raise ArgumentError, "Unknown stat #{stat}" unless key

          result[key.to_s] += value.to_i
        end.to_h
      end
    end
  end
end
