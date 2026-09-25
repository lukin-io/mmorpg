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
          if character.active_airship_journey
            raise ActionViolationError, I18n.t("game.flashes.disembark_first")
          end

          @position = character.position&.reload
          if MovementCommand.moving.where(character:).exists?
            raise ActionViolationError, I18n.t("game.flashes.movement_in_progress")
          end
          if LocalActionState.new(character:).call
            raise ActionViolationError, I18n.t("game.world.local_action_in_progress")
          end
          if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
            raise ActionViolationError, I18n.t("game.world.finish_active_fight")
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
          .first || raise(ActionViolationError, I18n.t("game.world.action_offer_unavailable"))
      end

      def validate!(offer)
        raise ActionViolationError, I18n.t("game.world.action_offer_unavailable") unless offer.offered?
        raise ActionViolationError, I18n.t("game.world.action_offer_expired") if offer.expired?
        raise ActionViolationError, I18n.t("game.world.action_offer_position_mismatch") unless offer.matches_position?(position)

        if action_type.present? && offer.action_type != action_type
          raise ActionViolationError, I18n.t("game.world.action_offer_action_mismatch")
        end

        if position&.zone&.outdoor? && FATIGUE_LOCKED_ACTIONS.include?(offer.action_type) &&
            Characters::FatigueService.new(character:).outdoor_actions_blocked?
          raise ActionViolationError, I18n.t("game.world.action_too_fatigued")
        end

        return unless target

        unless offer.target_type == target.class.base_class.name && offer.target_id == target.id
          raise ActionViolationError, I18n.t("game.world.action_offer_target_mismatch")
        end
      end
    end
  end
end
