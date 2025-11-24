# frozen_string_literal: true

module Players
  module Progression
    # RespecService resets allocated stats/skills using either a completed quest or premium token payment.
    #
    # Usage:
    #   Players::Progression::RespecService.new(character:, source: :quest, quest_key: "rebirth_ritual").call!
    #   Players::Progression::RespecService.new(character:, source: :premium, premium_cost: 50).call!
    class RespecService
      SOURCES = %w[quest premium].freeze

      def initialize(character:, source:, quest_key: nil, premium_cost: 0, ledger: Payments::PremiumTokenLedger)
        @character = character
        @source = source.to_s
        @quest_key = quest_key
        @premium_cost = premium_cost.to_i
        @ledger = ledger
      end

      def call!
        validate_source!

        Character.transaction do
          enforce_source_requirements!
          refund_stats!
          refund_skills!
        end

        character
      end

      private

      attr_reader :character, :source, :quest_key, :premium_cost, :ledger

      def validate_source!
        raise ArgumentError, "Unknown respec source #{source}" unless SOURCES.include?(source)
      end

      def enforce_source_requirements!
        case source
        when "quest" then ensure_quest_completed!
        when "premium" then charge_premium_tokens!
        end
      end

      def ensure_quest_completed!
        quest = Quest.find_by(key: quest_key)
        raise Pundit::NotAuthorizedError, "Quest requirement missing" unless quest

        completed = QuestAssignment.exists?(quest:, character:, status: :completed)
        raise Pundit::NotAuthorizedError, "Quest not completed" unless completed
      end

      def charge_premium_tokens!
        raise ArgumentError, "premium_cost required" unless premium_cost.positive?

        ledger.debit(
          user: character.user,
          amount: premium_cost,
          reason: "character_respec",
          actor: character.user,
          metadata: {character_id: character.id}
        )
      rescue Payments::PremiumTokenLedger::InsufficientBalanceError => e
        raise Pundit::NotAuthorizedError, e.message
      end

      def refund_stats!
        spent = character.allocated_stats.values.map(&:to_i).sum
        return if spent.zero?

        character.stat_points_available += spent
        character.allocated_stats = {}
        character.save!
      end

      def refund_skills!
        spent = character.character_skills.count
        return if spent.zero?

        character.skill_points_available += spent
        character.character_skills.destroy_all
        character.save!
      end
    end
  end
end
