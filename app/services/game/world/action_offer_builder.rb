# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Builds persisted action offers for the current authoritative tile state.
    class ActionOfferBuilder
      def initialize(character:, position:, tile_state:, gathering_nodes: [])
        @character = character
        @position = position
        @tile_state = tile_state
        @gathering_nodes = gathering_nodes
      end

      def call
        cancel_open_offers!

        offers = []
        offers.concat(gathering_node_offers)
        offers << gather_resource_offer
        offers << npc_offer
        offers << building_offer
        offers.compact
      end

      private

      attr_reader :character, :position, :tile_state, :gathering_nodes

      def cancel_open_offers!
        WorldActionOffer
          .offered
          .where(character:)
          .update_all(
            status: WorldActionOffer.statuses.fetch("cancelled"),
            updated_at: Time.current
          )
      end

      def gathering_node_offers
        gathering_nodes.map do |node|
          create_offer(:gather_node, target: node, metadata: {resource_key: node.resource_key})
        end
      end

      def gather_resource_offer
        resource = tile_state.resource
        return unless resource&.available?

        create_offer(
          :gather_resource,
          target: resource,
          metadata: {
            resource_key: resource.resource_key,
            resource_type: resource.resource_type
          }
        )
      end

      def npc_offer
        npc = tile_state.npc
        return unless npc&.alive?

        action_type = npc.hostile? ? :attack_npc : :talk_npc
        create_offer(
          action_type,
          target: npc,
          metadata: {
            npc_template_id: npc.npc_template_id,
            npc_key: npc.npc_key,
            hostile: npc.hostile?
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
