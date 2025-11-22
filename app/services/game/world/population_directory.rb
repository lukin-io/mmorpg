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

      def report_intake_npcs
        npcs.values.select(&:offers_reports?)
      end

      def announcer_for_event(event_key)
        npcs.values.find do |npc|
          npc.event_hooks.fetch("seasonal_keys", []).include?(event_key)
        end
      end

      def spawn_entries_for(region_key)
        overrides = SpawnSchedule.active.where(region_key: region_key.to_s).index_by(&:monster_key)

        monster_tables.fetch(region_key.to_s, []).map do |profile|
          schedule = overrides[profile.key]
          {
            "monster_key" => profile.key,
            "name" => profile.name,
            "kind" => "monster",
            "rarity" => schedule&.rarity_override || profile.rarity,
            "loot_table" => profile.loot_table,
            "difficulty" => profile.rarity,
            "weight" => profile.weight,
            "respawn_seconds" => schedule&.respawn_seconds || profile.respawn_seconds
          }
        end
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
