# frozen_string_literal: true

module Professions
  # Supports resetting profession progress either via premium tokens or quest completion.
  #
  # Usage:
  #   Professions::ResetService.new(progress:, actor: current_user).reset!(mode: "premium")
  class ResetService
    QUEST_KEY = "profession_reset"

    def initialize(progress:, actor:)
      @progress = progress
      @actor = actor
    end

    def reset!(mode:)
      case mode
      when "premium"
        reset_with_premium!
      when "quest"
        reset_with_quest!
      else
        raise ArgumentError, "Unknown reset mode"
      end
    end

    private

    attr_reader :progress, :actor

    def reset_with_premium!
      Payments::PremiumTokenLedger.debit(
        user: progress.user,
        amount: premium_cost,
        reason: "profession.reset",
        actor: actor,
        reference: progress
      )
      reset_progress!
    end

    def reset_with_quest!
      assignment = QuestAssignment
        .joins(:quest)
        .where(character: progress.character)
        .where(quests: {key: QUEST_KEY})
        .where(status: :completed)
        .first
      raise Pundit::NotAuthorizedError, "Complete the reset quest first" unless assignment

      reset_progress!
    end

    def reset_progress!
      progress.update!(skill_level: 1, experience: 0, mastery_tier: 0)
    end

    def premium_cost
      progress.profession.metadata.fetch("reset_cost_tokens", 150).to_i
    end
  end
end
