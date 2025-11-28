# frozen_string_literal: true

module Game
  module World
    # BiomeNpcConfig loads and provides access to biome-specific NPC spawns.
    # Configuration is loaded from config/gameplay/biome_npcs.yml
    #
    # Usage:
    #   BiomeNpcConfig.for_biome("forest")
    #   # => [{key: "forest_wolf", role: "hostile", ...}, ...]
    #
    #   BiomeNpcConfig.sample_npc("forest")
    #   # => {key: "giant_spider", role: "hostile", ...}
    #
    #   BiomeNpcConfig.respawn_modifier("mountain")
    #   # => 300 (seconds)
    #
    class BiomeNpcConfig
      CONFIG_PATH = Rails.root.join("config/gameplay/biome_npcs.yml")

      class << self
        def config
          @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
        end

        def reload!
          @config = nil
          config
        end

        # Get all NPCs for a biome
        def for_biome(biome)
          biome_config = config[biome.to_sym] || config[:default]
          biome_config[:npcs] || []
        end

        # Get respawn time modifier for biome (in seconds)
        def respawn_modifier(biome)
          biome_config = config[biome.to_sym] || config[:default]
          biome_config[:respawn_modifier] || 0
        end

        # Sample a random NPC from biome based on spawn_chance weights
        def sample_npc(biome, rng: Random.new)
          npcs = for_biome(biome)
          return nil if npcs.empty?

          # Weighted random selection
          total_weight = npcs.sum { |n| n[:spawn_chance] || 1 }
          roll = rng.rand(total_weight)

          cumulative = 0
          npcs.each do |npc|
            cumulative += npc[:spawn_chance] || 1
            return npc if roll < cumulative
          end

          # Fallback to first NPC
          npcs.first
        end

        # Check if biome has any NPCs
        def has_npcs?(biome)
          for_biome(biome).any?
        end

        # Get all NPC keys for a biome
        def npc_keys(biome)
          for_biome(biome).map { |n| n[:key] }
        end

        # Get NPC by key from any biome
        def find_npc(key)
          config.each_value do |biome_config|
            next unless biome_config[:npcs]

            npc = biome_config[:npcs].find { |n| n[:key] == key.to_sym }
            return npc if npc
          end
          nil
        end

        # Get all hostile NPCs for a biome
        def hostile_npcs(biome)
          for_biome(biome).select { |n| n[:role] == "hostile" }
        end

        # Get all friendly NPCs for a biome
        def friendly_npcs(biome)
          for_biome(biome).reject { |n| n[:role] == "hostile" }
        end

        # Get all unique NPCs across all biomes
        def all_npcs
          config.flat_map { |_, bc| bc[:npcs] || [] }.uniq { |n| n[:key] }
        end
      end
    end
  end
end
