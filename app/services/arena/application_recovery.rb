# frozen_string_literal: true

module Arena
  # Bounded recovery of persisted deadlines when queue delivery is delayed.
  # Called before controller character locks, preserving room-first assembly.
  class ApplicationRecovery
    def self.call(scope:)
      scope.open.where("expires_at <= ?", Time.current).limit(100).each do |application|
        if application.team_battle?
          GroupAssembly.new.settle(application:)
        else
          application.with_lock do
            next unless application.open? && application.deadline_passed?

            application.update!(status: :expired)
          end
        end
      end
    end
  end
end
