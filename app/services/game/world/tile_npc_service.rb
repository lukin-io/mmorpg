# frozen_string_literal: true

module Game
  module World
    # TileNpcService handles NPC spawning and interaction at map tiles.
    # Spawns random NPCs based on biome when players visit tiles.
    #
    # Usage:
    #   service = Game::World::TileNpcService.new(
    #     character: current_character,
    #     zone: "Starter Plains",
    #     x: 5,
    #     y: 7
    #   )
    #   npc_info = service.npc_info
    #   # => { name: "Wild Boar", role: "hostile", level: 2, ... }
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
        npc = find_or_spawn_npc
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
        npc = TileNpc.at_tile(@zone, @x, @y)
        npc.present? || can_spawn_npc?
      end

      # Check if there's an alive hostile NPC (for combat)
      def hostile_npc_present?
        npc = find_or_spawn_npc
        npc&.alive? && npc.hostile?
      end

      # Get the TileNpc record (for combat initiation)
      def tile_npc
        find_or_spawn_npc
      end

      private

      attr_reader :character, :zone, :x, :y

      def find_or_spawn_npc
        npc = TileNpc.at_tile(@zone, @x, @y)
        return npc if npc

        spawn_new_npc
      end

      def spawn_new_npc
        biome = determine_biome
        return nil unless BiomeNpcConfig.has_npcs?(biome)

        npc_data = BiomeNpcConfig.sample_npc(biome)
        return nil unless npc_data

        # Find or create NPC template
        template = find_or_create_template(npc_data)
        return nil unless template

        level = calculate_spawn_level(npc_data)

        TileNpc.create!(
          zone: @zone,
          x: @x,
          y: @y,
          biome: biome,
          npc_template: template,
          npc_key: npc_data[:key],
          npc_role: npc_data[:role] || "hostile",
          level: level,
          current_hp: template.health,
          max_hp: template.health,
          metadata: npc_data[:metadata] || {}
        )
      rescue ActiveRecord::RecordNotUnique
        # Race condition - another process created the NPC
        TileNpc.at_tile(@zone, @x, @y)
      end

      def can_spawn_npc?
        biome = determine_biome
        BiomeNpcConfig.has_npcs?(biome)
      end

      def determine_biome
        # Try to get biome from MapTileTemplate
        tile = MapTileTemplate.find_by(zone: @zone, x: @x, y: @y)
        return tile.biome if tile&.biome.present?

        # Fall back to zone biome
        zone_record = Zone.find_by(name: @zone)
        zone_record&.biome || "plains"
      end

      def calculate_spawn_level(npc_data)
        base_level = npc_data[:level] || 1
        variance = npc_data[:level_variance] || 2

        (base_level + rand(-variance..variance)).clamp(1, 100)
      end

      def find_or_create_template(npc_data)
        # Try to find existing template
        template = NpcTemplate.find_by(npc_key: npc_data[:key])
        return template if template

        # Create new template
        NpcTemplate.create!(
          npc_key: npc_data[:key],
          name: npc_data[:name],
          role: npc_data[:role] || "hostile",
          level: npc_data[:level] || 1,
          dialogue: npc_data[:dialogue] || "...",
          metadata: {
            biome: determine_biome,
            health: npc_data[:hp] || 100,
            base_damage: npc_data[:damage] || 10,
            xp_reward: npc_data[:xp] || 10,
            loot_table: npc_data[:loot] || [],
            description: npc_data.dig(:metadata, :description)
          }.merge(npc_data[:metadata] || {})
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create NPC template for #{npc_data[:key]}: #{e.message}")
        nil
      end
    end
  end
end
