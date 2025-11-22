# frozen_string_literal: true

module Moderation
  # DashboardPresenter aggregates moderation metrics for the admin queue widgets.
  # Usage:
  #   presenter = Moderation::DashboardPresenter.new(scope: Moderation::Ticket.all)
  #   presenter.report_volume_by_category
  class DashboardPresenter
    def initialize(scope: Moderation::Ticket.all)
      @scope = scope
    end

    def report_volume_by_category
      counts = scope.group(:category).count
      Moderation::Ticket.categories.keys.index_with { |key| counts[key] || 0 }
    end

    def average_resolution_time_hours
      resolved = scope.where.not(resolved_at: nil)
      return 0 if resolved.blank?

      total_seconds = resolved.sum("EXTRACT(EPOCH FROM resolved_at - created_at)")
      (total_seconds / resolved.count / 3600.0).round(2)
    end

    def repeat_offenders(limit: 5)
      counts = scope.where.not(subject_user_id: nil).group(:subject_user_id).count
      counts.sort_by { |_id, count| -count }.first(limit).map do |user_id, count|
        {
          user: User.find_by(id: user_id),
          count: count
        }
      end
    end

    private

    attr_reader :scope
  end
end
