# frozen_string_literal: true

module Manage
  class DashboardController < ApplicationController
    def index
      @resource_counts = {
        world_cells: MapTileTemplate.count,
        tile_buildings: TileBuilding.count,
        npc_templates: NpcTemplate.count,
        tile_npcs: TileNpc.count,
        cities: Zone.where(location_type: "city").count,
        city_hotspots: CityHotspot.count,
        audit_events: ManagementAuditEvent.count
      }
    end
  end
end
