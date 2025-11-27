# frozen_string_literal: true

module Characters
  # Handles character death consequences
  # Called when HP reaches 0
  #
  # @example Handle death
  #   Characters::DeathHandler.call(character)
  #
  class DeathHandler
    def self.call(character)
      new(character).call
    end

    def initialize(character)
      @character = character
    end

    def call
      # Apply death penalties based on context
      apply_penalties

      # Broadcast death event
      broadcast_death

      # Respawn character
      respawn_character
    end

    private

    attr_reader :character

    def apply_penalties
      # Arena deaths have no penalties
      return if in_arena_match?

      # Apply XP loss (e.g., 5% of current level XP)
      xp_loss = (character.experience * 0.05).to_i
      character.experience = [0, character.experience - xp_loss].max

      # Potentially apply durability loss to equipment
      # (Would be handled by inventory service)

      character.save!
    end

    def broadcast_death
      ActionCable.server.broadcast(
        "character:#{character.id}:vitals",
        {
          type: :death,
          character_id: character.id,
          character_name: character.name,
          message: "#{character.name} has been defeated!"
        }
      )

      # Also broadcast to zone for nearby players
      if character.position
        ActionCable.server.broadcast(
          "zone:#{character.position.zone_id}",
          {
            type: :player_death,
            character_id: character.id,
            character_name: character.name,
            x: character.position.x,
            y: character.position.y
          }
        )
      end
    end

    def respawn_character
      # Restore HP to 25% of max
      character.current_hp = (character.max_hp * 0.25).to_i
      character.current_mp = (character.max_mp * 0.25).to_i
      character.in_combat = false
      character.save!

      # Move to respawn point (city/safe zone)
      move_to_respawn_point

      # Start regeneration
      Characters::RegenTickerJob.perform_later(character.id)
    end

    def move_to_respawn_point
      return unless character.position

      # Find nearest spawn point or default city
      spawn_point = find_respawn_point

      if spawn_point
        character.position.update!(
          zone: spawn_point.zone,
          x: spawn_point.x,
          y: spawn_point.y
        )
      end
    end

    def find_respawn_point
      # First try to find a spawn point in character's current zone
      current_zone = character.position&.zone

      if current_zone
        spawn = SpawnPoint.find_by(zone: current_zone, spawn_type: :player_respawn)
        return spawn if spawn
      end

      # Fall back to default city spawn
      SpawnPoint.find_by(spawn_type: :player_default)
    end

    def in_arena_match?
      ArenaParticipation.joins(:arena_match)
        .where(character: character)
        .where(arena_matches: { status: [:pending, :matching, :live] })
        .exists?
    end
  end
end
