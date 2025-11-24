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
      Result = Struct.new(:allowed, :reasons, keyword_init: true) do
        def allowed?
          allowed
        end
      end

      def initialize(character:)
        @character = character
      end

      def allowed_for?(reputation: 0, faction_alignment: nil, alignment_score: nil)
        evaluate(
          reputation:,
          faction_alignment:,
          alignment_score:
        ).allowed?
      end

      def evaluate(requirements = {})
        reasons = []

        if requirements.key?(:reputation) && character.reputation < requirements[:reputation].to_i
          reasons << :reputation
        end

        if requirements[:faction_alignment].present? && requirements[:faction_alignment].to_s != character.faction_alignment
          reasons << :faction_alignment
        end

        if requirements.key?(:alignment_score) && character.alignment_score < requirements[:alignment_score].to_i
          reasons << :alignment_score
        end

        evaluate_gate(requirements[:city], :city, reasons)
        evaluate_gate(requirements[:vendor], :vendor, reasons)
        evaluate_gate(requirements[:storyline], :storyline, reasons)

        Result.new(allowed: reasons.empty?, reasons:)
      end

      private

      attr_reader :character

      def evaluate_gate(payload, prefix, reasons)
        return unless payload

        gate = payload.with_indifferent_access
        required_reputation = gate[:reputation].to_i if gate.key?(:reputation)
        required_faction = gate[:faction]

        if required_faction.present? && required_faction.to_s != character.faction_alignment
          reasons << :"#{prefix}_faction"
        end

        if required_reputation && character.reputation < required_reputation
          reasons << :"#{prefix}_reputation"
        end
      end
    end
  end
end
