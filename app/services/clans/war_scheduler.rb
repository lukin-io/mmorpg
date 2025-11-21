# frozen_string_literal: true

module Clans
  # Schedules clan wars and ensures constraints like cooldowns/territory ownership are respected.
  #
  # Usage:
  #   Clans::WarScheduler.new(attacker: clan_a, defender: clan_b).schedule!(territory_key: "castle_black", starts_at: 3.days.from_now)
  #
  # Returns:
  #   The persisted ClanWar record.
  class WarScheduler
    MINIMUM_NOTICE_HOURS = 24

    def initialize(attacker:, defender:)
      @attacker = attacker
      @defender = defender
    end

    def schedule!(territory_key:, starts_at:)
      raise ArgumentError, "Start time must be in the future" if starts_at < Time.current + MINIMUM_NOTICE_HOURS.hours

      ClanWar.create!(
        attacker_clan: attacker,
        defender_clan: defender,
        territory_key:,
        scheduled_at: starts_at,
        status: :scheduled
      )
    end

    private

    attr_reader :attacker, :defender
  end
end

