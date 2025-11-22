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

      ACTION_COOLDOWN_SECONDS = 2
      OFFSETS = {
        north: [0, -1],
        south: [0, 1],
        east: [1, 0],
        west: [-1, 0]
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
        ensure_ready!(position)

        dx, dy = fetch_offset
        target_x = position.x + dx
        target_y = position.y + dy

        provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = movement_validator_class.new(provider)
        raise MovementViolationError, "Tile is not passable" unless validator.valid?(target_x, target_y)

        encounter = resolve_encounter(provider:, zone: position.zone, x: target_x, y: target_y)

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

      def ensure_ready?(position)
        position.ready_for_action?(cooldown_seconds: ACTION_COOLDOWN_SECONDS)
      end

      def ensure_ready!(position)
        return if ensure_ready?(position)

        raise MovementViolationError, "Action already consumed for current turn"
      end

      def fetch_offset
        OFFSETS.fetch(direction) { raise MovementViolationError, "Unknown direction #{direction}" }
      end

      def resolve_encounter(provider:, zone:, x:, y:)
        encounter_resolver.resolve(
          zone:,
          biome: provider.biome_at(x, y),
          tile_metadata: provider.metadata_at(x, y),
          rng:
        )
      end
    end
  end
end

