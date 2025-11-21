# frozen_string_literal: true

class ScheduledEventJob < ApplicationJob
  queue_as :default

  def perform(event_key)
    Rails.logger.info("Executing scheduled event #{event_key}")
    # TODO: invoke Game::Events orchestration once available.
  end
end
