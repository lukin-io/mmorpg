# frozen_string_literal: true

# TileResourceRespawnJob respawns a depleted tile resource with a new random resource.
# Scheduled automatically when a resource is fully harvested.
#
# Usage:
#   TileResourceRespawnJob.perform_later(tile_resource_id)
#
class TileResourceRespawnJob < ApplicationJob
  queue_as :default

  def perform(tile_resource_id)
    tile_resource = TileResource.find_by(id: tile_resource_id)
    return unless tile_resource
    return if tile_resource.available? # Already respawned

    tile_resource.respawn!
    Rails.logger.info("[TileResourceRespawn] Respawned #{tile_resource.resource_key} at #{tile_resource.zone} (#{tile_resource.x}, #{tile_resource.y})")
  rescue => e
    Rails.logger.error("[TileResourceRespawn] Failed to respawn resource #{tile_resource_id}: #{e.message}")
    raise # Re-raise to trigger retry
  end
end
