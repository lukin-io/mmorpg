# frozen_string_literal: true

module LiveOps
  # ClanWarMonitorJob inspects clan wars that run beyond their schedule and escalates anomalies.
  #
  # Usage:
  #   LiveOps::ClanWarMonitorJob.perform_later
  class ClanWarMonitorJob < ApplicationJob
    queue_as :live_ops

    def perform
      reporter = auto_reporter
      return unless reporter

      report_intake = Moderation::ReportIntake.new
      overdue_wars.find_each do |war|
        report_intake.call(
          reporter: reporter,
          source: :system,
          category: :griefing,
          description: "Clan war #{war.id} has suspicious activity in territory #{war.territory_key}",
          priority: :high,
          metadata: {
            detector: "clan_war_anomaly",
            territory_key: war.territory_key,
            attacker_clan_id: war.attacker_clan_id,
            defender_clan_id: war.defender_clan_id
          }
        )
      end
    end

    private

    def overdue_wars
      ClanWar.active.where("scheduled_at < ?", 2.hours.ago)
    end

    def auto_reporter
      User.with_role(:gm).first || User.with_role(:admin).first || User.first
    end
  end
end
