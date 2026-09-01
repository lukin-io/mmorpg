# frozen_string_literal: true

module Game
  module World
    # Schedules and resolves a hidden hostile's passive same-cell attack.
    #
    # The browser supplies no gameplay inputs. A persisted per-character due
    # time prevents reloads, forged early checks, and overlapping timers from
    # choosing the encounter or accelerating it. Once due, StartNpcFight owns
    # the same locked match creation used by synchronous World interruptions.
    class PassiveEncounterCheck
      SCHEDULE_METADATA_KEY = "world_passive_encounter"
      MIN_DELAY_SECONDS = 10
      MAX_DELAY_SECONDS = 30
      EMPTY_RECHECK_SECONDS = 30

      Result = Struct.new(:interrupted, :match, :message, :retry_after_ms, keyword_init: true) do
        def interrupted?
          interrupted
        end
      end

      def initialize(character:, return_context: "world", clock: -> { Time.current }, rng: Random.new)
        @character = character
        @return_context = return_context
        @clock = clock
        @rng = rng
      end

      def call
        if (match = active_match)
          clear_schedule!
          return Result.new(
            interrupted: true,
            match:,
            message: "Finish the active fight before continuing."
          )
        end

        decision = schedule_decision
        return decision if decision.is_a?(Result)

        npc = decision.fetch(:npc)
        match = StartNpcFight.new(character:, tile_npc: npc, return_context:).call
        clear_schedule!

        Result.new(
          interrupted: true,
          match:,
          message: "#{npc.display_name} attacks while you wait."
        )
      rescue StartNpcFight::FightViolationError
        clear_schedule!
        raise
      end

      private

      attr_reader :character, :return_context, :clock, :rng

      def schedule_decision
        character.with_lock do
          character.reload
          position = character.position
          npc = hostile_npc_at(position)

          unless npc
            remove_schedule_from_locked_character!
            next waiting_result(EMPTY_RECHECK_SECONDS)
          end

          now = clock.call
          fingerprint = schedule_fingerprint(position, npc)
          schedule = character.metadata.to_h[SCHEDULE_METADATA_KEY]
          due_at = parsed_due_at(schedule)

          unless schedule_matches?(schedule, fingerprint) && due_at
            delay = rng.rand(MIN_DELAY_SECONDS..MAX_DELAY_SECONDS)
            due_at = now + delay
            persist_schedule!(fingerprint.merge("due_at" => due_at.iso8601(6)))
            next waiting_result(delay)
          end

          next waiting_result((due_at - now).ceil) if now < due_at

          {npc:}
        end
      end

      def hostile_npc_at(position)
        return unless position&.zone&.outdoor?

        npc = TileNpcService.new(
          character:,
          zone: position.zone,
          x: position.x,
          y: position.y
        ).tile_npc

        npc if npc&.alive? && npc.hostile?
      end

      def schedule_fingerprint(position, npc)
        {
          "zone_id" => position.zone_id,
          "x" => position.x,
          "y" => position.y,
          "tile_npc_id" => npc.id
        }
      end

      def schedule_matches?(schedule, fingerprint)
        schedule.is_a?(Hash) && fingerprint.all? { |key, value| schedule[key].to_i == value.to_i }
      end

      def parsed_due_at(schedule)
        value = schedule.is_a?(Hash) ? schedule["due_at"] : nil
        Time.iso8601(value.to_s) if value.present?
      rescue ArgumentError, TypeError
        nil
      end

      def persist_schedule!(schedule)
        character.update!(
          metadata: character.metadata.to_h.merge(SCHEDULE_METADATA_KEY => schedule)
        )
      end

      def clear_schedule!
        character.with_lock do
          character.reload
          remove_schedule_from_locked_character!
        end
      end

      def remove_schedule_from_locked_character!
        metadata = character.metadata.to_h
        return unless metadata.key?(SCHEDULE_METADATA_KEY)

        character.update!(metadata: metadata.except(SCHEDULE_METADATA_KEY))
      end

      def active_match
        character.arena_participations
          .joins(:arena_match)
          .merge(ArenaMatch.active)
          .order("arena_participations.created_at DESC")
          .first
          &.arena_match
      end

      def waiting_result(seconds)
        Result.new(
          interrupted: false,
          retry_after_ms: [seconds.to_i, 1].max * 1_000
        )
      end
    end
  end
end
