# frozen_string_literal: true

module LiveOps
  # ArenaMonitorJob flags suspicious arena ladder spikes and opens moderation tickets.
  #
  # Usage:
  #   LiveOps::ArenaMonitorJob.perform_later
  class ArenaMonitorJob < ApplicationJob
    queue_as :live_ops

    RATING_THRESHOLD = 2200

    def perform
      reporter = auto_reporter
      return unless reporter

      report_intake = Moderation::ReportIntake.new
      suspicious_rankings.find_each do |ranking|
        next unless ranking.character&.user

        report_intake.call(
          reporter: reporter,
          subject_user: ranking.character.user,
          subject_character: ranking.character,
          source: :system,
          category: :exploit,
          description: "Arena rating spike detected",
          priority: :urgent,
          metadata: {
            detector: "arena_rating_spike",
            rating: ranking.rating,
            character_id: ranking.character_id
          }
        )
      end
    end

    private

    def suspicious_rankings
      ArenaRanking.where("rating >= ?", RATING_THRESHOLD).where("updated_at >= ?", 1.hour.ago)
    end

    def auto_reporter
      User.with_role(:gm).first || User.with_role(:admin).first || User.first
    end
  end
end
