# frozen_string_literal: true

module Players
  module Alignment
    # AccessGate answers whether a character meets faction/reputation requirements.
    #
    # Usage:
    #   Players::Alignment::AccessGate.new(character:).allowed_for?(reputation: 500)
    #
    # Returns:
    #   Boolean
    class AccessGate
      def initialize(character:)
        @character = character
      end

      def allowed_for?(reputation: 0, faction_alignment: nil, alignment_score: nil)
        reputation_check = character.reputation >= reputation.to_i
        faction_check = faction_alignment.blank? || faction_alignment.to_s == character.faction_alignment
        alignment_check = alignment_score.nil? || character.alignment_score >= alignment_score

        reputation_check && faction_check && alignment_check
      end

      private

      attr_reader :character
    end
  end
end
