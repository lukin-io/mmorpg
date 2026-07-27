# frozen_string_literal: true

module Arena
  # Awards configured NPC experience for a solo PvE victory, capped by the
  # Neverlands per-fight limit for the winner's level. Group distribution is
  # intentionally deferred until its source formula is captured.
  class NpcExperienceAwarder
    Result = Data.define(:character_id, :experience_awarded, :levels_gained, :skipped_reason)

    def initialize(match:, winning_team:)
      @match = match
      @winning_team = winning_team
    end

    def call
      return skipped("draw") if winning_team.blank?

      winners = match.arena_participations.players.where(team: winning_team).includes(:character).to_a
      return skipped("group_formula_not_captured") unless winners.one?

      winner = winners.first.character
      configured_experience = defeated_enemy_npcs.sum { |participation| participation.npc_template.xp_reward }
      return skipped("no_configured_experience") unless configured_experience.positive?

      cap = Game::Progression::Catalog.fight_experience_cap(winner.level)
      awarded = [configured_experience, cap].min
      return skipped("unsupported_level") unless awarded.positive?

      progression = Players::Progression::LevelUpService.new(character: winner).apply_experience!(awarded)
      Result.new(
        character_id: winner.id,
        experience_awarded: awarded,
        levels_gained: progression.levels_gained,
        skipped_reason: nil
      )
    end

    private

    attr_reader :match, :winning_team

    def defeated_enemy_npcs
      match.arena_participations.npcs.where.not(team: winning_team).includes(:npc_template).select(&:defeat?)
    end

    def skipped(reason)
      Result.new(character_id: nil, experience_awarded: 0, levels_gained: 0, skipped_reason: reason)
    end
  end
end
