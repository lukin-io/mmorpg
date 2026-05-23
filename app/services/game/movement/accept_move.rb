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
        cancel_sibling_offers!(command)

        Result.new(command:, position:)
      end

      private

      attr_reader :character, :action_key, :target_x, :target_y, :direction, :respawn_service

      def ensure_not_already_moving!(position)
        return unless MovementCommand.moving.where(character:, zone: position.zone).exists?

        raise violation("Movement already in progress")
      end

      def find_offer!(position)
        scope = MovementCommand.offered.where(character:, zone: position.zone, action_key:)
        scope = scope.where(target_x:, target_y:) if target_x && target_y
        scope.order(created_at: :desc).first || raise(violation("Movement offer is no longer available"))
      end

      def validate_offer!(command, position)
        raise violation("Movement offer has expired") if command.expired_offer?
        if direction.present? && command.direction != direction.to_s
          raise violation("Movement offer does not match requested direction")
        end

        unless command.zone_id == position.zone_id && command.from_x == position.x && command.from_y == position.y
          raise violation("Movement offer does not match current position")
        end

        provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = Game::Movement::MovementValidator.new(provider)
        raise violation("Tile is not passable") unless validator.valid?(command.target_x, command.target_y)
      end

      def cancel_sibling_offers!(accepted_command)
        MovementCommand
          .offered
          .where(character:, zone: accepted_command.zone)
          .where.not(id: accepted_command.id)
          .update_all(
            status: MovementCommand.statuses.fetch("cancelled"),
            processed_at: Time.current,
            updated_at: Time.current
          )
      end

      def violation(message)
        Game::Movement::MovementViolationError.new(message)
      end
    end
  end
end
