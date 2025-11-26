# frozen_string_literal: true

module Achievements
  # Grants achievements, ensuring idempotency and awarding rewards such as titles or currency.
  #
  # Usage:
  #   Achievements::GrantService.new(user: user, achievement: achievement).call(source: "pve_win")
  class GrantService
    def initialize(user:, achievement:)
      @user = user
      @achievement = achievement
    end

    def call(source:)
      grant = AchievementGrant.find_or_create_by!(user:, achievement:) do |record|
        record.granted_at = Time.current
        record.source = source
      end

      if grant.previously_new_record?
        apply_reward!
        Webhooks::EventDispatcher.new(
          event_type: "achievement.unlocked",
          payload: {user_id: user.id, achievement_key: achievement.key}
        ).call
      end
      grant
    end

    private

    attr_reader :user, :achievement

    def apply_reward!
      wallet = user.currency_wallet || user.create_currency_wallet!

      case achievement.reward_type
      when "title"
        title = achievement.title_reward || Title.find_by(requirement_key: achievement.reward_payload["title_key"])
        return unless title

        Titles::EquipService.new(user:).call(
          title: title,
          source: "achievement:#{achievement.key}"
        )
      when "currency"
        wallet.adjust!(
          currency: :gold,
          amount: achievement.reward_payload["gold"].to_i,
          reason: "achievement.#{achievement.key}"
        )
      when "housing_trophy"
        plot = user.housing_plots.first_or_create!(plot_type: "studio", location_key: "capital")
        plot.housing_decor_items.create!(
          name: achievement.reward_payload["trophy_name"] || achievement.name,
          decor_type: :trophy,
          metadata: achievement.reward_payload
        )
      end
    end
  end
end
