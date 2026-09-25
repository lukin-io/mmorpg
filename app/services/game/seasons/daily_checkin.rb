# frozen_string_literal: true

module Game
  module Seasons
    # Once-per-UTC-day soft check-in XP — Mist-like login FOMO without forcing
    # a separate screen; Activity open is enough.
    class DailyCheckin
      Result = Struct.new(:granted, :xp, :message, keyword_init: true)

      def initialize(character:)
        @character = character
      end

      def call
        return Result.new(granted: false, xp: 0) unless Catalog.active?

        xp = Catalog.current.fetch("xp_per_daily_checkin", 15).to_i
        return Result.new(granted: false, xp: 0) unless xp.positive?

        character.with_lock do
          character.reload
          Progress.new(character:).tap { |p| p.send(:ensure_season!) }
          bag = character.metadata.to_h[Progress::META_KEY].to_h
          today = Time.current.utc.to_date.iso8601
          return Result.new(granted: false, xp: 0) if bag["checkin_day"] == today

          Progress.new(character:).add_xp!(xp)
          bag = character.reload.metadata.to_h[Progress::META_KEY].to_h
          bag["checkin_day"] = today
          character.update!(metadata: character.metadata.to_h.merge(Progress::META_KEY => bag))
          Result.new(granted: true, xp:, message: I18n.t("game.season.checkin", amount: xp))
        end
      end

      private

      attr_reader :character
    end
  end
end
