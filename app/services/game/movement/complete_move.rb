# frozen_string_literal: true

module Game
  module Movement
    # Finalizes due timed movement commands into authoritative coordinates.
    class CompleteMove
      def initialize(character:, encounter_resolver: Game::Exploration::EncounterResolver.new)
        @character = character
        @encounter_resolver = encounter_resolver
      end

      def call
        due_commands.each do |command|
          complete_command(command)
        end
      end

      private

      attr_reader :character, :encounter_resolver

      def due_commands
        MovementCommand
          .moving
          .where(character:)
          .where("ends_at <= ?", Time.current)
          .order(:ends_at)
      end

      def complete_command(command)
        command.with_lock do
          command.reload
          return unless command.moving?
          return if command.ends_at&.future?

          position = character.position || Game::Movement::RespawnService.new(character:).ensure_position!
          position.lock!

          unless source_position_matches?(command, position)
            mark_failed(command, "Character is no longer at the movement source")
            return
          end

          provider = Game::Movement::TileProvider.new(zone: command.zone)
          validator = Game::Movement::MovementValidator.new(provider)
          unless validator.valid?(command.target_x, command.target_y)
            mark_failed(command, "Tile is not passable")
            return
          end

          tile_metadata = provider.metadata_at(command.target_x, command.target_y) || {}
          encounter = resolve_encounter(command, provider, tile_metadata)
          now = Time.current

          position.update!(
            zone: command.zone,
            x: command.target_x,
            y: command.target_y,
            last_action_at: command.ends_at || now,
            last_turn_number: position.last_turn_number + 1
          )

          command.update!(
            status: :completed,
            completed_at: now,
            processed_at: now,
            latency_ms: compute_latency(command),
            metadata: (command.metadata || {}).merge("encounter" => encounter).compact,
            error_message: nil
          )
        end
      end

      def source_position_matches?(command, position)
        position.zone_id == command.zone_id &&
          position.x == command.from_x &&
          position.y == command.from_y
      end

      def resolve_encounter(command, provider, tile_metadata)
        encounter_resolver.resolve(
          zone: command.zone,
          biome: provider.biome_at(command.target_x, command.target_y),
          tile_metadata:,
          rng: Random.new(command.id)
        )
      end

      def compute_latency(command)
        return 0 unless command.created_at

        ((Time.current - command.created_at) * 1000).to_i.clamp(0, 86_400_000)
      end

      def mark_failed(command, message)
        now = Time.current
        command.update!(
          status: :failed,
          failed_at: now,
          processed_at: now,
          latency_ms: compute_latency(command),
          error_message: message
        )
      end
    end
  end
end
