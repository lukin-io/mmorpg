# frozen_string_literal: true

module Game
  module Movement
    # Calculates source-backed wilderness travel duration.
    class TravelTime
      BASE_TRAVEL_SECONDS = 30
      MIN_TRAVEL_SECONDS = 3
      MAX_TRAVEL_SECONDS = 86_400

      def self.seconds(...)
        new(...).seconds
      end

      def initialize(character:, **)
        @character = character
      end

      def seconds
        character.passive_skill_calculator
          .apply_movement_cooldown(BASE_TRAVEL_SECONDS)
          .ceil
          .clamp(MIN_TRAVEL_SECONDS, MAX_TRAVEL_SECONDS)
      end

      private

      attr_reader :character
    end
  end
end
