# frozen_string_literal: true

module Game
  module Movement
    # Calculates source-backed wilderness travel duration.
    class TravelTime
      BASE_TRAVEL_SECONDS = 30
      MIN_TRAVEL_SECONDS = 25
      WANDERER_MAX_LEVEL = 100
      WANDERER_MAX_REDUCTION_SECONDS = BASE_TRAVEL_SECONDS - MIN_TRAVEL_SECONDS

      # Neverlands exposes the already-calculated movement duration to the
      # browser. Its complete terrain, fatigue, effect, and encumbrance formula
      # is still unknown, so the MVP isolates the confirmed Wanderer relation:
      # a clean adjacent step falls from 30 to 25 seconds across levels 0..100.
      def self.seconds(character: nil, **)
        wanderer_level = character&.passive_skill_level(:wanderer).to_i.clamp(0, WANDERER_MAX_LEVEL)
        reduction = (wanderer_level * WANDERER_MAX_REDUCTION_SECONDS) / WANDERER_MAX_LEVEL

        (BASE_TRAVEL_SECONDS - reduction).clamp(MIN_TRAVEL_SECONDS, BASE_TRAVEL_SECONDS)
      end
    end
  end
end
