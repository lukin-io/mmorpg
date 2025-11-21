# frozen_string_literal: true

class BattleResolutionJob < ApplicationJob
  queue_as :combat

  def perform(battle_id)
    Rails.logger.info("Resolving battle #{battle_id}")
    # TODO: integrate Game::Combat services once battle records exist.
  end
end
