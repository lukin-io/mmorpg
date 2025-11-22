# frozen_string_literal: true

module Moderation
  # AnomalyAlertJob detects report surges per zone and pings webhooks for escalation.
  #
  # Usage:
  #   Moderation::AnomalyAlertJob.perform_later("ashen_forest")
  class AnomalyAlertJob < ApplicationJob
    queue_as :moderation

    THRESHOLD = 5

    def perform(zone_key)
      recent_count = Moderation::Ticket.where(zone_key: zone_key).where("created_at >= ?", 30.minutes.ago).count
      return if recent_count < THRESHOLD

      Moderation::Instrumentation.track("ticket.anomaly", zone_key:, count: recent_count)
      Moderation::WebhookDispatcher.post!(
        message: "Spike in reports for zone #{zone_key} (#{recent_count} in 30m)",
        severity: "critical",
        context: {zone_key:, count: recent_count}
      )
    end
  end
end
