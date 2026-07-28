# frozen_string_literal: true

module Game
  module Movement
    # Calculates source-backed wilderness travel duration.
    class TravelTime
      BASE_TRAVEL_SECONDS = 30
      MIN_TRAVEL_SECONDS = 24
      WANDERER_MAX_LEVEL = 100
      WANDERER_MAX_REDUCTION_SECONDS = BASE_TRAVEL_SECONDS - MIN_TRAVEL_SECONDS

      # Neverlands exposes the already-calculated duration to the browser and
      # can vary it per destination terrain. Authored cells therefore own an
      # exact `travel_seconds` override; the isolated Wanderer relation remains
      # the fallback where the complete source formula has not been captured.
      def self.seconds(character: nil, metadata: nil, tile_metadata: nil, **)
        authored_metadata = metadata || tile_metadata || {}
        authored_seconds = Integer(authored_metadata.to_h["travel_seconds"], exception: false)
        return authored_seconds if authored_seconds&.positive?

        wanderer_level = character&.passive_skill_level(:wanderer).to_i.clamp(0, WANDERER_MAX_LEVEL)
        reduction = (wanderer_level * WANDERER_MAX_REDUCTION_SECONDS) / WANDERER_MAX_LEVEL

        (BASE_TRAVEL_SECONDS - reduction).clamp(MIN_TRAVEL_SECONDS, BASE_TRAVEL_SECONDS)
      end
    end
  end
end
