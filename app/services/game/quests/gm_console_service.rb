# frozen_string_literal: true

module Game
  module Quests
    # GmConsoleService applies privileged quest operations triggered via the GM UI:
    # spawning assignments, disabling buggy quests, adjusting timers, and issuing
    # compensation. All operations are audited.
    class GmConsoleService
      class OperationError < StandardError; end

      def initialize(actor:, wallet_service: Economy::WalletService)
        @actor = actor
        @wallet_service_class = wallet_service
      end

      def spawn_assignment!(quest_key:, character_id:)
        quest = Quest.find_by!(key: quest_key)
        character = Character.find(character_id)
        gate_result = QuestGateEvaluator.new(character:, quest:).call
        raise OperationError, "Requirements not met" unless gate_result.allowed?

        assignment = QuestAssignment.find_or_initialize_by(quest:, character:)
        assignment.status = quest.repeatable_template? ? :pending : :in_progress
        assignment.started_at ||= Time.current if assignment.in_progress?
        assignment.save!

        AuditLogger.log(
          actor: actor,
          action: "gm.spawn_quest",
          target: assignment,
          metadata: {quest_key:, character_id:}
        )
        assignment
      end

      def disable_quest!(quest_key:, reason:)
        quest = Quest.find_by!(key: quest_key)
        quest.update!(
          active: false,
          metadata: quest.metadata.merge("gm_disabled_at" => Time.current, "gm_disabled_reason" => reason)
        )
        AuditLogger.log(
          actor: actor,
          action: "gm.disable_quest",
          target: quest,
          metadata: {reason: reason}
        )
        quest
      end

      def adjust_timers!(quest_key:, minutes:)
        quest = Quest.find_by!(key: quest_key)
        offset = minutes.to_i.minutes
        QuestAssignment.where(quest: quest).find_each do |assignment|
          attrs = {}
          attrs[:expires_at] = assignment.expires_at - offset if assignment.expires_at
          attrs[:next_available_at] = assignment.next_available_at - offset if assignment.next_available_at
          assignment.update!(attrs) if attrs.any?
        end
        AuditLogger.log(
          actor: actor,
          action: "gm.adjust_timers",
          target: quest,
          metadata: {minutes: minutes.to_i}
        )
        quest
      end

      def compensate_players!(quest_key:, currency:, amount:)
        quest = Quest.find_by!(key: quest_key)
        amt = amount.to_i
        raise OperationError, "Amount must be positive" unless amt.positive?

        QuestAssignment.where(quest: quest).includes(character: :user).find_each do |assignment|
          wallet = assignment.character.user.currency_wallet || assignment.character.user.create_currency_wallet!
          wallet_service_class.new(wallet:).adjust!(
            currency: currency,
            amount: amt,
            reason: "gm.compensation",
            metadata: {quest_id: quest.id, assignment_id: assignment.id}
          )
        end

        AuditLogger.log(
          actor: actor,
          action: "gm.compensate_players",
          target: quest,
          metadata: {currency:, amount: amt}
        )
        quest
      end

      private

      attr_reader :actor, :wallet_service_class
    end
  end
end
