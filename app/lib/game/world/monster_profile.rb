# frozen_string_literal: true

module Game
  module World
    # MonsterProfile holds spawn data, rarity tiers, and loot tables per region.
    #
    # Usage:
    #   profile = Game::World::MonsterProfile.new("forest_wolf", config)
    #   profile.weight # => 50
    #
    # Returns:
    #   Plain Ruby object for deterministic encounter & loot resolution.
    class MonsterProfile
      attr_reader :key, :name, :rarity, :weight, :respawn_seconds,
        :hostility, :loot_table

      def initialize(key, config)
        @key = key.to_s
        @name = config.fetch("name")
        @rarity = config.fetch("rarity")
        @weight = config.fetch("weight", 1)
        @respawn_seconds = config.fetch("respawn_seconds", 60)
        @hostility = config.fetch("hostility", "hostile")
        @loot_table = config.fetch("loot_table", {})
      end

      def hostile?
        hostility == "hostile"
      end
    end
  end
end
