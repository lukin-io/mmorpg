# frozen_string_literal: true

module Arena
  # Awards shared player/NPC encounter XP with the recipient's level/entitlement cap.
  # encounter_experience_reward is victory-only. A loss to an NPC side may use
  # the separate integer encounter_defeat_experience_reward only after the
  # player defeated an enemy NPC. Unconfigured rewards use the documented v1 calibrated model.
  # Benefits multiply the maximum, never the earned XP. The caller owns the
  # match lock and rewards_processed_at guard; call persists XP/level grants
  # and returns their actual character recipient, amount, and levels gained.
  class ExperienceAwarder
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

      # Snapshot opponents before any recipient levels up during settlement.
      @combatants = match.arena_participations.includes(:character, :npc_template).to_a
      @reward_inputs = @combatants.index_with { |entry| [entry.participant_level, entry.max_hp] }
      players = @combatants.select(&:player?).sort_by(&:character_id)
      players.group_by(&:team).flat_map do |team, members|
        enemies = reward_enemies(team)
        next members.map { skipped("no_defeated_enemy") } if enemies.empty?

        total_damage = members.sum { |member| member.metadata.to_h["damage_dealt"].to_i }
        members.map do |player|
          recipient = player.character
          amount = configured_or_calculated_experience(player, enemies, solo: players.one?)
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

    def reward_enemies(player_team)
      @combatants.reject { |entry| entry.team == player_team }.select do |entry|
        entry.defeat? || (entry.player? && entry.metadata.to_h["damage_taken"].to_i.positive?)
      end
    end

    def parameters
      Game::Combat::Calibration.config.fetch("experience")
    end

    def configured_or_calculated_experience(player, enemies, solo:)
      victory = player.team == winning_team
      key = victory ? "encounter_experience_reward" : "encounter_defeat_experience_reward"
      configured = match.metadata.to_h[key]
      return configured.is_a?(Integer) && configured >= 0 ? configured : 0 if solo && match.metadata.to_h.key?(key)

      base = enemies.sum do |enemy|
        if enemies.one? && enemy.npc? && enemy.npc_template.xp_reward.positive?
          enemy.npc_template.xp_reward
        else
          level, health = @reward_inputs.fetch(enemy)
          difference = [@reward_inputs.fetch(player).first - level - 2, 0].max
          health = [health, enemy.metadata.to_h["damage_taken"].to_i].min if enemy.player?
          health * parameters.fetch("hp_rate") * 0.75**difference
        end
      end
      group_bonus = 1 + [enemies.size - 1, 0].max * parameters.fetch("group_bonus_per_extra_npc")
      risk = if enemies.any?(&:player?)
        parameters.fetch("pvp_trauma_multiplier").fetch(match.trauma_percent.to_s, 1.0)
      else
        1.0
      end
      loss_multiplier = enemies.any?(&:player?) ? parameters.fetch("pvp_loss_multiplier") : parameters.fetch("loss_multiplier")
      (base * group_bonus * risk * (victory ? 1 : loss_multiplier)).round
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
