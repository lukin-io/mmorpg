# frozen_string_literal: true

module Game
  module Movement
    # Calculates Neverlands-style wilderness travel duration.
    class TravelTime
      BASE_TRAVEL_SECONDS = 30
      DIAGONAL_MULTIPLIER = 1.4
      MIN_TRAVEL_SECONDS = 3
      MAX_TRAVEL_SECONDS = 86_400

      DIAGONAL_DIRECTIONS = %i[northeast southeast southwest northwest].freeze

      def self.seconds(...)
        new(...).seconds
      end

      def initialize(character:, zone:, direction:, tile_metadata: {})
        @character = character
        @zone = zone
        @direction = direction.to_sym
        @tile_metadata = tile_metadata || {}
      end

      def seconds
        base_with_skills = character.passive_skill_calculator.apply_movement_cooldown(BASE_TRAVEL_SECONDS)
        terrain_adjusted = Game::Movement::TerrainModifier
          .new(zone:)
          .cooldown_seconds(base_seconds: base_with_skills, tile_metadata:)
        diagonal_adjusted = diagonal? ? (terrain_adjusted * DIAGONAL_MULTIPLIER) : terrain_adjusted

        diagonal_adjusted.ceil.clamp(MIN_TRAVEL_SECONDS, MAX_TRAVEL_SECONDS)
      end

      private

      attr_reader :character, :zone, :direction, :tile_metadata

      def diagonal?
        DIAGONAL_DIRECTIONS.include?(direction)
      end
    end
  end
end
