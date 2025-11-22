# frozen_string_literal: true

module Moderation
  # TicketsChannel streams live moderation queue metrics to moderators.
  #
  # Usage:
  #   consumer.subscriptions.create("Moderation::TicketsChannel")
  class TicketsChannel < ApplicationCable::Channel
    STREAM = "moderation:tickets"

    def subscribed
      reject unless current_user&.moderator?
      stream_from STREAM
      transmit(queue_payload)
    end

    def self.broadcast_summary
      ActionCable.server.broadcast(STREAM, queue_payload)
    end

    def self.queue_payload
      {
        pending_count: Moderation::Ticket.open_queue.count,
        updated_at: Time.current.iso8601
      }
    end

    private

    def queue_payload
      self.class.queue_payload
    end
  end
end
