# frozen_string_literal: true

module Game
  module World
    # Guard Tower directory: live district route offers from the current city node.
    class GuardTowerRoutes
      Route = Struct.new(:hotspot, :offer, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        position = character.position
        return [] unless position&.zone&.city?

        hotspots = CityHotspot.for_zone(position.zone).select { |h| h.hotspot_type == "district" }
        return [] if hotspots.empty?

        offers = CityActionOfferBuilder.new(
          character:,
          position:,
          hotspots:
        ).call.index_by(&:target_id)

        hotspots.filter_map do |hotspot|
          offer = offers[hotspot.id]
          next unless offer

          Route.new(hotspot:, offer:)
        end
      end

      private

      attr_reader :character
    end
  end
end
