# frozen_string_literal: true

module Combat
  class AggregateStatsJob < ApplicationJob
    queue_as :default

    def perform(battle_id)
      battle = Battle.find(battle_id)
      payload = Game::Combat::Analytics::ReportBuilder.new(battle:).call
      battle.create_combat_analytics_report!(
        payload: payload,
        generated_at: payload[:generated_at]
      )
    end
  end
end
