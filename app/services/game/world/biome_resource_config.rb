# frozen_string_literal: true

module Game
  module World
    # BiomeResourceConfig loads and provides access to biome-specific resource spawns.
    # Configuration is loaded from config/gameplay/biome_resources.yml
    #
    # Usage:
    #   BiomeResourceConfig.for_biome("forest")
    #   # => [{key: "oak_wood", type: "wood", name: "Oak Wood", ...}, ...]
    #
    #   BiomeResourceConfig.sample_resource("forest")
    #   # => {key: "moonleaf_herb", type: "herb", ...}
    #
    #   BiomeResourceConfig.respawn_modifier("mountain")
    #   # => 600 (seconds)
    #
    class BiomeResourceConfig
      CONFIG_PATH = Rails.root.join("config/gameplay/biome_resources.yml")

      class << self
        def config
          @config ||= YAML.load_file(CONFIG_PATH).deep_symbolize_keys
        end

        def reload!
          @config = nil
          config
        end

        # Get all resources for a biome
        def for_biome(biome)
          biome_config = config[biome.to_sym] || config[:default]
          biome_config[:resources] || []
        end

        # Get respawn time modifier for biome (in seconds)
        def respawn_modifier(biome)
          biome_config = config[biome.to_sym] || config[:default]
          biome_config[:respawn_modifier] || 0
        end

        # Sample a random resource from biome based on spawn_chance weights
        def sample_resource(biome, rng: Random.new)
          resources = for_biome(biome)
          return nil if resources.empty?

          # Weighted random selection
          total_weight = resources.sum { |r| r[:spawn_chance] || 1 }
          roll = rng.rand(total_weight)

          cumulative = 0
          resources.each do |resource|
            cumulative += resource[:spawn_chance] || 1
            return resource if roll < cumulative
          end

          # Fallback to first resource
          resources.first
        end

        # Check if biome has any resources
        def has_resources?(biome)
          for_biome(biome).any?
        end

        # Get all resource keys for a biome
        def resource_keys(biome)
          for_biome(biome).map { |r| r[:key] }
        end

        # Get resource by key from any biome
        def find_resource(key)
          config.each_value do |biome_config|
            next unless biome_config[:resources]

            resource = biome_config[:resources].find { |r| r[:key] == key.to_sym }
            return resource if resource
          end
          nil
        end

        # Get all unique resource types across all biomes
        def all_resource_types
          config.flat_map { |_, bc| bc[:resources]&.map { |r| r[:type] } || [] }.uniq
        end

        # Get all unique resources across all biomes
        def all_resources
          config.flat_map { |_, bc| bc[:resources] || [] }.uniq { |r| r[:key] }
        end
      end
    end
  end
end

# Alias for easier access
BiomeResourceConfig = Game::World::BiomeResourceConfig
