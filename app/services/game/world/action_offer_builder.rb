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
        offers << building_offer
        offers.concat(local_action_offers)
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

      def building_offer
        building = tile_state.building
        return unless building&.can_enter?(character)
        return if fatigue_locked?("enter_building")

        create_offer(
          :enter_building,
          target: building,
          metadata: {
            building_key: building.building_key,
            destination_zone_id: building.destination_zone_id
          }
        )
      end

      def local_action_offers
        tile = tile_state.respond_to?(:tile) ? tile_state.tile : nil
        return [] unless tile

        Array(tile_state.local_actions).filter_map do |local_action|
          local_action_type = local_action["type"]
          next unless MapTileTemplate.local_action_implemented?(local_action_type)

          world_action_type = MapTileTemplate.world_action_type_for(local_action_type)
          next unless world_action_type
          next if fatigue_locked?(world_action_type)

          create_offer(
            world_action_type,
            target: tile,
            metadata: {
              local_action_type:,
              source_id: local_action["source_id"],
              label: local_action["label"].presence ||
                MapTileTemplate.default_local_action_label(local_action_type)
            }
          )
        end
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

      def fatigue_locked?(action_type)
        return false unless position.zone.outdoor?
        return false unless AcceptAction::FATIGUE_LOCKED_ACTIONS.include?(action_type.to_s)

        Characters::FatigueService.new(character:).outdoor_actions_blocked?
      end
    end
  end
end
