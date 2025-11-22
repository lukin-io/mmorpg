# frozen_string_literal: true

module Game
  module Exploration
    # EncounterResolver picks deterministic encounters based on biome + tile metadata.
    #
    # Usage:
    #   Game::Exploration::EncounterResolver.new.resolve(zone:, biome:, tile_metadata:, rng: Random.new(1))
    #
    # Returns:
    #   Hash describing the encounter or nil when no encounter triggers.
    class EncounterResolver
      def resolve(zone:, biome:, tile_metadata:, rng: Random.new(1))
        entries = zone.encounter_table[biome] || biome_table[biome] || []
        entries += Array.wrap(tile_metadata["encounters"]) if tile_metadata["encounters"]
        return unless entries.present?

        selected = weighted_sample(entries, rng)
        return unless selected

        {
          name: selected["name"],
          kind: selected["kind"] || "ambient",
          loot_table: selected["loot_table"],
          difficulty: selected["difficulty"] || zone.metadata.fetch("difficulty", "standard")
        }
      end

      private

      def biome_table
        @biome_table ||= YAML.safe_load(
          Rails.root.join("config/gameplay/biomes.yml").read
        )
      end

      def weighted_sample(entries, rng)
        total = entries.sum { |entry| entry["weight"] || 1 }
        return entries.sample if total <= 0

        roll = rng.rand(total)
        cumulative = 0

        entries.each do |entry|
          cumulative += entry["weight"] || 1
          return entry if roll < cumulative
        end

        nil
      end
    end
  end
end
