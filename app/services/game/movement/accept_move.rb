# frozen_string_literal: true

module Game
  module Movement
    # Validates an owned move before resolving same-cell interruption or starting
    # timed travel. Both results share the character lock with other World actions.
    class AcceptMove
      Result = Struct.new(:command, :position, :interruption, keyword_init: true)

      def initialize(character:, action_key: nil, target_x: nil, target_y: nil, direction: nil, respawn_service: nil, rng: Random.new)
        @character = character
        @action_key = action_key.presence
        @target_x = target_x.presence&.to_i
        @target_y = target_y.presence&.to_i
        @direction = direction.presence&.to_sym
        @respawn_service = respawn_service || Game::Movement::RespawnService.new(character:)
        @rng = rng
      end

      def call
        Game::Movement::CompleteMove.new(character:).call
        character.with_lock do
          character.reload
          raise violation("Disembark before moving on foot") if character.active_airship_journey

          position = respawn_service.ensure_position!.reload
          raise violation("Wilderness movement is unavailable here") unless position.zone.outdoor?
          ensure_not_already_moving!
          if Game::World::LocalActionState.new(character:).call
            raise violation("A local action is already in progress")
          end
          ensure_not_fatigued!

          command = find_offer!(position)

          command.with_lock do
            command.reload
            raise violation("Movement offer is no longer available") unless command.offered?
            validate_offer!(command, position)

            interruption = Game::World::InterruptAction.new(character:).call
            if interruption.interrupted?
              next Result.new(command:, position:, interruption:)
            end

            now = Time.current
            command.update!(
              status: :moving,
              started_at: now,
              ends_at: now + command.travel_seconds.seconds,
              error_message: nil,
              metadata: command.metadata.to_h.merge("fatigue_gain" => rng.rand(1..2))
            )
            cancel_sibling_offers!(command)

            Result.new(command:, position:)
          end
        end
      end

      private

      attr_reader :character, :action_key, :target_x, :target_y, :direction, :respawn_service, :rng

      def ensure_not_fatigued!
        return unless Characters::FatigueService.new(character:).outdoor_actions_blocked?

        raise violation("Too fatigued to move")
      end

      def ensure_not_already_moving!
        return unless MovementCommand.moving.where(character:).exists?

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

        unless Game::Movement::Directions.matches?(
          direction: command.direction,
          from_x: command.from_x,
          from_y: command.from_y,
          target_x: command.target_x,
          target_y: command.target_y
        )
          raise violation("Movement offer is not an adjacent step")
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
        WorldActionOffer.offered.where(character:).update_all(
          status: WorldActionOffer.statuses.fetch("cancelled"),
          updated_at: Time.current
        )
      end

      def violation(message)
        Game::Movement::MovementViolationError.new(message)
      end
    end
  end
end
