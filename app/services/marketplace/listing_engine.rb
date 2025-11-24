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
    def initialize(user:, params:, tax_calculator: Economy::TaxCalculator.new, wallet_service: Economy::WalletService)
      @user = user
      @params = params
      @tax_calculator = tax_calculator
      @wallet_service = wallet_service
    end

    def create!
      guardrail_override = inflation_override?
      Economy::ListingCapEnforcer.new(user:, scope: AuctionListing.live).enforce!(override: guardrail_override)

      tax_rate = tax_calculator.call(
        location: params[:location_key],
        clan: owning_clan,
        listing_value: listing_value
      )
      apply_listing_fee!(tax_rate:)

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
      log_override!(listing) if guardrail_override
      listing
    end

    private

    attr_reader :user, :params, :tax_calculator, :wallet_service

    def owning_clan
      ClanTerritory.find_by(territory_key: params[:location_key])&.clan
    end

    def listing_value
      params[:starting_bid].to_i * (params[:quantity].presence || 1).to_i
    end

    def apply_listing_fee!(tax_rate:)
      fee = Economy::ListingFeeCalculator.new(
        listing_value: listing_value,
        location_modifier: tax_rate
      ).call
      wallet_service.new(wallet: user.currency_wallet).sink!(
        currency: :gold,
        amount: fee,
        sink_reason: :listing_fee,
        metadata: {
          location_key: params[:location_key],
          listing_value: listing_value
        }
      )
    end

    def inflation_override?
      return false unless params[:override_inflation_controls].presence

      user.has_any_role?(:gm, :admin)
    end

    def log_override!(listing)
      AuditLogger.log(
        actor: user,
        action: "economy.override",
        target: listing,
        metadata: {
          location_key: listing.location_key,
          listing_id: listing.id
        }
      )
    end
  end
end
