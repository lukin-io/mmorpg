# frozen_string_literal: true

module Housing
  # Manages creation, upgrades, and access rules for player housing plots.
  #
  # Usage:
  #   Housing::InstanceManager.new(user: user).ensure_default_plot!
  #   Housing::InstanceManager.new(plot: plot, user: user).upgrade_tier!(plot_tier: :estate)
  #   Housing::InstanceManager.new(plot: plot).update_access!(params)
  class InstanceManager
    PLOT_PRICING = {
      "starter" => {currency: :gold, amount: 0},
      "deluxe" => {currency: :gold, amount: 5_000},
      "estate" => {currency: :premium_tokens, amount: 25},
      "citadel" => {currency: :premium_tokens, amount: 60}
    }.freeze

    def initialize(user: nil, plot: nil, wallet_service: Economy::WalletService)
      @user = user || plot&.user
      @plot = plot || user&.housing_plots&.first
      @wallet_service = wallet_service
    end

    def ensure_default_plot!(plot_type: "apartment", location_key: "starter_city", plot_tier: "starter",
      exterior_style: "classic", visit_scope: "friends")
      raise ArgumentError, "User required" unless user

      plot = user.housing_plots.first || user.housing_plots.create!(
        plot_type:,
        location_key:,
        plot_tier:,
        exterior_style:,
        visit_scope:,
        storage_slots: HousingPlot::PLOT_TIERS.fetch(plot_tier).fetch(:storage_slots),
        utility_slots: HousingPlot::PLOT_TIERS.fetch(plot_tier).fetch(:utility_slots),
        access_rules: {"visibility" => visit_scope},
        next_upkeep_due_at: Time.current + Housing::UpkeepService::INTERVAL
      )
      Housing::UpkeepService.new(plot: plot).collect!
      plot
    end

    def upgrade_tier!(plot_tier:, exterior_style: nil)
      ensure_plot_present!
      return plot if plot.plot_tier == plot_tier
      raise Pundit::NotAuthorizedError unless plot.user == user
      ensure_upgrade_direction!(plot_tier)

      charge_for_tier!(plot_tier)

      plot.update!(
        plot_tier:,
        exterior_style: exterior_style.presence || plot.exterior_style,
        storage_slots: HousingPlot::PLOT_TIERS.fetch(plot_tier).fetch(:storage_slots),
        utility_slots: HousingPlot::PLOT_TIERS.fetch(plot_tier).fetch(:utility_slots)
      )
      plot
    end

    def update_access!(access_rules:, visit_scope: nil, visit_guild: nil, showcase_enabled: nil)
      ensure_plot_present!
      attrs = {access_rules: access_rules || plot.access_rules}
      attrs[:visit_scope] = visit_scope if visit_scope.present?
      attrs[:visit_guild] = visit_guild if visit_scope == "guild"
      attrs[:showcase_enabled] = showcase_enabled unless showcase_enabled.nil?
      plot.update!(attrs.compact)
    end

    private

    attr_reader :user, :plot, :wallet_service

    def ensure_plot_present!
      raise ArgumentError, "Plot required" unless plot
    end

    def ensure_upgrade_direction!(plot_tier)
      current_rank = tier_rank(plot.plot_tier)
      desired_rank = tier_rank(plot_tier)
      raise ArgumentError, "Unknown plot tier #{plot_tier}" if desired_rank.negative?
      raise ArgumentError, "Cannot downgrade housing" if desired_rank <= current_rank
    end

    def tier_rank(value)
      HousingPlot::PLOT_TIERS.keys.index(value.to_s) || -1
    end

    def charge_for_tier!(plot_tier)
      pricing = PLOT_PRICING.fetch(plot_tier) { raise ArgumentError, "No pricing for tier #{plot_tier}" }
      return if pricing[:amount].zero?

      wallet = user.currency_wallet || user.create_currency_wallet!
      wallet_service.new(wallet: wallet).sink!(
        currency: pricing[:currency],
        amount: pricing[:amount],
        sink_reason: :housing_upgrade,
        metadata: {plot_id: plot.id, new_tier: plot_tier}
      )
    end
  end
end
