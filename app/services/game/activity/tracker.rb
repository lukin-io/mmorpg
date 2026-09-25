# frozen_string_literal: true

module Game
  module Activity
    # Records combat/shop/instance events into achievements + daily contracts.
    class Tracker
      def initialize(character:)
        @character = character
      end

      def record!(kind:, amount: 1, meta: {})
        ensure_daily_contracts!
        ensure_achievement_rows!
        bump_contracts!(kind, amount)
        bump_achievement_chains!(kind, amount, meta)
      end

      def ensure_daily_contracts!
        day = Time.current.utc.strftime("%Y-%m-%d")

        DailyContracts.definitions_for(day).each do |row|
          DailyActivityContract.find_or_create_by!(character:, day_key: day, contract_key: row.fetch(:key)) do |c|
            c.kind = row.fetch(:kind)
            c.target = row.fetch(:target)
            c.reward = row.fetch(:reward)
            c.metadata = row.fetch(:metadata, {})
          end
        end
      end

      # Materialize catalog rows so the board shows locked next tiers.
      def ensure_achievement_rows!
        AchievementCatalog.all.each do |chain|
          key = "#{chain[:id]}:#{chain[:step]}"
          row = ActivityAchievement.find_or_initialize_by(character:, achievement_key: key)
          next if row.persisted?

          row.required = chain[:required]
          row.progress = 0
          row.metadata = chain.slice(:name_ru, :name_en, :rewards, :tier, :id, :step, :kind)
          row.save!
        end
      end

      private

      attr_reader :character

      def bump_contracts!(kind, amount)
        day = Time.current.utc.strftime("%Y-%m-%d")
        DailyActivityContract.where(character:, day_key: day, kind: kind, completed_at: nil).find_each do |row|
          row.update!(progress: [row.progress + amount, row.target].min)
          row.update!(completed_at: Time.current) if row.progress >= row.target
        end
      end

      def bump_achievement_chains!(kind, amount, meta)
        AchievementCatalog.chains_for(kind).each do |chain|
          key = "#{chain[:id]}:#{chain[:step]}"
          row = ActivityAchievement.find_or_initialize_by(character:, achievement_key: key)
          row.required = chain[:required]
          row.metadata = chain.slice(:name_ru, :name_en, :rewards, :tier, :id, :step, :kind).merge(meta)
          # Cumulative counters: only advance while under required (tiers share kind totals).
          row.progress = [row.progress.to_i + amount, row.required].min
          row.completed_at ||= Time.current if row.progress >= row.required
          row.save!
        end
      end
    end
  end
end
