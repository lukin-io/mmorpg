# frozen_string_literal: true

module Moderation
  # PenaltyNotifier fans out penalty events to in-game mail + email and posts urgent alerts to webhooks.
  # Usage:
  #   Moderation::PenaltyNotifier.call(action: moderation_action)
  # Returns:
  #   true
  class PenaltyNotifier
    def self.call(action:)
      new(action:).call
    end

    def initialize(action:, mailer: ModerationMailer, webhook_dispatcher: Moderation::WebhookDispatcher, instrumentation: Moderation::Instrumentation)
      @action = action
      @mailer = mailer
      @webhook_dispatcher = webhook_dispatcher
      @instrumentation = instrumentation
    end

    def call
      notify_inbox
      notify_email
      notify_webhooks_if_urgent
      instrumentation.track(
        "action.created",
        ticket_id: ticket.id,
        action_type: action.action_type,
        actor_id: action.actor_id,
        target_user_id: action.target_user_id,
        expires_at: action.expires_at
      )
      true
    end

    private

    attr_reader :action, :mailer, :webhook_dispatcher, :instrumentation

    delegate :ticket, to: :action

    def notify_inbox
      return unless ticket.reporter

      MailMessage.create!(
        sender: action.actor,
        recipient: ticket.reporter,
        subject: "Ticket ##{ticket.id} update: #{ticket.status.titleize}",
        body: inbox_copy,
        delivered_at: Time.current
      )
    end

    def notify_email
      return unless ticket.reporter&.email.present?

      mailer.penalty_notification(ticket:, action:).deliver_later
    end

    def notify_webhooks_if_urgent
      return unless urgent_action?

      webhook_dispatcher.post!(
        message: "Urgent moderation action #{action.action_type} on ticket #{ticket.id}",
        severity: "critical",
        context: {
          ticket_id: ticket.id,
          action_type: action.action_type,
          actor_id: action.actor_id
        }
      )
    end

    def urgent_action?
      action.action_type_permanent_ban? || action.action_type_trade_lock? || action.action_type_premium_refund?
    end

    def inbox_copy
      lines = [
        "Your report (ticket ##{ticket.id}) now has status #{ticket.status.humanize}.",
        "Moderator notes: #{action.reason}"
      ]
      if (duration = action_duration_copy)
        lines << "Duration: #{duration}"
      end
      lines.join("\n\n")
    end

    def action_duration_copy
      if action.action_type_permanent_ban?
        "Permanent"
      elsif action.expires_at.present?
        "Until #{action.expires_at.utc.iso8601}"
      elsif action.duration_seconds.present?
        human_duration(action.duration_seconds)
      end
    end

    def human_duration(seconds)
      return if seconds.to_i <= 0

      parts = ActiveSupport::Duration.build(seconds.to_i).parts.reject { |_unit, value| value.zero? }
      return "#{seconds.to_i} seconds" if parts.empty?

      parts.map do |unit, value|
        unit_name = unit.to_s.tr("_", " ")
        "#{value} #{ActiveSupport::Inflector.pluralize(unit_name, value)}"
      end.join(", ")
    end
  end
end
