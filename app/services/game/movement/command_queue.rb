# frozen_string_literal: true

module Game
  module Movement
    # CommandQueue enqueues deterministic movement commands and processes them via TurnProcessor.
    #
    # Usage:
    #   queue = Game::Movement::CommandQueue.new(character: character)
    #   command = queue.enqueue(direction: :north)
    #   queue.process(command)
    #
    # Returns:
    #   MovementCommand after enqueue/process.
    class CommandQueue
      def initialize(character:, respawn_service: nil)
        @character = character
        @respawn_service = respawn_service || Game::Movement::RespawnService.new(character:)
      end

      def enqueue(direction:)
        position = respawn_service.ensure_position!
        offsets = Game::Movement::TurnProcessor::OFFSETS
        offset = offsets.fetch(direction.to_sym) { raise ArgumentError, "Unknown direction #{direction}" }

        target_x = position.x + offset.first
        target_y = position.y + offset.last

        tile_provider = Game::Movement::TileProvider.new(zone: position.zone)
        validator = Game::Movement::MovementValidator.new(tile_provider)
        unless validator.valid?(target_x, target_y)
          raise Game::Movement::TurnProcessor::MovementViolationError, "Tile is not passable"
        end
        tile_metadata = tile_provider.metadata_at(target_x, target_y) || {}
        terrain_type = tile_provider.terrain_type_at(target_x, target_y)
        biome = tile_provider.biome_at(target_x, target_y)

        command = MovementCommand.create!(
          character:,
          zone: position.zone,
          direction: direction.to_s,
          predicted_x: target_x,
          predicted_y: target_y,
          metadata: build_metadata(tile_metadata, biome:, terrain_type:)
        )

        Game::MovementCommandProcessorJob.perform_later(command.id)
        command
      end

      def process(command_or_id)
        command = load_command(command_or_id)
        return command if command.processed? || command.failed?

        command.processing!

        begin
          result = Game::Movement::TurnProcessor.new(
            character: command.character,
            direction: command.direction.to_sym,
            rng: Random.new(command.id),
            respawn_service: Game::Movement::RespawnService.new(character: command.character)
          ).call

          command.update!(
            status: :processed,
            processed_at: Time.current,
            latency_ms: compute_latency(command),
            metadata: command.metadata.merge("encounter" => result.encounter),
            error_message: nil
          )
          result
        rescue Game::Movement::TurnProcessor::MovementViolationError => e
          mark_failed(command, e.message)
          nil
        rescue => e
          mark_failed(command, e.message)
          raise
        end
      end

      private

      attr_reader :character, :respawn_service

      def load_command(command_or_id)
        command_or_id.is_a?(MovementCommand) ? command_or_id : MovementCommand.lock.find(command_or_id)
      end

      def build_metadata(tile_metadata, biome:, terrain_type:)
        {
          "terrain_modifier" => tile_metadata["movement_modifier"],
          "terrain_type" => terrain_type || tile_metadata["terrain_type"],
          "biome" => biome
        }.compact
      end

      def compute_latency(command)
        ((Time.current - command.created_at) * 1000).to_i.clamp(0, 86_400_000)
      end

      def mark_failed(command, message)
        command.update!(
          status: :failed,
          processed_at: Time.current,
          latency_ms: compute_latency(command),
          error_message: message
        )
      end
    end
  end
end
