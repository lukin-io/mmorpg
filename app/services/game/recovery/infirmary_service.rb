# frozen_string_literal: true

module Game
  module Recovery
    # InfirmaryService reduces trauma downtime based on zone metadata (city infirmaries, hospitals, etc.).
    #
    # Usage:
    #   Game::Recovery::InfirmaryService.new(zone: zone).stabilize!(character_position: position)
    #
    # Returns:
    #   Updated CharacterPosition or the original when no infirmary rules apply.
    class InfirmaryService
      def initialize(zone:)
        @zone = zone
      end

      def available?
        zone&.metadata&.key?("infirmary")
      end

      def stabilize!(character_position:)
        return character_position unless available?
        return character_position unless character_position&.respawn_available_at

        reduction = settings.fetch("reduction_seconds", 15).to_i
        target_time = [character_position.respawn_available_at - reduction.seconds, Time.current].max
        character_position.update!(respawn_available_at: target_time)
        character_position
      end

      private

      attr_reader :zone

      def settings
        zone.metadata.fetch("infirmary", {})
      end
    end
  end
end
