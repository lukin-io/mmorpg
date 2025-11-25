# frozen_string_literal: true

module Clans
  # WarScheduler coordinates declarations, prep windows, and support objectives
  # when clans schedule territory battles.
  #
  # Usage:
  #   Clans::WarScheduler.new(attacker: clan_a, defender: clan_b).schedule!(
  #     territory_key: "castle_black",
  #     starts_at: 3.days.from_now,
  #     support_objectives: ["sabotage_supply_lines"]
  #   )
  class WarScheduler
    MINIMUM_NOTICE_HOURS = 24

    def initialize(attacker:, defender:, logger: Clans::LogWriter.new(clan: attacker), config: Rails.configuration.x.clans)
      @attacker = attacker
      @defender = defender
      @logger = logger
      @config = config
    end

    def schedule!(territory_key:, starts_at:, support_objectives: default_support_objectives, preparation_window_hours: MINIMUM_NOTICE_HOURS)
      validate_start!(starts_at, preparation_window_hours)

      ClanWar.create!(
        attacker_clan: attacker,
        defender_clan: defender,
        territory_key: territory_key,
        scheduled_at: starts_at,
        declaration_made_at: Time.current,
        preparation_begins_at: starts_at - preparation_window_hours.hours,
        support_objectives: Array(support_objectives),
        status: :scheduled
      ).tap do |war|
        logger.record!(
          action: "war.declare",
          actor: attacker.leader,
          metadata: {war_id: war.id, defender_id: defender.id, territory_key: territory_key}
        )
      end
    end

    private

    attr_reader :attacker, :defender, :logger, :config

    def validate_start!(starts_at, preparation_window_hours)
      raise ArgumentError, "Start time must be in the future" if starts_at < Time.current + MINIMUM_NOTICE_HOURS.hours
      raise ArgumentError, "Preparation window must be positive" unless preparation_window_hours.positive?
    end

    def default_support_objectives
      Array(config.dig("warfare", "support_objectives"))
    end
  end
end
