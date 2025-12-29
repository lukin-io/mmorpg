# frozen_string_literal: true

module Characters
  # Background job for server-authoritative HP/MP regeneration
  # Re-enqueues itself while character needs regen
  #
  # @example Start regen for a character
  #   Characters::RegenTickerJob.perform_later(character.id)
  #
  class RegenTickerJob < ApplicationJob
    queue_as :vitals

    # Thread-local guard to prevent infinite recursion in test mode
    # when ActiveJob test adapter runs jobs inline
    RECURSION_GUARD = :regen_ticker_executing

    def perform(character_id)
      # Prevent infinite recursion when jobs run inline (test mode)
      return if Thread.current[RECURSION_GUARD]

      begin
        Thread.current[RECURSION_GUARD] = true

        character = Character.find_by(id: character_id)
        return unless character

        service = Characters::VitalsService.new(character)
        return unless service.needs_regen?

        # Apply one tick of regeneration
        service.tick_regeneration

        # Re-enqueue if still needs regen (only in production/async mode)
        # Skip re-enqueue in test mode to prevent recursion
        return if Rails.env.test?

        if character.reload
          service = Characters::VitalsService.new(character)
          if service.needs_regen? && service.out_of_combat?
            self.class.set(wait: 1.second).perform_later(character_id)
          end
        end
      ensure
        Thread.current[RECURSION_GUARD] = nil
      end
    end
  end
end
