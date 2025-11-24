# frozen_string_literal: true

module GameOverview
  # SnapshotJob persists a periodic engagement snapshot so the overview page
  # can display deltas without recomputing heavy queries on every request.
  class SnapshotJob < ApplicationJob
    queue_as :low

    def perform
      snapshot = SuccessMetricsSnapshot.new.call
      GameOverviewSnapshot.create!(snapshot)
    end
  end
end
