# frozen_string_literal: true

module Arena
  # Periodically spawns NPC arena applications in eligible rooms
  # Maintains a pool of available training fights for players
  #
  # Purpose: Ensure arena rooms always have NPC opponents available
  #
  # Inputs:
  #   - room_slug: Optional specific room to spawn in (default: all eligible rooms)
  #
  # Usage:
  #   Arena::NpcSpawnerJob.perform_later
  #   Arena::NpcSpawnerJob.perform_later(room_slug: "training")
  #
  class NpcSpawnerJob < ApplicationJob
    queue_as :default

    # Configuration
    MIN_NPCS_PER_ROOM = 2
    MAX_NPCS_PER_ROOM = 5
    RESPAWN_INTERVAL = 60.seconds # Re-check every minute

    # Rooms that support NPC spawning
    NPC_ENABLED_ROOMS = %w[training trial challenge].freeze

    def perform(room_slug: nil)
      if room_slug
        spawn_for_room(room_slug)
      else
        spawn_for_all_rooms
      end

      # Reschedule self to maintain NPC pool
      self.class.set(wait: RESPAWN_INTERVAL).perform_later unless room_slug
    end

    private

    def spawn_for_all_rooms
      NPC_ENABLED_ROOMS.each do |slug|
        spawn_for_room(slug)
      end
    end

    def spawn_for_room(room_slug)
      room = ArenaRoom.find_by(slug: room_slug)
      return unless room&.active?

      # Check if room has NPC config
      return unless Game::World::ArenaNpcConfig.has_npcs?(room_slug)

      current_npc_count = ArenaApplication.open.from_npcs.where(arena_room: room).count

      # Spawn more NPCs if below minimum
      if current_npc_count < MIN_NPCS_PER_ROOM
        npcs_to_spawn = MIN_NPCS_PER_ROOM - current_npc_count
        spawn_npcs(room, npcs_to_spawn)
      end
    end

    def spawn_npcs(room, count)
      service = Arena::NpcApplicationService.new
      rng = Random.new(Time.current.to_i)

      count.times do |i|
        # Alternate difficulties for variety
        difficulty = case i % 3
        when 0 then :easy
        when 1 then :medium
        else :hard
        end

        result = service.create_for_room(
          room: room,
          difficulty: difficulty,
          rng: rng
        )

        if result.success?
          Rails.logger.info("[ArenaNpcSpawner] Spawned NPC application in #{room.slug}: #{result.application.applicant_name}")
        else
          Rails.logger.warn("[ArenaNpcSpawner] Failed to spawn NPC in #{room.slug}: #{result.errors.join(", ")}")
        end
      end
    end
  end
end
