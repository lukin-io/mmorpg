# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Rotates short-lived server offers for the current city node's captured
    # transitions, buildings, and gates.
    class CityActionOfferBuilder
      def initialize(character:, position:, hotspots:)
        @character = character
        @position = position
        @hotspots = hotspots
      end

      def call
        cancel_open_offers!

        hotspots.filter_map do |hotspot|
          next unless hotspot.can_interact?(character)

          WorldActionOffer.create!(
            character:,
            zone: position.zone,
            x: position.x,
            y: position.y,
            action_type: hotspot.world_action_type,
            target: hotspot,
            action_key: SecureRandom.hex(16),
            expires_at: WorldActionOffer::OFFER_TTL.from_now,
            metadata: {
              "city_node_key" => position.zone.metadata["city_node_key"],
              "hotspot_key" => hotspot.key,
              "feature" => hotspot.action_params["feature"]
            }.compact
          )
        end
      end

      private

      attr_reader :character, :position, :hotspots

      def cancel_open_offers!
        WorldActionOffer.offered.where(character:).update_all(
          status: WorldActionOffer.statuses.fetch("cancelled"),
          updated_at: Time.current
        )
      end
    end
  end
end
