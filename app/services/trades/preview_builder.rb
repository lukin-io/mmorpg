# frozen_string_literal: true

module Trades
  # PreviewBuilder summarizes both sides of a trade to power the anti-scam UI.
  class PreviewBuilder
    Preview = Struct.new(
      :initiator_totals,
      :recipient_totals,
      :net_gold,
      :net_premium_tokens,
      :warning?
    )

    WARNING_THRESHOLD = 10_000

    def initialize(trade_session:)
      @trade_session = trade_session
    end

    def call
      initiator_totals = totals_for(trade_session.initiator)
      recipient_totals = totals_for(trade_session.recipient)

      net_gold = recipient_totals[:gold] - initiator_totals[:gold]
      net_tokens = recipient_totals[:premium_tokens] - initiator_totals[:premium_tokens]
      warning = net_gold.abs >= WARNING_THRESHOLD || net_tokens.positive?

      Preview.new(
        initiator_totals,
        recipient_totals,
        net_gold,
        net_tokens,
        warning
      )
    end

    private

    attr_reader :trade_session

    def totals_for(user)
      items = trade_session.trade_items.where(owner: user)
      {
        gold: currency_total(items, "gold"),
        silver: currency_total(items, "silver"),
        premium_tokens: currency_total(items, "premium_tokens"),
        items: items.reject(&:currency?)
      }
    end

    def currency_total(items, currency_type)
      items.select { |item| item.currency_type == currency_type }.sum { |i| i.currency_amount.to_i }
    end
  end
end
