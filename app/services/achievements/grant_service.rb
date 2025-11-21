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

      apply_reward! if grant.previously_new_record?
      grant
    end

    private

    attr_reader :user, :achievement

    def apply_reward!
      wallet = user.currency_wallet || user.create_currency_wallet!

      case achievement.reward_type
      when "title"
        # placeholder for Title unlock logic
      when "currency"
        wallet.adjust!(currency: :gold, amount: achievement.reward_payload["gold"].to_i)
      end
    end
  end
end

