# frozen_string_literal: true

module Game
  module Movement
    # TeleportService relocates a character instantly when premium artifacts are used.
    class TeleportService
      def initialize(character:, zone:, x:, y:, tile_provider: nil)
        @character = character
        @zone = zone
        @x = x
        @y = y
        @tile_provider = tile_provider || Game::Movement::TileProvider.new(zone: zone)
      end

      def call
        raise Pundit::NotAuthorizedError, "Invalid destination" unless valid_tile?

        position = character.position || CharacterPosition.new(character: character)
        position.update!(
          zone: zone,
          x: x,
          y: y,
          state: :active,
          last_action_at: Time.current,
          respawn_available_at: nil
        )
        position
      end

      private

      attr_reader :character, :zone, :x, :y, :tile_provider

      def valid_tile?
        MovementValidator.new(tile_provider).valid?(x, y)
      end
    end
  end
end
