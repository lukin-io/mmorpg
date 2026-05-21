# frozen_string_literal: true

require "yaml"
require "singleton"

module Game
  module World
    # PopulationDirectory loads NPC and monster definitions for gameplay systems.
    #
    # Usage:
    #   Game::World::PopulationDirectory.instance.spawn_entries_for("ashen_forest")
    #
    # Returns:
    #   Singleton surfacing POROs for deterministic encounter+dialogue logic.
    class PopulationDirectory
      include Singleton

      NPC_PATH = Rails.root.join("config/gameplay/world/npcs.yml")
      MONSTER_PATH = Rails.root.join("config/gameplay/world/monsters.yml")

      def initialize
        reload!
      end

      def reload!
        @npcs = load_npcs
        @monster_tables = load_monsters
      end

      def npc(key)
        npcs[key.to_s]
      end

      def npcs_for_region(region_key)
        npcs.values.select { |npc| npc.region == region_key.to_s }
      end

      def spawn_entries_for(region_key)
        profiles = monster_tables.fetch(region_key.to_s, [])
        templates = NpcTemplate.where(npc_key: profiles.map(&:key)).index_by(&:npc_key)

        profiles.map do |profile|
          template = templates[profile.key]
          {
            "monster_key" => profile.key,
            "name" => template&.name || profile.name,
            "kind" => "monster",
            "rarity" => template&.configured_spawn_rarity || profile.rarity,
            "loot_table" => template&.loot_table.presence || profile.loot_table,
            "difficulty" => template&.configured_spawn_rarity || profile.rarity,
            "weight" => template&.configured_spawn_weight || profile.weight,
            "respawn_seconds" => template&.configured_respawn_seconds || profile.respawn_seconds
          }
        end
      end

      def spawn_ephemeral(npc_key:, zone_key:, location:)
        npc = npc(npc_key)
        raise ArgumentError, "Unknown NPC #{npc_key}" unless npc

        {
          npc:,
          zone_key: zone_key.to_s,
          location:
        }
      end

      private

      attr_reader :npcs, :monster_tables

      def load_npcs
        data = safe_load(NPC_PATH)
        data.fetch("npcs", {}).each_with_object({}) do |(key, attrs), memo|
          memo[key.to_s] = Game::World::NpcArchetype.new(key, attrs)
        end
      end

      def load_monsters
        data = safe_load(MONSTER_PATH)
        data.fetch("monsters", {}).each_with_object({}) do |(region_key, attrs), memo|
          entries = attrs.fetch("entries", []).map do |entry|
            Game::World::MonsterProfile.new(entry.fetch("key"), entry)
          end
          memo[region_key.to_s] = entries
        end
      end

      def safe_load(path)
        YAML.safe_load(
          path.read,
          permitted_classes: [Date, Time],
          aliases: true
        ) || {}
      end
    end
  end
end
