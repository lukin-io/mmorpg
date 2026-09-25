# frozen_string_literal: true

module Arena
  # Awards NPC experience for PvE victories. Soft-release Ashen formula:
  #   Base_Monster_XP = (monster_level * 15) * max(1.0 - |Δlevel| * 0.1, 0.1)
  # Multi-bot pools sum per-NPC formula values; party shares split by damage
  # dealt (equal fallback). Per-character fight XP caps still apply.
  class NpcExperienceAwarder
    Result = Data.define(:character_id, :experience_awarded, :levels_gained, :skipped_reason, :party_awards)

    def initialize(match:, winning_team:)
      @match = match
      @winning_team = winning_team
    end

    def call
      return skipped("draw") if winning_team.blank?

      winners = match.arena_participations.players.where(team: winning_team).includes(:character).to_a
      return skipped("no_winners") if winners.empty?

      defeated = defeated_enemy_npcs
      return skipped("no_configured_experience") if defeated.empty? && explicit_encounter_experience.blank?

      party_awards = []
      primary = nil

      winners.each do |participation|
        character = participation.character
        pool = experience_pool_for(character)
        next unless pool.positive?

        shares = damage_shares(winners)
        raw = (pool * shares.fetch(participation.id)).round
        cap = Game::Progression::Catalog.fight_experience_cap(character.level)
        awarded = [raw, cap].min
        next unless awarded.positive?

        progression = Players::Progression::LevelUpService.new(character:).apply_experience!(awarded)
        entry = {
          character_id: character.id,
          experience_awarded: awarded,
          levels_gained: progression.levels_gained
        }
        party_awards << entry
        primary ||= entry
      end

      return skipped("unsupported_level") if party_awards.empty?

      Result.new(
        character_id: primary.fetch(:character_id),
        experience_awarded: primary.fetch(:experience_awarded),
        levels_gained: primary.fetch(:levels_gained),
        skipped_reason: nil,
        party_awards:
      )
    end

    private

    attr_reader :match, :winning_team

    def experience_pool_for(character)
      explicit = explicit_encounter_experience
      return explicit if explicit

      defeated_enemy_npcs.sum do |participation|
        Game::Progression::Curves.monster_xp(
          monster_level: monster_level_of(participation),
          player_level: character.level
        )
      end
    end

    def monster_level_of(participation)
      template = participation.npc_template
      level = template&.level.to_i
      level = participation.metadata.to_h["level"].to_i if level < 1
      level = template&.metadata.to_h["level"].to_i if level < 1
      [level, 1].max
    end

    def damage_shares(winners)
      damages = winners.to_h do |participation|
        dealt = participation.metadata.to_h["damage_dealt"].to_i
        [participation.id, [dealt, 0].max]
      end
      total = damages.values.sum
      if total <= 0
        equal = 1.0 / winners.size
        return winners.to_h { |p| [p.id, equal] }
      end

      damages.transform_values { |d| d.to_f / total }
    end

    def defeated_enemy_npcs
      match.arena_participations.npcs.where.not(team: winning_team).includes(:npc_template).select(&:defeat?)
    end

    def explicit_encounter_experience
      Integer(match.metadata.to_h["encounter_experience_reward"], exception: false)
    end

    def skipped(reason)
      Result.new(character_id: nil, experience_awarded: 0, levels_gained: 0, skipped_reason: reason, party_awards: [])
    end
  end
end
