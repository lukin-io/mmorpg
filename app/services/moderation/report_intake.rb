# frozen_string_literal: true

module Moderation
  # ReportIntake normalizes evidence, creates Moderation::Ticket rows, and wires Action Cable broadcasts.
  # Usage:
  #   Moderation::ReportIntake.new.call(reporter:, source: :chat, category: :chat_abuse, description: "...")
  # Returns:
  #   Moderation::Ticket
  class ReportIntake
    ALLOWED_EVIDENCE_KEYS = %w[
      log_excerpt
      screenshot_url
      combat_replay_id
      chat_log_reference
      npc_key
      additional_context
    ].freeze

    def initialize(instrumentation: Moderation::Instrumentation)
      @instrumentation = instrumentation
    end

    def call(
      reporter:,
      source:,
      category:,
      description:,
      subject_user: nil,
      subject_character: nil,
      origin_reference: nil,
      evidence: {},
      metadata: {},
      priority: :normal,
      zone_key: nil,
      chat_report: nil,
      npc_report: nil
    )
      ticket = Moderation::Ticket.create!(
        reporter: reporter,
        subject_user: subject_user || chat_report&.chat_message&.sender,
        subject_character: subject_character,
        source:,
        category: category.presence || :other,
        description: description.strip,
        priority:,
        origin_reference: origin_reference || evidence["combat_replay_id"],
        evidence: sanitized_evidence(evidence),
        metadata: metadata.merge(entry_point: source.to_s),
        zone_key: zone_key || metadata[:zone_key] || metadata["zone_key"]
      )

      chat_report&.update!(moderation_ticket: ticket)
      npc_report&.update!(moderation_ticket: ticket)

      instrumentation.track(
        "ticket.created",
        ticket_id: ticket.id,
        reporter_id: reporter.id,
        category: ticket.category,
        source: ticket.source,
        zone_key: ticket.zone_key
      )

      enqueue_zone_alert(ticket)

      ticket
    end

    private

    attr_reader :instrumentation

    def sanitized_evidence(raw)
      return {} if raw.blank?

      raw.slice(*ALLOWED_EVIDENCE_KEYS)
    end

    def enqueue_zone_alert(ticket)
      return unless ticket.should_alert_zone_surge?

      Moderation::AnomalyAlertJob.perform_later(ticket.zone_key)
    end
  end
end
