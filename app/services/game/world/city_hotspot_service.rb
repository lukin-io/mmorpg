# frozen_string_literal: true

module Game
  module World
    # CityHotspotService handles interactions with city hotspots.
    # Provides hotspot data for display and handles zone transitions.
    #
    # Purpose: Get city hotspots for a zone and handle interactions
    #
    # Inputs:
    #   - character: Character instance
    #   - zone: Zone instance (city zone)
    #
    # Returns:
    #   - hotspots: Array of hotspot info hashes for UI
    #   - interact!: Result struct with navigation info
    #
    # Usage:
    #   service = Game::World::CityHotspotService.new(
    #     character: current_character,
    #     zone: current_zone
    #   )
    #   hotspots = service.hotspots_for_display
    #   result = service.interact!(hotspot_id)
    #
    class CityHotspotService
      Result = Struct.new(:success, :message, :hotspot, :redirect_url, :destination_zone, keyword_init: true)

      attr_reader :character, :zone

      def initialize(character:, zone:)
        @character = character
        @zone = zone
      end

      # Check if the zone has a city view (is a city)
      #
      # @return [Boolean]
      def city_zone?
        zone&.biome == "city"
      end

      # Get all hotspots for display in the city view
      #
      # @return [Array<Hash>] array of hotspot info hashes
      def hotspots_for_display
        return [] unless city_zone?

        CityHotspot.for_zone(zone).map do |hotspot|
          hotspot.to_info_hash.merge(
            can_interact: hotspot.can_interact?(character),
            blocked_reason: hotspot.interaction_blocked_reason(character)
          )
        end
      end

      # Get hotspot records for rendering
      #
      # @return [ActiveRecord::Relation]
      def hotspots
        return CityHotspot.none unless city_zone?

        CityHotspot.for_zone(zone)
      end

      # Interact with a specific hotspot
      #
      # @param hotspot_id [Integer] the hotspot to interact with
      # @return [Result]
      def interact!(hotspot_id)
        hotspot = CityHotspot.find_by(id: hotspot_id, zone: zone)

        unless hotspot
          return Result.new(
            success: false,
            message: "Location not found."
          )
        end

        unless hotspot.can_interact?(character)
          return Result.new(
            success: false,
            message: hotspot.interaction_blocked_reason(character) || "You cannot interact with this location.",
            hotspot: hotspot
          )
        end

        case hotspot.action_type
        when "enter_zone"
          handle_zone_transition(hotspot)
        when "open_feature"
          handle_feature_navigation(hotspot)
        else
          Result.new(
            success: false,
            message: "This location has no interaction.",
            hotspot: hotspot
          )
        end
      end

      private

      def handle_zone_transition(hotspot)
        unless hotspot.destination_zone
          return Result.new(
            success: false,
            message: "This exit leads nowhere.",
            hotspot: hotspot
          )
        end

        # Use explicit destination coordinates from action_params if provided,
        # otherwise fall back to spawn point
        dest_x = hotspot.action_params["destination_x"]
        dest_y = hotspot.action_params["destination_y"]

        unless dest_x && dest_y
          spawn_point = hotspot.destination_zone.spawn_points.find_by(default_entry: true) ||
            hotspot.destination_zone.spawn_points.first
          dest_x ||= spawn_point&.x || (hotspot.destination_zone.width / 2)
          dest_y ||= spawn_point&.y || (hotspot.destination_zone.height / 2)
        end

        spawn_x = dest_x
        spawn_y = dest_y

        # Update character position
        position = character.position
        if position
          position.update!(
            zone: hotspot.destination_zone,
            x: spawn_x,
            y: spawn_y,
            last_action_at: Time.current
          )

          Result.new(
            success: true,
            message: "You exit to #{hotspot.destination_zone.name}.",
            hotspot: hotspot,
            destination_zone: hotspot.destination_zone
          )
        else
          Result.new(
            success: false,
            message: "Unable to move - position not found.",
            hotspot: hotspot
          )
        end
      end

      def handle_feature_navigation(hotspot)
        url = hotspot.navigate_url

        Result.new(
          success: true,
          message: "Entering #{hotspot.name}...",
          hotspot: hotspot,
          redirect_url: url
        )
      end
    end
  end
end
