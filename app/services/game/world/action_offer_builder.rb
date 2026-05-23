# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Builds persisted action offers for the current authoritative tile state.
    class ActionOfferBuilder
      def initialize(character:, position:, tile_state:)
        @character = character
        @position = position
        @tile_state = tile_state
      end

      def call
        cancel_open_offers!

        offers = []
        offers << npc_offer
        offers << building_offer
        offers.compact
      end

      private

      attr_reader :character, :position, :tile_state

      def cancel_open_offers!
        WorldActionOffer
          .offered
          .where(character:)
          .update_all(
            status: WorldActionOffer.statuses.fetch("cancelled"),
            updated_at: Time.current
          )
      end

      def npc_offer
        npc = tile_state.npc
        return unless npc&.alive?
        return unless npc.hostile?

        create_offer(
          :attack_npc,
          target: npc,
          metadata: {
            npc_template_id: npc.npc_template_id,
            npc_key: npc.npc_key,
            hostile: true
          }
        )
      end

      def building_offer
        building = tile_state.building
        return unless building&.can_enter?(character)

        create_offer(
          :enter_building,
          target: building,
          metadata: {
            building_key: building.building_key,
            building_type: building.building_type,
            destination_zone_id: building.destination_zone_id
          }
        )
      end

      def create_offer(action_type, target:, metadata: {})
        WorldActionOffer.create!(
          character:,
          zone: position.zone,
          x: position.x,
          y: position.y,
          action_type: action_type.to_s,
          target:,
          action_key: SecureRandom.hex(16),
          expires_at: WorldActionOffer::OFFER_TTL.from_now,
          metadata:
        )
      end
    end
  end
end
