# frozen_string_literal: true

module Game
  module Movement
    # Calculates wilderness travel duration from a server-resolved effective
    # Wanderer level, authored cell metadata, and validated rule parameters.
    # This numeric boundary performs no character/equipment or database reads.
    class TravelTime
      # Neverlands exposes the already-calculated duration to the browser and
      # can vary it per destination terrain. Authored cells therefore own an
      # exact `travel_seconds` override; the isolated Wanderer relation remains
      # the fallback where the complete source formula has not been captured.
      def self.seconds(wanderer_level: 0, metadata: nil, tile_metadata: nil, rules: Game::World::Rules.default, **)
        authored_metadata = metadata || tile_metadata || {}
        authored_seconds = Integer(authored_metadata.to_h["travel_seconds"], exception: false)
        return authored_seconds if authored_seconds&.positive?

        parameters = rules.movement
        maximum_level = parameters.fetch("wanderer_max_level")
        base_seconds = parameters.fetch("base_seconds")
        wanderer_level = wanderer_level.to_i.clamp(0, maximum_level)
        reduction = (wanderer_level * parameters.fetch("wanderer_max_reduction_seconds")) / maximum_level

        (base_seconds - reduction).clamp(parameters.fetch("minimum_seconds"), base_seconds)
      end
    end
  end
end
