# frozen_string_literal: true

module Clans
  # XpProgression handles clan XP grants, level-ups, and buff unlock tracking.
  # All XP sources (quests, wars, research) should pass through this service so
  # rewards and audit logs remain consistent.
  #
  # Usage:
  #   Clans::XpProgression.new(clan: clan).grant!(amount: 500, source: "clan_quest")
  #
  # Returns:
  #   Result struct with previous level, new level, and rewards unlocked.
  class XpProgression
    Result = Struct.new(:previous_level, :new_level, :rewards, keyword_init: true)

    def initialize(clan:, config: Rails.configuration.x.clans, logger: Clans::LogWriter)
      @clan = clan
      @config = config
      @logger = logger
    end

    def grant!(amount:, source:, metadata: {})
      result = nil
      clan.with_lock do
        previous_level = clan.level
        updated_xp = clan.experience + amount
        new_level, rewards = compute_levels(previous_level, updated_xp)

        clan.update!(
          experience: updated_xp,
          level: new_level,
          unlocked_buffs: (clan.unlocked_buffs + rewards.fetch("buffs", [])).uniq,
          banner_data: clan.banner_data.merge(
            "unlocked_cosmetics" => Array(clan.banner_data["unlocked_cosmetics"]) | rewards.fetch("cosmetics", [])
          )
        )

        ClanXpEvent.create!(
          clan:,
          source:,
          amount:,
          recorded_at: Time.current,
          metadata:
        )

        logger.new(clan:).record!(
          action: "xp.grant",
          metadata: metadata.merge(amount:, source:, previous_level:, new_level:)
        )

        result = Result.new(previous_level:, new_level:, rewards:)
      end

      result
    end

    def threshold_for(level)
      base = config.dig("xp", "base_threshold").to_i
      scaling = config.dig("xp", "scaling_factor").to_f
      (base * (scaling**(level - 1))).round
    end

    private

    attr_reader :clan, :config, :logger

    def compute_levels(previous_level, updated_xp)
      level = previous_level
      rewards = {"buffs" => [], "cosmetics" => []}

      while updated_xp >= threshold_for(level + 1)
        level += 1
        level_rewards = per_level_rewards(level)
        rewards["buffs"] |= level_rewards.fetch("buffs", [])
        rewards["cosmetics"] |= level_rewards.fetch("cosmetics", [])
      end

      [level, rewards]
    end

    def per_level_rewards(level)
      (config.dig("xp", "per_level_rewards", level.to_s) || {}).stringify_keys
    end
  end
end
