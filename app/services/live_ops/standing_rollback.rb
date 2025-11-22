# frozen_string_literal: true

module LiveOps
  # StandingRollback reverts arena or clan war outcomes if cheating is confirmed.
  # Usage:
  #   LiveOps::StandingRollback.new.call(target_type: "arena_tournament", target_id: 1)
  class StandingRollback
    def initialize(instrumentation: Moderation::Instrumentation)
      @instrumentation = instrumentation
    end

    def call(target_type:, target_id:)
      case target_type
      when "arena_tournament"
        rollback_arena(target_id)
      when "clan_war"
        rollback_clan_war(target_id)
      else
        raise ArgumentError, "Unsupported rollback target #{target_type}"
      end
    end

    private

    attr_reader :instrumentation

    def rollback_arena(target_id)
      tournament = ArenaTournament.find(target_id)
      ArenaRanking.where(arena_tournament: tournament).update_all(points: 0)
      tournament.update!(status: :cancelled)
      instrumentation.track("live_ops.rollback.arena", target_id:)
    end

    def rollback_clan_war(target_id)
      clan_war = ClanWar.find(target_id)
      clan_war.update!(status: :cancelled)
      instrumentation.track("live_ops.rollback.clan_war", target_id:)
    end
  end
end
