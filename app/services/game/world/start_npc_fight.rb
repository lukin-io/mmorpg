# frozen_string_literal: true

module Game
  module World
    # Starts the shared combat flow for a hostile NPC materialized on the
    # character's current outdoor cell.
    class StartNpcFight
      class FightViolationError < StandardError; end

      def initialize(character:, tile_npc:, return_context: "world")
        @character = character
        @tile_npc = tile_npc
        @return_context = return_context
      end

      def call
        raise FightViolationError, "NPC is unavailable." unless tile_npc

        match = nil
        ActiveRecord::Base.transaction do
          character.with_lock do
            character.reload
            match = active_match

            unless match
              tile_npc.with_lock do
                tile_npc.reload
                validate!
                match = create_match!
                create_participations!(match)
                Arena::CombatProcessor.new(match).start_match
              end
            end
          end
        end

        match
      end

      private

      attr_reader :character, :tile_npc, :return_context

      def validate!
        raise FightViolationError, "NPC is unavailable." unless tile_npc&.alive?
        raise FightViolationError, "This NPC is not hostile." unless tile_npc.hostile?
        raise FightViolationError, "NPC is not on the current cell." unless npc_matches_position?
        unless encounter_size.between?(1, TileNpc::MAX_ENCOUNTER_SIZE)
          raise FightViolationError, "NPC encounter size is not supported."
        end
        return if npc_health

        raise FightViolationError, "NPC combat parameters are not documented."
      end

      def npc_matches_position?
        position = character.position
        position.present? &&
          position.zone.name == tile_npc.zone &&
          position.x == tile_npc.x &&
          position.y == tile_npc.y
      end

      def npc_health
        @npc_health ||= [tile_npc.current_hp.to_i, tile_npc.npc_template.health.to_i].find(&:positive?)
      end

      def active_match
        character.arena_participations
          .joins(:arena_match)
          .merge(ArenaMatch.active)
          .order("arena_participations.created_at DESC")
          .first
          &.arena_match
      end

      def encounter_size
        source_count = OutdoorNpcConfig
          .source_npc_for_tile(tile_npc.zone, tile_npc.x, tile_npc.y)
          &.dig(:metadata, :encounter_count)
        Integer(source_count || tile_npc.encounter_size, exception: false).to_i
      end

      def normalized_return_context
        @normalized_return_context ||= CombatReturnContext.new(character:).normalize(return_context)
      end

      def create_match!
        ArenaMatch.create!(
          zone: character.position.zone,
          match_type: encounter_size > 1 ? :team_battle : :duel,
          status: :pending,
          turn_timeout_seconds: ArenaMatch::DEFAULT_TURN_TIMEOUT,
          trauma_percent: 30,
          metadata: {
            "source" => "world_npc",
            "fight_kind" => "free",
            "is_npc_fight" => true,
            "tile_npc_id" => tile_npc.id,
            "npc_template_id" => tile_npc.npc_template_id,
            "npc_name" => tile_npc.npc_template.name,
            "npc_role" => tile_npc.npc_template.role,
            "encounter_count" => encounter_size,
            "return_context" => normalized_return_context,
            "zone" => tile_npc.zone,
            "x" => tile_npc.x,
            "y" => tile_npc.y
          }
        )
      end

      def create_participations!(match)
        ArenaParticipation.create!(
          arena_match: match,
          character:,
          user: character.user,
          team: "a",
          joined_at: Time.current
        )

        encounter_size.times do |index|
          ArenaParticipation.create!(
            arena_match: match,
            npc_template: tile_npc.npc_template,
            team: "b",
            joined_at: Time.current,
            metadata: {
              "current_hp" => npc_health,
              "max_hp" => npc_health,
              "tile_npc_id" => tile_npc.id,
              "encounter_slot" => index + 1
            }
          )
        end
      end
    end
  end
end
