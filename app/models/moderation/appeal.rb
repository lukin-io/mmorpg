# frozen_string_literal: true

module Moderation
  # Appeal represents a player-submitted request to revisit a ticket decision with SLA tracking.
  # Usage:
  #   Moderation::Appeal.create!(ticket:, appellant:, body: "Please reconsider", sla_due_at: 48.hours.from_now)
  # Returns:
  #   Moderation::Appeal
  class Appeal < ApplicationRecord
    self.table_name = "moderation_appeals"
    enum :status, {
      submitted: "submitted",
      acknowledged: "acknowledged",
      resolved_upheld: "resolved_upheld",
      resolved_overturned: "resolved_overturned"
    }, prefix: true

    belongs_to :ticket, class_name: "Moderation::Ticket"
    belongs_to :appellant, class_name: "User"
    belongs_to :reviewer, class_name: "User", optional: true

    validates :body, presence: true

    after_commit :maybe_reopen_ticket, on: :update

    scope :overdue, -> { where(status: :submitted).where("sla_due_at < ?", Time.current) }

    private

    def maybe_reopen_ticket
      return unless saved_change_to_status? && status_resolved_overturned?

      ticket.reopen!(actor: reviewer) if reviewer
    end
  end
end
