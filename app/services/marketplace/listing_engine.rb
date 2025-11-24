# frozen_string_literal: true

module Marketplace
  # Builds and posts auction listings, calculating taxes and broadcasting updates.
  #
  # Usage:
  #   Marketplace::ListingEngine.new(user: current_user, params: listing_params).create!
  #
  # Returns:
  #   AuctionListing record.
  class ListingEngine
    def initialize(user:, params:, tax_calculator: Economy::TaxCalculator.new)
      @user = user
      @params = params
      @tax_calculator = tax_calculator
    end

    def create!
      tax_rate = tax_calculator.call(location: params[:location_key], clan: owning_clan, listing_value: params[:starting_bid].to_i)

      listing = AuctionListing.new(
        seller: user,
        item_name: params[:item_name],
        item_metadata: params[:item_metadata] || {},
        quantity: params[:quantity] || 1,
        currency_type: params[:currency_type] || "gold",
        starting_bid: params[:starting_bid],
        buyout_price: params[:buyout_price],
        status: :active,
        ends_at: params[:ends_at],
        location_key: params[:location_key].presence || "capital",
        tax_rate: tax_rate,
        required_profession_id: params[:required_profession_id],
        required_skill_level: params[:required_skill_level].to_i,
        commission_scope: params[:commission_scope] || "personal"
      )
      listing.save!
      listing
    end

    private

    attr_reader :user, :params, :tax_calculator

    def owning_clan
      ClanTerritory.find_by(territory_key: params[:location_key])&.clan
    end
  end
end
