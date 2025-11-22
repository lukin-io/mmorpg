# frozen_string_literal: true

module Moderation
  # Instrumentation centralizes structured logging + metric emission for moderation/live ops events.
  # Usage:
  #   Moderation::Instrumentation.track("ticket.created", ticket_id: ticket.id, category: ticket.category)
  # Returns:
  #   Hash payload that was emitted.
  class Instrumentation
    class << self
      def track(event, payload = {})
        enriched = payload.merge(event:, emitted_at: Time.current.iso8601)
        Rails.logger.tagged("moderation") { Rails.logger.info(enriched.to_json) }
        ActiveSupport::Notifications.instrument("moderation.#{event}", enriched)
        emit_statsd_metric(event, enriched)
        enriched
      end

      private

      def emit_statsd_metric(event, payload)
        return unless defined?(::StatsD)

        metric_name = "moderation.#{event.tr(".", "_")}"
        StatsD.increment(metric_name, tags: statsd_tags(payload))
      rescue => e
        Rails.logger.warn("StatsD emit failed: #{e.message}")
      end

      def statsd_tags(payload)
        payload.slice(:category, :status, :priority, :zone_key, :severity).map do |key, value|
          "#{key}:#{value}"
        end
      end
    end
  end
end
