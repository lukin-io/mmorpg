# frozen_string_literal: true

module Game
  module World
    # Reconciles the character's accepted Look Around timer and returns its
    # offer while work remains active, otherwise nil. The persisted deadline
    # owns completion; reloads and modal dismissal cannot restart it. Calls
    # lock the character before the offer, complete due work, and cancel work
    # superseded by a fight or fail work whose source position no longer fits.
    # No resource, currency, or coordinate changes occur here.
    class LocalActionState
      def initialize(character:, clock: -> { Time.current })
        @character = character
        @clock = clock
      end

      def call
        character.with_lock do
          character.reload
          offer = WorldActionOffer.timed_local_actions.where(character:).order(:accepted_at, :id).first
          next unless offer

          offer.with_lock do
            offer.reload
            next unless offer.accepted?

            if character.arena_participations.joins(:arena_match).merge(ArenaMatch.active).exists?
              offer.update!(status: :cancelled)
              next
            end

            unless offer.matches_position?(character.position)
              offer.fail!("Character is no longer at the local action cell")
              next
            end

            deadline = offer.local_action_ends_at
            unless deadline
              offer.fail!("Local action deadline is invalid")
              next
            end

            now = clock.call
            if now >= deadline
              offer.update!(status: :completed, completed_at: now, error_message: nil)
              next
            end

            offer
          end
        end
      end

      private

      attr_reader :character, :clock
    end
  end
end
