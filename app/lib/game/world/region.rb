# frozen_string_literal: true

module Game
  module World
    # Region encapsulates deterministic metadata for a Elselands world slice.
    #
    # Usage:
    #   region = Game::World::Region.new("ashen_forest", config_hash)
    #   region.territory?("ashen_forest") # => true
    #
    # Returns:
    #   Plain Ruby object exposing helper methods for region-specific lookups.
    class Region
      attr_reader :key, :name, :biome, :territory_key, :landmarks, :hidden_areas,
        :zones, :metadata

      def initialize(key, attributes)
        @key = key.to_s
        @name = attributes.fetch("name")
        @biome = attributes.fetch("biome")
        @territory_key = attributes.fetch("territory_key")
        @zones = attributes.fetch("zones", [])
        @landmarks = attributes.fetch("landmarks", [])
        @hidden_areas = attributes.fetch("hidden_areas", [])
        @metadata = attributes.fetch("metadata", {})
        @bounds = attributes.fetch("coordinates", nil)
      end

      def includes_coordinate?(x:, y:)
        return false unless @bounds

        x_range = Range.new(*@bounds.fetch("x"))
        y_range = Range.new(*@bounds.fetch("y"))
        x_range.cover?(x) && y_range.cover?(y)
      end

      def territory?(key)
        territory_key == key.to_s
      end

      def zone?(zone_name)
        zones.include?(zone_name)
      end
    end
  end
end
