# frozen_string_literal: true

class ModerationMailer < ApplicationMailer
  def penalty_notification(ticket:, action:)
    @ticket = ticket
    @action = action

    mail(
      to: ticket.reporter.email,
      subject: "Elselands Moderation Update — Ticket ##{ticket.id}"
    )
  end

  def status_update(ticket:)
    @ticket = ticket

    mail(
      to: ticket.reporter.email,
      subject: "Elselands Ticket ##{ticket.id} is now #{ticket.status.humanize}"
    )
  end
end
