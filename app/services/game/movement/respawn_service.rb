# frozen_string_literal: true

module Game
  module Movement
    # RespawnService snaps a character to the correct spawn point when they enter or recover.
    #
    # Usage:
    #   Game::Movement::RespawnService.new(character:).ensure_position!
    #
    # Returns:
    #   CharacterPosition with active state.
    class RespawnService
      def initialize(character:, spawn_scope: SpawnPoint.all)
        @character = character
        @spawn_scope = spawn_scope
      end

      def ensure_position!
        position = character.position
        return position if position&.active?
        return revive(position) if position&.respawn_available_at&.past?

        create_fresh_position!
      end

      private

      attr_reader :character, :spawn_scope

      def create_fresh_position!
        spawn = resolve_spawn_point!
        CharacterPosition.create!(
          character:,
          zone: spawn.zone,
          x: spawn.x,
          y: spawn.y,
          state: :active,
          last_action_at: nil,
          respawn_available_at: nil
        )
      end

      def revive(position)
        spawn = resolve_spawn_point!(zone: position.zone)
        position.update!(
          zone: spawn.zone,
          x: spawn.x,
          y: spawn.y,
          state: :active,
          respawn_available_at: nil
        )
        position
      end

      def resolve_spawn_point!(zone: nil)
        scope = spawn_scope
        scope = scope.where(zone:) if zone
        scope.matching_faction(faction_alignment).first || scope.default_entries.first || scope.first!
      end

      def faction_alignment
        character.faction_alignment.presence || Character::ALIGNMENTS[:neutral]
      end
    end
  end
end

