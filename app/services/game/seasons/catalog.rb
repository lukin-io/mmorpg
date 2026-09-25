# frozen_string_literal: true

module Game
  module Seasons
    # Mist-oriented seasonal FOMO catalog (battle-pass style free/premium tracks).
    class Catalog
      CONFIG = Rails.root.join("config/gameplay/ashen_season.yml")

      def self.config
        @config ||= YAML.safe_load(CONFIG.read, aliases: true).deep_stringify_keys
      end

      def self.current_key
        config.fetch("current").to_s
      end

      def self.current
        seasons = config.fetch("seasons")
        seasons.fetch(current_key)
      end

      def self.active?(at: Time.current)
        season = current
        starts = Date.iso8601(season.fetch("starts_on"))
        ends = Date.iso8601(season.fetch("ends_on"))
        day = at.to_date
        day >= starts && day <= ends
      rescue ArgumentError, KeyError
        false
      end

      def self.demand_multiplier(item_key, at: Time.current)
        return 1.0 unless active?(at:)

        season = current
        keys = Array(season["demand_keys"]).map(&:to_s)
        return 1.0 unless keys.include?(item_key.to_s)

        season.fetch("demand_mult", 1.0).to_f
      end

      def self.days_remaining(at: Time.current)
        return 0 unless active?(at:)

        ends = Date.iso8601(current.fetch("ends_on"))
        (ends - at.to_date).to_i
      end
    end
  end
end
