# frozen_string_literal: true

module Game
  module World
    # TileBuildingService handles building interactions at map tiles.
    # Provides building info for display and handles zone transitions.
    #
    # Purpose: Get building information at a tile and handle entry
    #
    # Inputs:
    #   - character: Character instance
    #   - zone: Zone name (string)
    #   - x: X coordinate
    #   - y: Y coordinate
    #
    # Returns:
    #   - building_info: Hash with building data for UI
    #   - enter!: Result struct with success/failure
    #
    # Usage:
    #   service = Game::World::TileBuildingService.new(
    #     character: current_character,
    #     zone: "Starter Plains",
    #     x: 5,
    #     y: 5
    #   )
    #   info = service.building_info  # => { id: 1, name: "Castle", ... }
    #   result = service.enter!       # => Result(success: true, ...)
    #
    class TileBuildingService
      Result = Struct.new(:success, :message, :building, :destination_zone, keyword_init: true)

      attr_reader :character, :zone, :x, :y

      def initialize(character:, zone:, x:, y:)
        @character = character
        @zone = zone.is_a?(Zone) ? zone.name : zone.to_s
        @x = x.to_i
        @y = y.to_i
      end

      # Get building information at the current tile
      # Returns nil for inactive buildings (they shouldn't show on UI)
      #
      # @return [Hash, nil] building info hash or nil if no active building
      def building_info
        return nil unless active_building

        {
          id: active_building.id,
          name: active_building.display_name,
          building_type: active_building.building_type,
          icon: active_building.display_icon,
          destination: active_building.destination_zone&.name,
          required_level: active_building.required_level,
          faction_key: active_building.faction_key,
          can_enter: active_building.can_enter?(character),
          blocked_reason: active_building.entry_blocked_reason(character),
          description: active_building.metadata&.dig("description"),
          active: active_building.active?
        }
      end

      # Attempt to enter the building
      #
      # @return [Result]
      def enter!
        unless building
          return Result.new(
            success: false,
            message: "No building found at this location."
          )
        end

        unless building.active?
          return Result.new(
            success: false,
            message: "This building is currently inaccessible.",
            building: building
          )
        end

        blocked_reason = building.entry_blocked_reason(character)
        if blocked_reason
          return Result.new(
            success: false,
            message: blocked_reason,
            building: building
          )
        end

        if building.enter!(character)
          Result.new(
            success: true,
            message: "You enter #{building.display_name}.",
            building: building,
            destination_zone: building.destination_zone
          )
        else
          Result.new(
            success: false,
            message: "Failed to enter #{building.display_name}.",
            building: building
          )
        end
      end

      # Check if there's a building at the current tile
      #
      # @return [Boolean]
      # Check if there's a visible (active) building at this tile
      def building_present?
        active_building.present?
      end

      private

      # Find building at tile (without active filter so we can check status)
      def building
        @building ||= TileBuilding.at_tile(zone, x, y)
      end

      # Find only active building at tile (for display purposes)
      def active_building
        @active_building ||= TileBuilding.active.at_tile(zone, x, y)
      end
    end
  end
end
