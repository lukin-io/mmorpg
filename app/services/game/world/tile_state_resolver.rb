# frozen_string_literal: true

module Game
  module World
    # Materializes and returns DB-backed state for the character's current tile.
    class TileStateResolver
      Result = Struct.new(:resource, :resource_info, :npc, :npc_info, :building, :building_info, keyword_init: true)

      def initialize(character:, position:)
        @character = character
        @position = position
      end

      def call
        Result.new(
          resource: resource,
          resource_info: resource_info,
          npc: npc,
          npc_info: npc_info,
          building: building,
          building_info: building_info
        )
      end

      private

      attr_reader :character, :position

      def resource_service
        @resource_service ||= Game::World::TileGatheringService.new(
          character:,
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
      end

      def npc_service
        @npc_service ||= Game::World::TileNpcService.new(
          character:,
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
      end

      def building_service
        @building_service ||= Game::World::TileBuildingService.new(
          character:,
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
      end

      def resource
        @resource ||= resource_service.tile_resource
      end

      def resource_info
        @resource_info ||= resource_service.resource_info
      end

      def npc
        @npc ||= npc_service.tile_npc
      end

      def npc_info
        @npc_info ||= npc_service.npc_info
      end

      def building
        @building ||= TileBuilding.active.at_tile(position.zone.name, position.x, position.y)
      end

      def building_info
        @building_info ||= building_service.building_info
      end
    end
  end
end
