# frozen_string_literal: true

module Marketplace
  # ListingFilter applies advanced item metadata filters (type, rarity, stat thresholds).
  #
  # Usage:
  #   filter = Marketplace::ListingFilter.new(scope: AuctionListing.live, params: params)
  #   @auction_listings = filter.call
  #   @active_filters = filter.filters
  class ListingFilter
    attr_reader :filters

    def initialize(scope:, params:)
      @scope = scope
      @params = params || {}
      @filters = {}
    end

    def call
      filtered = scope
      filtered = apply_item_type_filter(filtered)
      filtered = apply_rarity_filter(filtered)
      filtered = apply_currency_filter(filtered)
      filtered = apply_stat_filter(filtered)
      filtered
    end

    private

    attr_reader :scope, :params

    def apply_item_type_filter(relation)
      item_type = params[:item_type].presence
      return relation unless item_type

      filters[:item_type] = item_type
      relation.with_item_type(item_type)
    end

    def apply_rarity_filter(relation)
      rarity = params[:rarity].presence
      return relation unless rarity

      filters[:rarity] = rarity
      relation.with_rarity(rarity)
    end

    def apply_currency_filter(relation)
      currency = params[:currency_type].presence
      return relation unless currency

      filters[:currency_type] = currency
      relation.where(currency_type: currency)
    end

    def apply_stat_filter(relation)
      stat_key = params[:stat_key].presence
      stat_min = params[:stat_min].presence&.to_i
      return relation unless stat_key && stat_min&.positive?

      filters[:stat_key] = stat_key
      filters[:stat_min] = stat_min
      relation.with_stat_at_least(stat_key, stat_min)
    end
  end
end
