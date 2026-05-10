# frozen_string_literal: true

module Game
  module World
    # Validates and accepts a persisted world action offer.
    class AcceptAction
      class ActionViolationError < StandardError; end

      def initialize(character:, action_key:, action_type: nil, target: nil, position: nil)
        @character = character
        @action_key = action_key.presence
        @action_type = action_type&.to_s
        @target = target
        @position = position || character.position
      end

      def call
        offer = find_offer

        offer.with_lock do
          offer.reload
          validate!(offer)
          offer.accept!
        end

        offer
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
        raise ActionViolationError, "Action offer has expired" if offer.expired?
        raise ActionViolationError, "Action offer does not match current position" unless offer.matches_position?(position)

        if action_type.present? && offer.action_type != action_type
          raise ActionViolationError, "Action offer does not match requested action"
        end

        return unless target

        unless offer.target_type == target.class.base_class.name && offer.target_id == target.id
          raise ActionViolationError, "Action offer does not match requested target"
        end
      end
    end
  end
end
