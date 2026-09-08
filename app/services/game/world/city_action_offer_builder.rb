# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Reuses live offers for the current city node's captured actions so another
    # read cannot invalidate visible forms. Under the character lock, replaces
    # expired or changed actions and cancels obsolete offers. Returns the offers
    # to render; acceptance still validates fresh authority and consumes a key.
    class CityActionOfferBuilder
      def initialize(character:, position:, hotspots:)
        @character = character
        @position = position
        @requested_coordinates = [position.zone_id, position.x, position.y]
        @hotspots = hotspots
      end

      def call
        character.with_lock do
          @position = character.position&.reload
          next [] unless position&.zone&.city? && requested_coordinates == [position.zone_id, position.x, position.y]

          available_hotspots = CityHotspot.for_zone(position.zone)
            .where(id: hotspots.map(&:id)).includes(:destination_zone)
            .select { |hotspot| hotspot.can_interact?(character) }
          candidates = WorldActionOffer.live.at_tile(position.zone, position.x, position.y)
            .where(character:, target_type: "CityHotspot", target_id: available_hotspots.map(&:id))
            .order(:id).to_a

          offers = available_hotspots.map do |hotspot|
            metadata = {
              "city_node_key" => position.zone.metadata["city_node_key"],
              "hotspot_key" => hotspot.key,
              "hotspot_revision" => hotspot.updated_at.iso8601(6),
              "feature" => hotspot.action_params["feature"]
            }.compact
            candidates.find { |offer| offer.target_id == hotspot.id && offer.action_type == hotspot.world_action_type && offer.metadata == metadata } ||
              WorldActionOffer.create!(
                character:,
                zone: position.zone,
                x: position.x,
                y: position.y,
                action_type: hotspot.world_action_type,
                target: hotspot,
                action_key: SecureRandom.hex(16),
                expires_at: WorldActionOffer::OFFER_TTL.from_now,
                metadata:
              )
          end
          cancel_obsolete_offers!(offers)
          offers
        end
      end

      private

      attr_reader :character, :position, :hotspots, :requested_coordinates

      def cancel_obsolete_offers!(offers)
        WorldActionOffer.offered.where(character:).where.not(id: offers.map(&:id)).update_all(
          status: WorldActionOffer.statuses.fetch("cancelled"),
          updated_at: Time.current
        )
      end
    end
  end
end
