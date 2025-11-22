# frozen_string_literal: true

module Game
  module Combat
    # PostBattleProcessor applies arena rankings, trauma recovery, and respawn scheduling.
    #
    # Usage:
    #   Game::Combat::PostBattleProcessor.new(battle:).call(winner: character)
    #
    # Returns:
    #   Hash summarizing processing actions.
    class PostBattleProcessor
      def initialize(battle:, arena_ladder: Game::Combat::ArenaLadder.new(battle:))
        @battle = battle
        @arena_ladder = arena_ladder
      end

      def call(winner: nil)
        updates = {}
        updates[:arena] = arena_ladder.apply!(winner:) if winner && battle.battle_type == "arena"
        apply_doctor_support!
        schedule_respawns!
        battle.update!(status: :completed, ended_at: Time.current) if battle.status != "completed"
        updates
      end

      private

      attr_reader :battle, :arena_ladder

      def apply_doctor_support!
        doctor_progresses.each do |progress|
          battle.battle_participants.each do |participant|
            position = participant.character&.position
            next unless position

            Professions::Doctor::TraumaResponse.new(doctor_progress: progress).apply!(character_position: position)
          end
        end
      end

      def doctor_progresses
        battle.battle_participants.filter_map do |participant|
          character = participant.character
          next unless character

          character.user.profession_progresses.includes(:profession).select do |progress|
            progress.profession.name.casecmp("Doctor").zero?
          end
        end.flatten
      end

      def schedule_respawns!
        battle.battle_participants.each do |participant|
          next unless participant.character
          next unless participant.hp_remaining <= 0

          schedule_respawn_for(participant.character)
        end
      end

      def schedule_respawn_for(character)
        position = character.position || Game::Movement::RespawnService.new(character:).ensure_position!
        position.update!(
          state: :downed,
          respawn_available_at: Time.current + respawn_seconds_for(character)
        )
      end

      def respawn_seconds_for(character)
        spawn_scope = SpawnPoint.where(zone: character.position&.zone)
        spawn = spawn_scope.matching_faction(character.faction_alignment).first || spawn_scope.first
        spawn&.respawn_seconds || 60
      end
    end
  end
end

