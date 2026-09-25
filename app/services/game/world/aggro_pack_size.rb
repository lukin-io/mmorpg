# frozen_string_literal: true

module Game
  module World
    # Level-based aggro pack size for personal wilderness instances.
    #
    # Bands (inclusive):
    # - levels 1–5  → 1..3
    # - levels 6–10 → 3..5
    # - then +2 min/max every five levels, capped for combat UI/server load.
    class AggroPackSize
      MAX_PACK = TileNpc::MAX_ENCOUNTER_SIZE

      def initialize(level:, rng: Random.new)
        @level = level.to_i
        @rng = rng
      end

      def call
        range = self.class.range_for(level)
        rng.rand(range)
      end

      def self.range_for(level)
        l = level.to_i.clamp(1, 200)
        band = ((l - 1) / 5).clamp(0, 8)
        minimum = (1 + (band * 2)).clamp(1, MAX_PACK)
        maximum = (3 + (band * 2)).clamp(minimum, MAX_PACK)
        minimum..maximum
      end

      private

      attr_reader :level, :rng
    end
  end
end
