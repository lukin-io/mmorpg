# frozen_string_literal: true

module Analytics
  # QuestSnapshotCalculator produces aggregate quest metrics for a quest chain
  # over a configurable time window. The results are written into
  # QuestAnalyticsSnapshot by QuestAnalyticsJob.
  #
  # Usage:
  #   Analytics::QuestSnapshotCalculator.new(quest_chain:, window: 7.days).call
  #
  # Returns:
  #   Hash with :completion_rate, :abandon_rate, :avg_minutes, and
  #   :bottleneck metadata.
  class QuestSnapshotCalculator
    def initialize(quest_chain:, window: 7.days)
      @quest_chain = quest_chain
      @window = window
    end

    def call
      total = scoped_assignments.count
      completed = scoped_assignments.completed.count
      abandoned = scoped_assignments.where.not(abandoned_at: nil).count
      avg_minutes = average_completion_minutes
      bottleneck = bottleneck_step

      {
        completion_rate: percentage(completed, total),
        abandon_rate: percentage(abandoned, total),
        avg_minutes: avg_minutes,
        bottleneck_step_position: bottleneck[:position],
        bottleneck_step_key: bottleneck[:step_key]
      }
    end

    private

    attr_reader :quest_chain, :window

    def window_range
      window.ago..Time.current
    end

    def scoped_assignments
      @scoped_assignments ||= QuestAssignment
        .where(quest_id: quest_chain.quests.select(:id))
        .where(updated_at: window_range)
    end

    def percentage(count, total)
      return 0 if total.zero?

      ((count.to_f / total) * 100).round(2)
    end

    def average_completion_minutes
      rows = scoped_assignments
        .where(status: :completed)
        .where.not(started_at: nil, completed_at: nil)
        .pluck(:started_at, :completed_at)

      return 0 if rows.empty?

      total_minutes = rows.sum do |started_at, completed_at|
        ((completed_at - started_at) / 60).round
      end
      total_minutes / rows.size
    end

    def bottleneck_step
      failures = scoped_assignments.where(status: [:failed, :expired])
      counts = Hash.new(0)

      failures.find_each do |assignment|
        position = assignment.current_step_position
        counts[[assignment.quest_id, position]] += 1
      end

      quest_id, position = counts.max_by { |_key, value| value }&.first
      return {position: nil, step_key: nil} unless quest_id && position

      step = QuestStep.find_by(quest_id:, position:)
      {
        position: position,
        step_key: step&.npc_key || "step_#{position}"
      }
    end
  end
end
