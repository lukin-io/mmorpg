# frozen_string_literal: true

module Game
  module Movement
    # TurnProcessor enforces server-side, turn-based movement and resolves encounters.
    #
    # Usage:
    #   result = Game::Movement::TurnProcessor.new(character:, direction: :north).call
    #
    # Returns:
    #   Result struct with updated position + optional encounter data.
    class TurnProcessor
      Result = Struct.new(:position, :encounter, keyword_init: true)

      ACTION_COOLDOWN_SECONDS = 3
      OFFSETS = {
        north: [0, -1],
        south: [0, 1],
        east: [1, 0],
        west: [-1, 0],
        northeast: [1, -1],
        southeast: [1, 1],
        southwest: [-1, 1],
        northwest: [-1, -1]
      }.freeze

      def initialize(character:, direction:, rng: Random.new(1), movement_validator: MovementValidator,
        respawn_service: nil, encounter_resolver: Game::Exploration::EncounterResolver.new)
        @character = character
        @direction = direction.to_sym
        @rng = rng
        @movement_validator_class = movement_validator
        @respawn_service = respawn_service || RespawnService.new(character:)
        @encounter_resolver = encounter_resolver
      end

      def call
        position = respawn_service.ensure_position!
        dx, dy = fetch_offset
        target_x = position.x + dx
        target_y = position.y + dy

        provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = movement_validator_class.new(provider)
        raise MovementViolationError, "Tile is not passable" unless validator.valid?(target_x, target_y)

        tile_metadata = provider.metadata_at(target_x, target_y) || {}
        cooldown_seconds = environment_cooldown(zone: position.zone, tile_metadata:)
        ensure_ready!(position, cooldown_seconds:)

        encounter = resolve_encounter(provider:, zone: position.zone, x: target_x, y: target_y, tile_metadata:)

        position.update!(
          x: target_x,
          y: target_y,
          last_action_at: Time.current,
          last_turn_number: position.last_turn_number + 1
        )

        Result.new(position:, encounter:)
      end

      private

      class MovementViolationError < StandardError; end

      attr_reader :character, :direction, :rng, :movement_validator_class, :respawn_service, :encounter_resolver

      def ensure_ready?(position, cooldown_seconds:)
        position.ready_for_action?(cooldown_seconds:)
      end

      def ensure_ready!(position, cooldown_seconds:)
        return if ensure_ready?(position, cooldown_seconds:)

        raise MovementViolationError, "Action already consumed for current turn"
      end

      def fetch_offset
        OFFSETS.fetch(direction) { raise MovementViolationError, "Unknown direction #{direction}" }
      end

      def resolve_encounter(provider:, zone:, x:, y:, tile_metadata:)
        encounter_resolver.resolve(
          zone:,
          biome: provider.biome_at(x, y),
          tile_metadata: tile_metadata,
          rng:
        )
      end

      def environment_cooldown(zone:, tile_metadata:)
        base = Game::Movement::TerrainModifier
          .new(zone:)
          .cooldown_seconds(base_seconds: ACTION_COOLDOWN_SECONDS, tile_metadata:)
        (base / mount_speed_multiplier).round(2)
      end

      def mount_speed_multiplier
        @mount_speed_multiplier ||= begin
          active_mount = character.user&.mounts&.find_by(summon_state: :summoned)
          active_mount ? active_mount.travel_multiplier : 1.0
        end
      end
    end
  end
end
