# frozen_string_literal: true

require "securerandom"

module Game
  module World
    # Returns live offers for the current tile or linked-location surface.
    # Serialized reads reuse exact unchanged actions without extending expiry;
    # changed/unavailable actions are replaced or cancelled. Supplied tile state
    # selects targets only: their current persisted rules are rechecked under
    # the character lock, and a stale-position read cannot cancel newer offers.
    class ActionOfferBuilder
      def initialize(character:, position:, tile_state:, context: :tile)
        @character = character
        @position = position
        @requested_coordinates = [position.zone_id, position.x, position.y]
        @tile_state = tile_state
        @context = context.to_sym
      end

      def call
        character.with_lock do
          @position = character.position&.reload
          next [] unless position && requested_coordinates == [position.zone_id, position.x, position.y]

          @candidates = WorldActionOffer.live.at_tile(position.zone, position.x, position.y)
            .where(character:).order(:id).to_a
          offers = if context == :location
            location_feature_offers
          else
            [building_offer, *local_action_offers].compact
          end
          cancel_obsolete_offers!(offers)
          offers
        end
      end

      private

      attr_reader :character, :position, :tile_state, :context, :requested_coordinates, :candidates

      def cancel_obsolete_offers!(offers)
        WorldActionOffer
          .offered
          .where(character:)
          .where.not(id: offers.map(&:id))
          .update_all(
            status: WorldActionOffer.statuses.fetch("cancelled"),
            updated_at: Time.current
          )
      end

      def building_offer
        building = current_target(tile_state.building)
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
        tile = current_target(tile_state.respond_to?(:tile) ? tile_state.tile : nil)
        return [] unless tile

        Array(tile.active_local_actions).filter_map do |local_action|
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

      def location_feature_offers
        building = current_target(tile_state.building)
        return [] unless building&.location? && building.can_enter?(character)

        building.location_features.map do |feature|
          create_offer(
            :open_location_feature,
            target: building,
            metadata: {
              building_key: building.building_key,
              hotspot_key: feature.fetch("key"),
              location_action_type: feature.fetch("action_type"),
              feature: feature["feature"]
            }.compact
          )
        end
      end

      def create_offer(action_type, target:, metadata: {})
        metadata = metadata.stringify_keys.merge("target_revision" => target.updated_at.iso8601(6))
        existing = candidates.find do |offer|
          offer.action_type == action_type.to_s && offer.target_type == target.class.base_class.name &&
            offer.target_id == target.id && offer.metadata == metadata
        end
        return existing if existing

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

      def current_target(target)
        return unless target

        target.class.find_by(id: target.id, zone: position.zone.name, x: position.x, y: position.y)
      end

      def fatigue_locked?(action_type)
        return false unless position.zone.outdoor?
        return false unless AcceptAction::FATIGUE_LOCKED_ACTIONS.include?(action_type.to_s)

        Characters::FatigueService.new(character:).outdoor_actions_blocked?
      end
    end
  end
end
