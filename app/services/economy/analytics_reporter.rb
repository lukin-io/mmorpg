# frozen_string_literal: true

module Economy
  # AnalyticsReporter aggregates trading metrics for Live Ops dashboards.
  class AnalyticsReporter
    attr_reader :now

    def initialize(now: Time.current)
      @now = now
    end

    def call
      snapshot = EconomicSnapshot.create!(
        captured_on: now.to_date,
        active_listings: AuctionListing.live.count,
        daily_trade_volume_gold: daily_trade_volume("gold"),
        daily_trade_volume_premium_tokens: daily_trade_volume("premium_tokens"),
        currency_velocity_gold: currency_velocity("gold"),
        currency_velocity_silver: currency_velocity("silver"),
        currency_velocity_premium_tokens: currency_velocity("premium_tokens"),
        suspicious_trade_count: EconomyAlert.where(flagged_at: window..now).count,
        item_price_index: price_index_payload
      )
      create_price_points!
      snapshot
    end

    private

    def window
      24.hours.ago
    end

    def daily_trade_volume(currency)
      TradeItem
        .joins(:trade_session)
        .where(currency_type: currency)
        .where(trade_sessions: {completed_at: window..now})
        .sum(:currency_amount)
    end

    def currency_velocity(currency)
      total_supply = CurrencyWallet.sum(currency_column_for(currency))
      return 0 if total_supply.zero?

      total_movement = CurrencyTransaction
        .for_currency(currency)
        .where(created_at: window..now)
        .sum("ABS(amount)")
      ((total_movement.to_f / total_supply) * 100).round(2)
    end

    def price_index_payload
      AuctionListing
        .where(created_at: window..now)
        .group(:item_name)
        .pluck(:item_name, Arel.sql("AVG(starting_bid)::integer"), Arel.sql("COUNT(*)"))
        .each_with_object({}) do |(name, avg_price, volume), memo|
          memo[name] = {avg_price: avg_price, volume: volume}
        end
    end

    def create_price_points!
      AuctionListing
        .where(created_at: window..now)
        .group(:item_name, :currency_type)
        .pluck(:item_name, :currency_type, Arel.sql("AVG(starting_bid)::integer"), Arel.sql("COUNT(*)"))
        .each do |item_name, currency_type, avg_price, volume|
          ItemPricePoint.create!(
            sampled_on: now.to_date,
            item_name: item_name,
            currency_type: currency_type,
            average_price: avg_price,
            median_price: avg_price, # approximation until per-item medians stored
            volume: volume
          )
        end
    end

    def currency_column_for(currency)
      case currency.to_s
      when "gold"
        :gold_balance
      when "silver"
        :silver_balance
      when "premium_tokens"
        :premium_tokens_balance
      else
        raise ArgumentError, "Unknown currency #{currency}"
      end
    end
  end
end
