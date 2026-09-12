# frozen_string_literal: true

module Arena
  # The persisted application deadline is authoritative; stale/early/retried
  # deliveries are safe. Lobby refresh can recover an unavailable queue.
  class ApplicationDeadlineJob < ApplicationJob
    queue_as :arena

    def perform(application_id)
      application = ArenaApplication.find_by(id: application_id)
      return unless application&.team_battle?

      GroupAssembly.new.settle(application:)
    end
  end
end
