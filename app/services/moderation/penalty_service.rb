# frozen_string_literal: true

module Moderation
  # PenaltyService applies moderator decisions (warnings, bans, refunds) and records Moderation::Action rows.
  # Usage:
  #   Moderation::PenaltyService.new(ticket:, actor:).call(action_type: :warning, reason: "Stop spamming")
  # Returns:
  #   Moderation::Action
  class PenaltyService
    def initialize(ticket:, actor:, instrumentation: Moderation::Instrumentation, ledger: Payments::PremiumTokenLedger, audit_logger: AuditLogger)
      @ticket = ticket
      @actor = actor
      @instrumentation = instrumentation
      @ledger = ledger
      @audit_logger = audit_logger
    end

    def call(action_type:, reason:, duration_seconds: nil, target_user: ticket.subject_user, target_character: ticket.subject_character, context: {}, metadata: {})
      raise Pundit::NotAuthorizedError unless actor&.moderator?

      action = nil

      ApplicationRecord.transaction do
        action = ticket.actions.create!(
          actor:,
          target_user:,
          target_character:,
          action_type:,
          reason:,
          duration_seconds:,
          context: context || {},
          metadata: metadata || {}
        )

        apply_effects(action)
        ticket.mark_action_taken!(actor:)
      end

      instrumentation.track("penalty.applied", ticket_id: ticket.id, action_type:, actor_id: actor.id)

      action
    end

    private

    attr_reader :ticket, :actor, :instrumentation, :ledger, :audit_logger

    def apply_effects(action)
      case action.action_type
      when "warning", "note"
        log_audit(action, "moderation.warning")
      when "mute"
        apply_mute(action)
      when "temp_ban"
        suspend_user(action, permanent: false)
      when "permanent_ban"
        suspend_user(action, permanent: true)
      when "trade_lock"
        trade_lock_user(action)
      when "premium_refund"
        refund_premium_tokens(action)
      when "quest_adjustment"
        log_audit(action, "moderation.quest_adjustment")
      end
    end

    def apply_mute(action)
      return unless action.target_user

      ChatModerationAction.create!(
        target_user: action.target_user,
        actor: action.actor,
        action_type: :mute_global,
        expires_at: action.expires_at || 1.hour.from_now,
        context: action.context.merge("reason" => action.reason)
      )

      log_audit(action, "moderation.mute")
    end

    def suspend_user(action, permanent:)
      return unless action.target_user

      new_time = permanent ? 100.years.from_now : (action.expires_at || 7.days.from_now)
      action.target_user.update!(suspended_until: new_time)
      log_audit(action, permanent ? "moderation.permanent_ban" : "moderation.temp_ban")
    end

    def trade_lock_user(action)
      return unless action.target_user

      lock_until = action.expires_at || 3.days.from_now
      action.target_user.update!(trade_locked_until: lock_until)
      log_audit(action, "moderation.trade_lock")
    end

    def refund_premium_tokens(action)
      return unless action.target_user

      amount = action.metadata.fetch("token_delta", 0).to_i
      return if amount.zero?

      ledger.adjust(
        user: action.target_user,
        delta: amount,
        reason: "Moderation refund for ticket #{ticket.id}",
        actor: actor,
        metadata: action.metadata.merge(ticket_id: ticket.id),
        reference: ticket
      )
    end

    def log_audit(action, event)
      audit_logger.log(
        actor: action.actor,
        action: event,
        target: action.target_user || ticket,
        metadata: action.metadata.merge(ticket_id: ticket.id, reason: action.reason)
      )
    end
  end
end
