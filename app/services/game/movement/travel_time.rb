# frozen_string_literal: true

module Game
  module Movement
    # Calculates source-backed wilderness travel duration.
    class TravelTime
      BASE_TRAVEL_SECONDS = 30

      def self.seconds(**)
        BASE_TRAVEL_SECONDS
      end
    end
  end
end
