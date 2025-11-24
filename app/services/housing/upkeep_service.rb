# frozen_string_literal: true

module Housing
  # UpkeepService withdraws recurring housing fees to keep plots active.
  class UpkeepService
    INTERVAL = 7.days

    def initialize(plot:, wallet_service: Economy::WalletService)
      @plot = plot
      @wallet_service = wallet_service
    end

    def collect!
      return unless plot.upkeep_due?

      wallet_service.new(wallet: plot.user.currency_wallet).sink!(
        currency: :gold,
        amount: plot.upkeep_gold_cost,
        sink_reason: :housing_upkeep,
        metadata: {plot_id: plot.id}
      )
      plot.update!(next_upkeep_due_at: Time.current + INTERVAL)
    rescue Economy::WalletService::InsufficientFundsError
      lock_plot!
    end

    private

    attr_reader :plot, :wallet_service

    def lock_plot!
      rules = plot.access_rules || {}
      plot.update!(access_rules: rules.merge("locked" => true))
    end
  end
end
