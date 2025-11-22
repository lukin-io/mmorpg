# frozen_string_literal: true

module Moderation
  # TicketBroadcastJob fans out Turbo stream updates + queue metrics when a ticket changes.
  #
  # Usage:
  #   Moderation::TicketBroadcastJob.perform_later(ticket.id, event: :created)
  class TicketBroadcastJob < ApplicationJob
    queue_as :moderation

    include ActionView::RecordIdentifier

    def perform(ticket_id, event: :updated)
      ticket = Moderation::Ticket.find_by(id: ticket_id)
      return unless ticket

      broadcast_turbo(ticket, event)
      Moderation::TicketsChannel.broadcast_summary
    end

    private

    def broadcast_turbo(ticket, event)
      locals = {ticket: ticket}
      if event == :created
        Turbo::StreamsChannel.broadcast_prepend_to(
          Moderation::Ticket::BROADCAST_STREAM,
          target: "moderation_tickets_list",
          partial: "admin/moderation/tickets/ticket",
          locals:
        )
      else
        Turbo::StreamsChannel.broadcast_replace_to(
          Moderation::Ticket::BROADCAST_STREAM,
          target: dom_id(ticket),
          partial: "admin/moderation/tickets/ticket",
          locals:
        )
      end
    end
  end
end
