# frozen_string_literal: true

# TileNpcRespawnJob respawns a defeated tile NPC only when the tile has an
# explicit source-backed respawn rule.
# Scheduled automatically when an NPC is defeated.
#
# Usage:
#   TileNpcRespawnJob.perform_later(tile_npc_id)
#
class TileNpcRespawnJob < ApplicationJob
  queue_as :default

  def perform(tile_npc_id)
    tile_npc = TileNpc.find_by(id: tile_npc_id)
    return unless tile_npc
    tile_npc.with_lock do
      return unless tile_npc.defeated? && tile_npc.respawns_at && tile_npc.respawns_at <= Time.current

      # Activation controls encounter availability, not the authoritative
      # respawn clock. A due disabled placement stays disabled after respawn.
      tile_npc.respawn!
      Rails.logger.info("[TileNpcRespawn] Respawned #{tile_npc.npc_key} at #{tile_npc.zone} (#{tile_npc.x}, #{tile_npc.y})")
    end
  rescue => e
    Rails.logger.error("[TileNpcRespawn] Failed to respawn NPC #{tile_npc_id}: #{e.message}")
    raise # Re-raise to trigger retry
  end
end
