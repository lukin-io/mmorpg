# frozen_string_literal: true

module Game
  module World
    # Accepts a live owned offer against fresh position/travel state. The
    # character lock is retained through an enclosing action transaction so
    # movement cannot race its cell-local side effects.
    class AcceptAction
      class ActionViolationError < StandardError; end
      FATIGUE_LOCKED_ACTIONS = %w[enter_building search_resources].freeze

      def initialize(character:, action_key:, action_type: nil, target: nil, position: nil)
        @character = character
        @action_key = action_key.presence
        @action_type = action_type&.to_s
        @target = target
        @position = position || character.position
      end

      def call
        Game::Movement::CompleteMove.new(character:).call
        character.with_lock do
          character.reload
          @position = character.position&.reload
          if MovementCommand.moving.where(character:).exists?
            raise ActionViolationError, "Movement already in progress"
          end
          if LocalActionState.new(character:).call
            raise ActionViolationError, "A local action is already in progress"
          end
          if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
            raise ActionViolationError, "Finish the active fight before continuing"
          end

          offer = find_offer

          offer.with_lock do
            offer.reload
            validate!(offer)
            offer.accept!
          end

          offer
        end
      end

      private

      attr_reader :character, :action_key, :action_type, :target, :position

      def find_offer
        WorldActionOffer
          .offered
          .where(character:, action_key:)
          .order(created_at: :desc)
          .first || raise(ActionViolationError, "Action offer is no longer available")
      end

      def validate!(offer)
        raise ActionViolationError, "Action offer is no longer available" unless offer.offered?
        raise ActionViolationError, "Action offer has expired" if offer.expired?
        raise ActionViolationError, "Action offer does not match current position" unless offer.matches_position?(position)

        if action_type.present? && offer.action_type != action_type
          raise ActionViolationError, "Action offer does not match requested action"
        end

        if position&.zone&.outdoor? && FATIGUE_LOCKED_ACTIONS.include?(offer.action_type) &&
            Characters::FatigueService.new(character:).outdoor_actions_blocked?
          raise ActionViolationError, "Too fatigued for this action"
        end

        return unless target

        unless offer.target_type == target.class.base_class.name && offer.target_id == target.id
          raise ActionViolationError, "Action offer does not match requested target"
        end
      end
    end
  end
end
