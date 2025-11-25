# frozen_string_literal: true

module Moderation
  class ReportVolumeAlertJob < ApplicationJob
    queue_as :default

    def perform(source: "chat")
      window = 15.minutes.ago
      count = ChatReport.where("created_at >= ?", window).count
      return unless count >= threshold

      Moderation::WebhookDispatcher.post!(
        message: "High #{source} report volume (#{count} in last 15m)",
        severity: "warning",
        context: {source:, count:}
      )
    end

    private

    def threshold
      ENV.fetch("REPORT_VOLUME_ALERT_THRESHOLD", 25).to_i
    end
  end
end
