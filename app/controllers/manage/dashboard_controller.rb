# frozen_string_literal: true

module Manage
  class DashboardController < ApplicationController
    def index
      @resource_counts = {
        world_cells: MapTileTemplate.count,
        world_atlas: MapTileTemplate.count,
        tile_buildings: TileBuilding.count,
        npc_templates: NpcTemplate.count,
        tile_npcs: TileNpc.count,
        cities: Zone.where(location_type: "city").count,
        city_hotspots: CityHotspot.count,
        idle_ticks: IdleTickControl.count,
        characters: Character.count,
        unique_items: (defined?(CustomItemTemplate) ? CustomItemTemplate.count : 0),
        world_fortresses: WorldFortress.count,
        audit_events: ManagementAuditEvent.count
      }
      @playable_region_status = Game::World::PlayableRegionStatus.read
      bounds = Game::World::PlayableRegionBuilder.bounds
      @playable_region_live = {
        landmark_cells: MapTileTemplate.where(zone: bounds[:zone]).count,
        fortresses: WorldFortress.count
      }
    end
  end
end
