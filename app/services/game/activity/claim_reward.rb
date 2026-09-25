# frozen_string_literal: true

module Game
  module Activity
    # Claims NV/XP rewards from completed daily contracts or achievements.
    class ClaimReward
      Result = Struct.new(:success?, :message, keyword_init: true)

      def initialize(character:, kind:, id:)
        @character = character
        @kind = kind.to_s
        @id = id.to_i
      end

      def call
        ApplicationRecord.transaction do
          case kind
          when "contract"
            claim_contract!
          when "achievement"
            claim_achievement!
          else
            Result.new(success?: false, message: I18n.t("game.activity.unknown_kind"))
          end
        end
      end

      private

      attr_reader :character, :kind, :id

      def claim_contract!
        row = DailyActivityContract.lock.find_by!(id:, character:)
        return Result.new(success?: false, message: I18n.t("game.activity.not_ready")) if row.completed_at.blank?
        return Result.new(success?: false, message: I18n.t("game.activity.already_claimed")) if row.claimed_at.present?

        reward = row.reward.to_h.deep_dup
        streak = bump_claim_streak!
        bonus_nv = [streak - 1, 0].max * 5
        milestone = streak_milestone_for(streak)
        bonus_nv += milestone["nv"].to_i if milestone
        reward["nv"] = reward["nv"].to_i + bonus_nv if bonus_nv.positive?
        grant!(reward)
        meta = row.metadata.to_h.merge("claim_streak" => streak, "streak_bonus_nv" => bonus_nv)
        meta["streak_milestone_days"] = milestone["days"] if milestone
        row.update!(claimed_at: Time.current, metadata: meta)
        season_xp = Game::Seasons::Catalog.active? ? Game::Seasons::Catalog.current.fetch("xp_per_daily_claim", 25).to_i : 0
        season_xp += milestone["season_xp"].to_i if milestone
        Game::Seasons::Progress.new(character:).add_xp!(season_xp) if season_xp.positive?
        message = if milestone
          I18n.t("game.activity.claimed_milestone", streak:, bonus: bonus_nv, days: milestone["days"])
        elsif bonus_nv.positive?
          I18n.t("game.activity.claimed_streak", streak:, bonus: bonus_nv)
        else
          I18n.t("game.activity.claimed")
        end
        Result.new(success?: true, message:)
      end

      def streak_milestone_for(streak)
        return nil unless Game::Seasons::Catalog.active?

        Array(Game::Seasons::Catalog.current["streak_milestones"]).map(&:deep_stringify_keys)
          .find { |row| row["days"].to_i == streak.to_i }
      end

      def bump_claim_streak!
        meta = character.metadata.to_h.deep_dup
        activity = meta["activity_streak"].to_h
        today = Time.current.utc.to_date
        last = begin
          Date.iso8601(activity["last_claim_day"].to_s)
        rescue ArgumentError, TypeError
          nil
        end
        streak = activity["count"].to_i
        streak = if last == today
          [streak, 1].max
        elsif last == today - 1
          streak + 1
        else
          1
        end
        activity["count"] = streak
        activity["last_claim_day"] = today.iso8601
        meta["activity_streak"] = activity
        character.update!(metadata: meta)
        streak
      end
      def claim_achievement!
        row = ActivityAchievement.lock.find_by!(id:, character:)
        return Result.new(success?: false, message: I18n.t("game.activity.not_ready")) if row.completed_at.blank?
        return Result.new(success?: false, message: I18n.t("game.activity.already_claimed")) if row.claimed_at.present?

        grant!(row.metadata.to_h.fetch("rewards", {}))
        row.update!(claimed_at: Time.current)
        Result.new(success?: true, message: I18n.t("game.activity.claimed"))
      end

      def grant!(reward)
        nv = reward["nv"].to_i
        xp = reward["xp"].to_i
        if nv.positive?
          wallet = character.user.currency_wallet || character.user.create_currency_wallet!(nv_balance: 0)
          wallet.adjust!(amount: nv, reason: "activity.claim", metadata: {"kind" => kind, "id" => id})
        end
        if xp.positive?
          character.with_lock do
            character.reload
            character.update!(experience: character.experience.to_i + xp)
          end
        end
      end
    end
  end
end
