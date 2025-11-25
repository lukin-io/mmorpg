# frozen_string_literal: true

# QuestAnalyticsJob snapshots quest completion/abandonment metrics for every
# quest chain so dashboards can render trends without running expensive queries.
class QuestAnalyticsJob < ApplicationJob
  queue_as :default

  def perform(window: 7.days)
    QuestChain.find_each do |chain|
      metrics = Analytics::QuestSnapshotCalculator.new(quest_chain: chain, window: window).call
      QuestAnalyticsSnapshot.upsert(
        {
          captured_on: Date.current,
          quest_chain_key: chain.key,
          completion_rate: metrics[:completion_rate],
          abandon_rate: metrics[:abandon_rate],
          avg_completion_minutes: metrics[:avg_minutes],
          bottleneck_step_position: metrics[:bottleneck_step_position],
          bottleneck_step_key: metrics[:bottleneck_step_key],
          metadata: {}
        },
        unique_by: :index_quest_analytics_snapshots_on_date_and_chain
      )
    end
  end
end
