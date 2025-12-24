# frozen_string_literal: true

module Game
  module World
    # TileGatheringService handles resource gathering from map tiles.
    # Creates or finds tile resources, handles harvesting, and adds items to inventory.
    #
    # Usage:
    #   service = Game::World::TileGatheringService.new(
    #     character: current_character,
    #     zone: "Starter Plains",
    #     x: 5,
    #     y: 7
    #   )
    #   result = service.gather!
    #   # => { success: true, item_name: "Iron Ore", quantity: 1, message: "..." }
    #
    class TileGatheringService
      Result = Struct.new(:success, :item_name, :quantity, :message, :respawn_in, keyword_init: true)

      def initialize(character:, zone:, x:, y:)
        @character = character
        @zone = zone.is_a?(Zone) ? zone.name : zone
        @x = x.to_i
        @y = y.to_i
      end

      def gather!
        tile_resource = find_or_spawn_resource

        unless tile_resource
          return Result.new(
            success: false,
            message: "No resources available at this location."
          )
        end

        unless tile_resource.available?
          return Result.new(
            success: false,
            message: "This resource is depleted.",
            respawn_in: tile_resource.time_until_respawn
          )
        end

        # Harvest the resource
        harvested_qty = tile_resource.harvest!(character)

        if harvested_qty.zero?
          return Result.new(
            success: false,
            message: "Failed to gather resource."
          )
        end

        # Add to inventory
        add_result = add_to_inventory(tile_resource, harvested_qty)

        unless add_result[:success]
          # Rollback harvest if inventory failed
          tile_resource.update!(
            quantity: tile_resource.quantity + harvested_qty,
            respawns_at: nil,
            last_harvested_at: tile_resource.last_harvested_at
          )
          return Result.new(
            success: false,
            message: add_result[:message]
          )
        end

        Result.new(
          success: true,
          item_name: tile_resource.display_name,
          quantity: harvested_qty,
          message: "Gathered #{harvested_qty}x #{tile_resource.display_name}!",
          respawn_in: tile_resource.depleted? ? tile_resource.time_until_respawn : nil
        )
      end

      # Check if there's a gatherable resource at this tile
      def resource_available?
        resource = TileResource.at_tile(@zone, @x, @y)
        resource&.available? || can_spawn_resource?
      end

      # Get info about resource at tile (for display)
      def resource_info
        resource = TileResource.at_tile(@zone, @x, @y)

        if resource
          {
            name: resource.display_name,
            type: resource.resource_type,
            available: resource.available?,
            respawn_in: resource.time_until_respawn
          }
        elsif can_spawn_resource?
          {
            name: "Unknown Resource",
            type: "unknown",
            available: true,
            respawn_in: 0
          }
        end
      end

      private

      attr_reader :character, :zone, :x, :y

      def find_or_spawn_resource
        resource = TileResource.at_tile(@zone, @x, @y)
        return resource if resource

        spawn_new_resource
      end

      def spawn_new_resource
        biome = determine_biome
        return nil unless BiomeResourceConfig.has_resources?(biome)

        resource_data = BiomeResourceConfig.sample_resource(biome)
        return nil unless resource_data

        TileResource.create!(
          zone: @zone,
          x: @x,
          y: @y,
          biome: biome,
          resource_key: resource_data[:key],
          resource_type: resource_data[:type],
          quantity: resource_data[:quantity] || 1,
          base_quantity: resource_data[:quantity] || 1,
          metadata: resource_data[:metadata] || {}
        )
      rescue ActiveRecord::RecordNotUnique
        # Race condition - another process created the resource
        TileResource.at_tile(@zone, @x, @y)
      end

      def can_spawn_resource?
        biome = determine_biome
        BiomeResourceConfig.has_resources?(biome)
      end

      def determine_biome
        # Try to get biome from MapTileTemplate
        tile = MapTileTemplate.find_by(zone: @zone, x: @x, y: @y)
        return tile.biome if tile&.biome.present?

        # Fall back to zone biome
        zone_record = Zone.find_by(name: @zone)
        zone_record&.biome || "plains"
      end

      def add_to_inventory(tile_resource, quantity)
        inventory = character.inventory
        return {success: false, message: "No inventory found."} unless inventory

        # Find or create item template for this resource
        item_template = find_or_create_item_template(tile_resource)
        return {success: false, message: "Unknown item type."} unless item_template

        begin
          manager = Game::Inventory::Manager.new(inventory: inventory)
          manager.add_item!(item_template: item_template, quantity: quantity)
          {success: true}
        rescue Game::Inventory::Manager::CapacityExceededError => e
          {success: false, message: "Inventory full: #{e.message}"}
        end
      end

      def find_or_create_item_template(tile_resource)
        # First try to find by key
        template = ItemTemplate.find_by(key: tile_resource.resource_key)
        return template if template

        # Try by name
        template = ItemTemplate.find_by(name: tile_resource.display_name)
        return template if template

        # Create a new item template for this resource
        ItemTemplate.create!(
          key: tile_resource.resource_key,
          name: tile_resource.display_name,
          item_type: "material",
          slot: "none",
          rarity: tile_resource.metadata&.dig("rarity") || "common",
          weight: resource_weight(tile_resource.resource_type),
          stack_limit: 99,
          stat_modifiers: {}
        )
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create item template for #{tile_resource.resource_key}: #{e.message}")
        nil
      end

      def resource_weight(resource_type)
        case resource_type
        when "ore" then 3
        when "wood" then 2
        when "herb" then 1
        when "fish" then 2
        when "crystal", "gem" then 1
        else 1
        end
      end
    end
  end
end
