# frozen_string_literal: true

module Characters
  # Atomically spends primary-stat points and recalculates the source-backed
  # base HP/MP values without healing the character.
  class StatAllocationService
    class AllocationError < StandardError; end

    Result = Data.define(:allocated, :remaining_points)

    def initialize(character:)
      @character = character
    end

    def call(allocations:)
      normalized = normalize(allocations)
      raise AllocationError, "No stats selected" if normalized.empty?

      character.with_lock do
        character.reload
        total = normalized.values.sum
        raise AllocationError, "Not enough free stat points" if total > character.stat_points_available.to_i

        merged = character.allocated_stats.to_h.deep_dup
        normalized.each do |key, amount|
          merged[key.to_s] = merged.fetch(key.to_s, 0).to_i + amount
        end

        character.allocated_stats = merged
        character.stat_points_available -= total
        character.assign_base_vitals_from_stats
        character.save!

        Result.new(allocated: normalized, remaining_points: character.stat_points_available)
      end
    end

    private

    attr_reader :character

    def normalize(allocations)
      allocations.to_h.each_with_object(Hash.new(0)) do |(key, raw_amount), result|
        stat = Character.normalize_stat_key(key)
        next unless stat

        amount = Integer(raw_amount, exception: false)
        next unless amount&.positive?

        result[stat] += amount
      end.to_h
    end
  end
end
