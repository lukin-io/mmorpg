# frozen_string_literal: true

module Game
  module Combat
    module Analytics
      # ReportBuilder aggregates combat logs into shareable analytics for balancing/esports.
      #
      # Usage:
      #   Game::Combat::Analytics::ReportBuilder.new(battle: battle).call
      #
      # Returns:
      #   Hash payload persisted to CombatAnalyticsReport.
      class ReportBuilder
        def initialize(battle:)
          @battle = battle
        end

        def call
          entries = battle.combat_log_entries
          {
            battle_id: battle.id,
            duration_seconds: battle_duration(entries),
            total_damage: entries.sum(:damage_amount),
            total_healing: entries.sum(:healing_amount),
            ability_usage: ability_usage(entries),
            generated_at: Time.current
          }
        end

        private

        attr_reader :battle

        def battle_duration(entries)
          return 0 if entries.empty?

          (entries.maximum(:created_at) - entries.minimum(:created_at)).to_i
        end

        def ability_usage(entries)
          entries.group(:ability_id).where.not(ability_id: nil).count
        end
      end
    end
  end
end
