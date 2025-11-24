# frozen_string_literal: true

module Economy
  # FraudDetector scans recent trades for gold-selling or duping patterns.
  class FraudDetector
    GOLD_THRESHOLD = 100_000

    def initialize(report_intake: Moderation::ReportIntake.new, now: Time.current)
      @report_intake = report_intake
      @now = now
    end

    def call
      suspicious_sessions.each do |session|
        create_alert!(session)
        notify_moderation!(session)
      end
    end

    private

    attr_reader :report_intake, :now

    def suspicious_sessions
      TradeSession
        .where(completed_at: window..now)
        .includes(:trade_items, :initiator, :recipient)
        .select { |session| suspicious_session?(session) }
    end

    def suspicious_session?(session)
      preview = Trades::PreviewBuilder.new(trade_session: session).call
      preview.net_gold.abs >= GOLD_THRESHOLD || preview.net_premium_tokens.positive?
    end

    def create_alert!(session)
      EconomyAlert.create!(
        alert_type: "trade_anomaly",
        trade_session: session,
        payload: {
          initiator_id: session.initiator_id,
          recipient_id: session.recipient_id,
          trade_item_ids: session.trade_items.pluck(:id)
        },
        flagged_at: now
      )
    end

    def notify_moderation!(session)
      reporter = session.initiator
      report_intake.call(
        reporter: reporter,
        source: :system,
        category: :economy,
        description: "Suspicious trade volume detected (session ##{session.id})",
        subject_user: session.recipient,
        metadata: {
          detector: "economy",
          trade_session_id: session.id
        },
        priority: :urgent
      )
    end

    def window
      24.hours.ago
    end
  end
end
