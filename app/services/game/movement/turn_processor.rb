# frozen_string_literal: true

module Game
  module Movement
    # TurnProcessor enforces server-side, turn-based movement.
    #
    # Legacy synchronous movement processor used by low-level services/specs.
    # Runtime wilderness movement uses MapState, AcceptMove, and CompleteMove.
    #
    # Movement cooldown uses the captured starter movement duration: 30 seconds.
    # Skill, terrain, and encumbrance timing changes must be source-captured
    # before they become runtime formulas.
    #
    # Usage:
    #   result = Game::Movement::TurnProcessor.new(character:, direction: :north).call
    #
    # Returns:
    #   Result struct with updated position.
    class TurnProcessor
      Result = Struct.new(:position, keyword_init: true)

      BASE_MOVEMENT_COOLDOWN_SECONDS = Game::Movement::TravelTime::BASE_TRAVEL_SECONDS
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
        respawn_service: nil)
        @character = character
        @direction = direction.to_sym
        @rng = rng
        @movement_validator_class = movement_validator
        @respawn_service = respawn_service || RespawnService.new(character:)
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

        position.update!(
          x: target_x,
          y: target_y,
          last_action_at: Time.current,
          last_turn_number: position.last_turn_number + 1
        )

        Result.new(position:)
      end

      private

      class MovementViolationError < StandardError; end

      attr_reader :character, :direction, :rng, :movement_validator_class, :respawn_service

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

      def environment_cooldown(**)
        character.passive_skill_calculator
          .apply_movement_cooldown(BASE_MOVEMENT_COOLDOWN_SECONDS)
          .round(2)
      end
    end
  end
end
