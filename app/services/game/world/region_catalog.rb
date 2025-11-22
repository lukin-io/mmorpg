# frozen_string_literal: true

require "yaml"
require "singleton"

module Game
  module World
    # RegionCatalog loads world/region descriptors and exposes lookup helpers.
    #
    # Usage:
    #   Game::World::RegionCatalog.instance.region_for_zone(zone)
    #
    # Returns:
    #   Singleton responsible for transforming YAML into Region objects.
    class RegionCatalog
      include Singleton

      REGION_PATH = Rails.root.join("config/gameplay/world/regions.yml")
      RESOURCE_PATH = Rails.root.join("config/gameplay/world/resource_nodes.yml")

      def initialize
        reload!
      end

      def reload!
        @regions = load_regions
        @resource_nodes = load_resource_nodes
      end

      def all
        regions.values
      end

      def find(key)
        regions[key.to_s]
      end

      def region_for_territory(territory_key)
        return unless territory_key

        regions.values.find { |region| region.territory?(territory_key) }
      end

      def region_for_zone(zone)
        return unless zone

        regions.values.find { |region| region.zone?(zone.name) }
      end

      def region_for_coordinate(x:, y:)
        regions.values.find { |region| region.includes_coordinate?(x:, y:) }
      end

      def resource_nodes_for(region_key)
        resource_nodes[region_key.to_s] || []
      end

      private

      attr_reader :regions, :resource_nodes

      def load_regions
        data = safe_load(REGION_PATH)
        data.fetch("regions", {}).each_with_object({}) do |(key, attrs), memo|
          memo[key.to_s] = Game::World::Region.new(key, attrs)
        end
      end

      def load_resource_nodes
        data = safe_load(RESOURCE_PATH)
        data.fetch("resource_nodes", {})
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
