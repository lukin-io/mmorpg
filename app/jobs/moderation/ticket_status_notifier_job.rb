# frozen_string_literal: true

module Moderation
  # TicketStatusNotifierJob mirrors ticket status updates into player inbox + email.
  #
  # Usage:
  #   Moderation::TicketStatusNotifierJob.perform_later(ticket.id)
  class TicketStatusNotifierJob < ApplicationJob
    queue_as :moderation

    def perform(ticket_id)
      ticket = Moderation::Ticket.find_by(id: ticket_id)
      reporter = ticket&.reporter
      return unless ticket && reporter

      MailMessage.create!(
        sender: reporter,
        recipient: reporter,
        subject: "Ticket ##{ticket.id} status updated",
        body: "Your ticket is now #{ticket.status.humanize}.",
        delivered_at: Time.current
      )

      ModerationMailer.status_update(ticket:).deliver_later if reporter.email.present?
    end
  end
end
