# frozen_string_literal: true

require "securerandom"

module Game
  module Movement
    # Builds the server-authored movement state rendered by the wilderness map.
    class MapState
      Result = Struct.new(:position, :active_command, :destinations, :locked_reason, keyword_init: true)

      Destination = Struct.new(
        :id,
        :direction,
        :from_x,
        :from_y,
        :target_x,
        :target_y,
        :action_key,
        :travel_seconds,
        :metadata,
        keyword_init: true
      )

      OFFER_TTL = 10.minutes

      def initialize(character:, respawn_service: nil)
        @character = character
        @respawn_service = respawn_service || Game::Movement::RespawnService.new(character:)
      end

      def call
        Game::Movement::CompleteMove.new(character:).call
        position = respawn_service.ensure_position!.reload
        active_command = active_travel_for(position)

        return Result.new(position:, active_command:, destinations: [], locked_reason: :moving) if active_command

        cancel_open_offers!
        destinations = build_destination_offers(position)
        Result.new(position:, active_command: nil, destinations:, locked_reason: nil)
      end

      private

      attr_reader :character, :respawn_service

      def active_travel_for(position)
        MovementCommand
          .moving
          .where(character:, zone: position.zone)
          .order(:ends_at)
          .first
      end

      def cancel_open_offers!
        MovementCommand
          .offered
          .where(character:)
          .update_all(
            status: MovementCommand.statuses.fetch("cancelled"),
            processed_at: Time.current,
            updated_at: Time.current
          )
      end

      def build_destination_offers(position)
        provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = Game::Movement::MovementValidator.new(provider)

        Game::Movement::TurnProcessor::OFFSETS.filter_map do |direction, (dx, dy)|
          target_x = position.x + dx
          target_y = position.y + dy
          next unless validator.valid?(target_x, target_y)

          tile_metadata = provider.metadata_at(target_x, target_y) || {}
          command = MovementCommand.create!(
            character:,
            zone: position.zone,
            status: :offered,
            direction: direction.to_s,
            from_x: position.x,
            from_y: position.y,
            target_x:,
            target_y:,
            predicted_x: target_x,
            predicted_y: target_y,
            action_key: SecureRandom.hex(16),
            travel_seconds: Game::Movement::TravelTime.seconds(
              character:,
              zone: position.zone,
              direction:,
              tile_metadata:
            ),
            metadata: build_metadata(provider, target_x, target_y, tile_metadata)
          )

          Destination.new(
            id: command.id,
            direction: command.direction,
            from_x: command.from_x,
            from_y: command.from_y,
            target_x: command.target_x,
            target_y: command.target_y,
            action_key: command.action_key,
            travel_seconds: command.travel_seconds,
            metadata: command.metadata
          )
        end
      end

      def build_metadata(provider, target_x, target_y, tile_metadata)
        {
          "biome" => provider.biome_at(target_x, target_y),
          "terrain_type" => provider.terrain_type_at(target_x, target_y) || tile_metadata["terrain_type"],
          "terrain_modifier" => tile_metadata["movement_modifier"]
        }.compact
      end
    end
  end
end
