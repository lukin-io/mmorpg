# frozen_string_literal: true

module Game
  module World
    # Materializes and returns DB-backed state for the character's current tile.
    class TileStateResolver
      Result = Struct.new(
        :tile,
        :npc,
        :npc_info,
        :building,
        :building_info,
        :local_actions,
        keyword_init: true
      )

      def initialize(character:, position:)
        @character = character
        @position = position
      end

      def call
        Result.new(
          tile: tile,
          npc: npc,
          npc_info: npc_info,
          building: building,
          building_info: building_info,
          local_actions: local_actions
        )
      end

      private

      attr_reader :character, :position

      def npc_service
        @npc_service ||= Game::World::TileNpcService.new(
          character:,
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
      end

      def tile
        @tile ||= MapTileTemplate.find_by(
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
      end

      def local_actions
        Array(tile&.active_local_actions).select do |action|
          MapTileTemplate.local_action_implemented?(action["type"])
        end
      end

      def building_service
        @building_service ||= Game::World::TileBuildingService.new(
          character:,
          zone: position.zone.name,
          x: position.x,
          y: position.y
        )
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
