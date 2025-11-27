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

    def perform(character_id)
      character = Character.find_by(id: character_id)
      return unless character

      service = Characters::VitalsService.new(character)
      return unless service.needs_regen?

      # Apply one tick of regeneration
      service.tick_regeneration

      # Re-enqueue if still needs regen
      if character.reload
        service = Characters::VitalsService.new(character)
        if service.needs_regen? && service.out_of_combat?
          self.class.set(wait: 1.second).perform_later(character_id)
        end
      end
    end
  end
end
