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
    # Returns a city hotspot relation or interaction result.
    #
    # Usage:
    #   service = Game::World::CityHotspotService.new(
    #     character: current_character,
    #     zone: current_zone
    #   )
    #   hotspots = service.hotspots
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
        zone&.city? || false
      end

      # Get hotspot records for rendering
      #
      # @return [ActiveRecord::Relation]
      def hotspots
        return CityHotspot.none unless city_zone?

        CityHotspot.for_zone(zone)
      end

      # Interact with a current-node hotspot under character/target locks.
      # A successful relocation and its chat-entry context commit together.
      #
      # @param hotspot_id [Integer] the hotspot to interact with
      # @return [Result]
      def interact!(hotspot_id)
        return Result.new(success: false, message: I18n.t("game.world.character_unavailable")) unless character

        character.with_lock do
          if character.active_airship_journey
            next Result.new(success: false, message: I18n.t("game.world.disembark_city"))
          end

          unless city_zone? && character.position&.zone_id == zone.id
            next Result.new(success: false, message: I18n.t("game.world.location_position_mismatch"))
          end

          perform_interaction(hotspot_id)
        end
      end

      private

      def perform_interaction(hotspot_id)
        hotspot = CityHotspot.lock.find_by(id: hotspot_id, zone: zone)

        unless hotspot
          return Result.new(
            success: false,
            message: I18n.t("game.flashes.location_not_found")
          )
        end

        unless hotspot.can_interact?(character)
          return Result.new(
            success: false,
            message: hotspot.interaction_blocked_reason(character) || I18n.t("game.world.cannot_go_there"),
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
            message: I18n.t("game.world.area_no_action"),
            hotspot: hotspot
          )
        end
      end

      def handle_zone_transition(hotspot)
        unless hotspot.destination_zone
          return Result.new(
            success: false,
            message: I18n.t("game.world.transition_not_configured"),
            hotspot: hotspot
          )
        end

        destination_x = Integer(hotspot.action_params["destination_x"], exception: false)
        destination_y = Integer(hotspot.action_params["destination_y"], exception: false)
        unless destination_coordinates_valid?(hotspot.destination_zone, destination_x, destination_y)
          return Result.new(
            success: false,
            message: I18n.t("game.world.destination_coords_missing"),
            hotspot: hotspot
          )
        end

        # Update character position
        position = character.position
        if position
          position.update!(
            zone: hotspot.destination_zone,
            x: destination_x,
            y: destination_y,
            last_action_at: Time.current
          )
          ResumeContext.new(character:).remember_world!

          Result.new(
            success: true,
            message: I18n.t("game.world.moved_to", name: hotspot.destination_zone.name),
            hotspot: hotspot,
            destination_zone: hotspot.destination_zone
          )
        else
          Result.new(
            success: false,
            message: I18n.t("game.world.transition_no_position"),
            hotspot: hotspot
          )
        end
      end

      def destination_coordinates_valid?(destination_zone, x, y)
        x&.between?(0, destination_zone.width - 1) &&
          y&.between?(0, destination_zone.height - 1)
      end

      def handle_feature_navigation(hotspot)
        url = hotspot.navigate_url
        unless url
          return Result.new(
            success: false,
            message: I18n.t("game.world.hotspot_unavailable", name: hotspot.name),
            hotspot: hotspot
          )
        end

        ResumeContext.new(character:).remember_arena_entry! if hotspot.action_params["feature"] == "arena"

        Result.new(
          success: true,
          message: I18n.t("game.world.entered", name: hotspot.name),
          hotspot: hotspot,
          redirect_url: url
        )
      end
    end
  end
end
