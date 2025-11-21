# frozen_string_literal: true

module Game
  module Economy
    class LootGenerator
      def initialize(loot_table, rng: Random.new(1))
        @loot_table = loot_table
        @rng = rng
      end

      def call
        roll = rng.rand(100)
        cumulative = 0

        loot_table.each do |item, chance|
          cumulative += chance
          return item if roll < cumulative
        end

        nil
      end

      private

      attr_reader :loot_table, :rng
    end
  end
end
