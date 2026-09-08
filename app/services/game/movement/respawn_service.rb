# frozen_string_literal: true

module Game
  module Movement
    # RespawnService creates only a missing character position from the supplied
    # spawn scope. The character lock protects retry-safe first position and
    # local-chat entry-context persistence in the same transaction.
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
        character.with_lock do
          position = character.position
          next position if position

          create_fresh_position!
        end
      end

      private

      attr_reader :character, :spawn_scope

      def create_fresh_position!
        spawn = resolve_spawn_point!
        position = CharacterPosition.create!(
          character:,
          zone: spawn.zone,
          x: spawn.x,
          y: spawn.y,
          state: :active,
          last_action_at: nil
        )
        Chat::LocalContext.new(character:).synchronize!
        position
      end

      def resolve_spawn_point!(zone: nil)
        scope = spawn_scope
        scope = scope.where(zone:) if zone
        scope.default_entries.first || raise(ActiveRecord::RecordNotFound, "Default spawn point is not configured")
      end
    end
  end
end
