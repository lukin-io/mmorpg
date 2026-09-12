# frozen_string_literal: true

module Arena
  # Awards configured solo PvE XP with the recipient's level/entitlement cap.
  # encounter_experience_reward is victory-only. A loss to an NPC side may use
  # the separate integer encounter_defeat_experience_reward only after the
  # player defeated an enemy NPC. Unconfigured rewards use the documented v1 calibrated model.
  # Benefits multiply the maximum, never the earned XP. The caller owns the
  # match lock and rewards_processed_at guard; call persists XP/level grants
  # and returns their actual character recipient, amount, and levels gained.
  class NpcExperienceAwarder
    Result = Data.define(:character_id, :experience_awarded, :levels_gained, :skipped_reason)

    def initialize(match:, winning_team:)
      @match = match
      @winning_team = winning_team
    end

    # Compatibility entry point for single-recipient callers.
    def call
      call_all.first || skipped("no_recipient")
    end

    # The match finalizer calls once under its reward guard. Returns one result
    # per player, including defeated allies who contributed before defeat.
    def call_all
      return [skipped("draw")] if winning_team.blank?
      return [skipped("invalid_winner")] unless match.arena_participations.exists?(team: winning_team)

      players = match.arena_participations.players.includes(:character).order(:character_id).to_a
      players.group_by(&:team).flat_map do |team, members|
        npcs = defeated_enemy_npcs(team)
        next members.map { skipped("no_defeated_enemy_npc") } if npcs.empty?

        total_damage = members.sum { |member| member.metadata.to_h["damage_dealt"].to_i }
        members.map do |player|
          recipient = player.character
          amount = configured_or_calculated_experience(player, npcs, solo: players.one?)
          unless members.one?
            contribution = total_damage.positive? ? player.metadata.to_h["damage_dealt"].to_f / total_damage : 1.0 / members.size
            shared = parameters.fetch("participation_share")
            amount = (amount * (shared / members.size + (1 - shared) * contribution)).floor
          end
          award(recipient, amount)
        end
      end
    end

    private

    attr_reader :match, :winning_team

    def defeated_enemy_npcs(player_team)
      match.arena_participations.npcs.where.not(team: player_team).includes(:npc_template).select(&:defeat?)
    end

    def parameters
      Game::Combat::Calibration.config.fetch("experience")
    end

    def configured_or_calculated_experience(player, npcs, solo:)
      victory = player.team == winning_team
      key = victory ? "encounter_experience_reward" : "encounter_defeat_experience_reward"
      configured = match.metadata.to_h[key]
      return configured.is_a?(Integer) && configured >= 0 ? configured : 0 if solo && match.metadata.to_h.key?(key)

      base = npcs.sum do |npc|
        if npcs.one? && npc.npc_template.xp_reward.positive?
          npc.npc_template.xp_reward
        else
          difference = [player.participant_level - npc.participant_level - 2, 0].max
          npc.max_hp * parameters.fetch("hp_rate") * 0.75**difference
        end
      end
      group_bonus = 1 + [npcs.size - 1, 0].max * parameters.fetch("group_bonus_per_extra_npc")
      (base * group_bonus * (victory ? 1 : parameters.fetch("loss_multiplier"))).round
    end

    def award(recipient, amount)
      return skipped("no_configured_experience") unless amount.positive?

      base_cap = Game::Progression::Catalog.fight_experience_cap(recipient.level)
      awarded = [amount, recipient.combat_benefits.maximum_experience(base_cap:)].min
      return skipped("unsupported_level") unless awarded.positive?

      progression = Players::Progression::LevelUpService.new(character: recipient).apply_experience!(awarded)
      Result.new(character_id: recipient.id, experience_awarded: awarded,
        levels_gained: progression.levels_gained, skipped_reason: nil)
    end

    def skipped(reason)
      Result.new(character_id: nil, experience_awarded: 0, levels_gained: 0, skipped_reason: reason)
    end
  end
end
