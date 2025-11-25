# frozen_string_literal: true

class ScheduledEventJob < ApplicationJob
  queue_as :default

  def perform(event_slug, options = {})
    event = GameEvent.find_by!(slug: event_slug)
    Rails.logger.info("Executing scheduled event #{event.slug}")
    instance = Game::Events::Scheduler.new(event).spawn_instance!(**symbolize_keys(options))
    Game::Events::QuestOrchestrator.new(instance).prepare!(characters: Character.all)
  end

  private

  def symbolize_keys(options)
    options.each_with_object({}) do |(key, value), memo|
      memo[key.to_sym] = value.is_a?(Hash) ? symbolize_keys(value) : value
    end
  end
end
