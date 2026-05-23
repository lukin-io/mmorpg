# frozen_string_literal: true

module Game
  module World
    # TileNpcService materializes source-backed hostile NPCs at captured map tiles.
    #
    # Usage:
    #   service = Game::World::TileNpcService.new(
    #     character: current_character,
    #     zone: "Окрестность Форпоста",
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
        npc_data = OutdoorNpcConfig.source_npc_for_tile(zone, x, y)
        return nil unless npc_data
        return nil unless source_npc_data_complete?(npc_data)

        template = find_or_create_template(npc_data)
        return nil unless template

        TileNpc.create!(
          zone: @zone,
          x: @x,
          y: @y,
          npc_template: template,
          npc_key: npc_data[:key],
          npc_role: npc_data[:role],
          level: npc_data[:level],
          current_hp: template.max_hp,
          max_hp: template.max_hp,
          metadata: npc_data[:metadata] || {}
        )
      rescue ActiveRecord::RecordNotUnique
        # Race condition - another process created the NPC
        TileNpc.at_tile(@zone, @x, @y)
      end

      def can_spawn_npc?
        OutdoorNpcConfig.source_npc_for_tile(zone, x, y).present?
      end

      def find_or_create_template(npc_data)
        # Try to find existing template
        template = NpcTemplate.find_by(npc_key: npc_data[:key])
        if template
          sync_template_spawn_metadata(template, npc_data)
          return template
        end

        # Create new template
        NpcTemplate.create!(
          npc_key: npc_data[:key],
          name: npc_data[:name],
          role: npc_data[:role],
          level: npc_data[:level],
          dialogue: npc_data[:dialogue] || "...",
          metadata: template_spawn_metadata(npc_data)
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create NPC template for #{npc_data[:key]}: #{e.message}")
        nil
      end

      def sync_template_spawn_metadata(template, npc_data)
        additions = template_spawn_metadata(npc_data).compact
        missing = additions.except(*template.metadata.keys)
        return if missing.empty?

        template.update!(metadata: template.metadata.merge(missing))
      end

      def template_spawn_metadata(npc_data)
        {
          "health" => npc_data[:hp],
          "base_damage" => npc_data[:damage],
          "xp_reward" => npc_data[:xp],
          "loot_table" => npc_data[:loot] || [],
          "respawn_seconds" => npc_data[:respawn_seconds],
          "respawn_variance_seconds" => npc_data[:respawn_variance_seconds],
          "description" => npc_data.dig(:metadata, :description),
          "avatar_image" => npc_data.dig(:metadata, :avatar_image)
        }.compact.merge((npc_data[:metadata] || {}).deep_stringify_keys)
      end

      def source_npc_data_complete?(npc_data)
        npc_data.values_at(:key, :name, :role, :level, :hp, :damage).all?(&:present?)
      end
    end
  end
end
