# frozen_string_literal: true

module Game
  module World
    # TileNpcService reads persisted hostile NPCs at captured map tiles.
    #
    # Usage:
    #   service = Game::World::TileNpcService.new(
    #     character: current_character,
    #     zone: "Outpost Surroundings",
    #     x: 5,
    #     y: 7
    #   )
    #   npc_info = service.npc_info
    #   # => { name: "Plague Rat", role: "hostile", level: 4, ... }
    #
    class TileNpcService
      def initialize(character:, zone:, x:, y:)
        @character = character
        @zone = zone.is_a?(Zone) ? zone.name : zone
        @x = x.to_i
        @y = y.to_i
      end

      # Get info about NPC at tile (for display)
      def npc_info
        npc = find_npc
        return nil unless npc

        {
          id: npc.id,
          name: npc.display_name,
          role: npc.npc_role,
          level: npc.level,
          hp: npc.current_hp,
          max_hp: npc.max_hp,
          hp_percentage: npc.hp_percentage,
          alive: npc.alive?,
          hostile: npc.hostile?,
          respawn_in: npc.time_until_respawn,
          npc_template_id: npc.npc_template_id,
          description: npc.npc_template&.description
        }
      end

      # Check if there's an NPC at this tile
      def npc_present?
        TileNpc.at_tile(@zone, @x, @y).present?
      end

      # Check if there's an alive hostile NPC (for combat)
      def hostile_npc_present?
        npc = find_npc
        npc&.alive? && npc.hostile?
      end

      # Get the TileNpc record (for combat initiation)
      def tile_npc
        find_npc
      end

      private

      attr_reader :character, :zone, :x, :y

      def find_npc
        TileNpc.at_tile(@zone, @x, @y)
      end
    end
  end
end
