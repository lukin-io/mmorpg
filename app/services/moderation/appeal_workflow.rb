# frozen_string_literal: true

module Moderation
  # AppealWorkflow coordinates appeal submissions/resolutions and ticket state transitions.
  # Usage:
  #   Moderation::AppealWorkflow.new.submit(ticket:, appellant:, body: "Why I should be unbanned")
  # Returns:
  #   Moderation::Appeal
  class AppealWorkflow
    DEFAULT_SLA_HOURS = 48

    def initialize(instrumentation: Moderation::Instrumentation)
      @instrumentation = instrumentation
    end

    def submit(ticket:, appellant:, body:, sla_hours: DEFAULT_SLA_HOURS)
      raise Pundit::NotAuthorizedError unless ticket.reporter == appellant

      appeal = ticket.appeals.create!(
        appellant:,
        body: body.strip,
        sla_due_at: sla_hours.hours.from_now
      )

      ticket.update!(status: :appealed)

      instrumentation.track("appeal.submitted", ticket_id: ticket.id, appeal_id: appeal.id)

      appeal
    end

    def resolve(appeal:, reviewer:, status:, resolution_notes:)
      raise Pundit::NotAuthorizedError unless reviewer&.moderator?

      appeal.update!(
        reviewer:,
        status:,
        resolution_notes: resolution_notes
      )

      if status.to_s == "resolved_upheld"
        appeal.ticket.record_resolution!(actor: reviewer)
      elsif status.to_s == "resolved_overturned"
        appeal.ticket.reopen!(actor: reviewer)
      end

      instrumentation.track("appeal.resolved", ticket_id: appeal.ticket_id, appeal_id: appeal.id, status:)

      appeal
    end

    private

    attr_reader :instrumentation
  end
end
