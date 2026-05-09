# frozen_string_literal: true

module Game
  module Movement
    # Accepts a server-offered destination and starts timed travel.
    class AcceptMove
      Result = Struct.new(:command, :position, keyword_init: true)

      def initialize(character:, action_key: nil, target_x: nil, target_y: nil, direction: nil, respawn_service: nil)
        @character = character
        @action_key = action_key.presence
        @target_x = target_x.presence&.to_i
        @target_y = target_y.presence&.to_i
        @direction = direction.presence&.to_sym
        @respawn_service = respawn_service || Game::Movement::RespawnService.new(character:)
      end

      def call
        Game::Movement::CompleteMove.new(character:).call
        position = respawn_service.ensure_position!.reload
        ensure_not_already_moving!(position)

        command = find_offer!(position)
        validate_offer!(command, position)

        command.with_lock do
          command.reload
          raise violation("Movement offer is no longer available") unless command.offered?

          now = Time.current
          command.update!(
            status: :moving,
            started_at: now,
            ends_at: now + command.travel_seconds.seconds,
            error_message: nil
          )
        end

        Result.new(command:, position:)
      end

      private

      attr_reader :character, :action_key, :target_x, :target_y, :direction, :respawn_service

      def ensure_not_already_moving!(position)
        return unless MovementCommand.moving.where(character:, zone: position.zone).exists?

        raise violation("Movement already in progress")
      end

      def find_offer!(position)
        return find_offer_by_direction!(position) if action_key.blank? && direction

        scope = MovementCommand.offered.where(character:, zone: position.zone, action_key:)
        scope = scope.where(target_x:, target_y:) if target_x && target_y
        scope.order(created_at: :desc).first || raise(violation("Movement offer is no longer available"))
      end

      def find_offer_by_direction!(position)
        state = Game::Movement::MapState.new(character:, respawn_service:).call
        destination = state.destinations.find { |offer| offer.direction == direction.to_s }
        raise violation("Movement offer is no longer available") unless destination

        MovementCommand.offered.find(destination.id)
      end

      def validate_offer!(command, position)
        raise violation("Movement offer has expired") if command.expired_offer?

        unless command.zone_id == position.zone_id && command.from_x == position.x && command.from_y == position.y
          raise violation("Movement offer does not match current position")
        end

        provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = Game::Movement::MovementValidator.new(provider)
        raise violation("Tile is not passable") unless validator.valid?(command.target_x, command.target_y)
      end

      def violation(message)
        Game::Movement::TurnProcessor::MovementViolationError.new(message)
      end
    end
  end
end
