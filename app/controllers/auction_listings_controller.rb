# frozen_string_literal: true

class AuctionListingsController < ApplicationController
  def index
    scope = policy_scope(AuctionListing).live.order(ends_at: :asc)
    @filter_params = filter_params
    @listing_filter = Marketplace::ListingFilter.new(scope:, params: @filter_params)
    @auction_listings = @listing_filter.call
  end

  def new
    @auction_listing = authorize AuctionListing.new
    @professions = Profession.order(:name)
  end

  def create
    authorize AuctionListing
    listing = Marketplace::ListingEngine.new(user: current_user, params: listing_params).create!
    redirect_to auction_listing_path(listing), notice: "Listing created."
  rescue ActiveRecord::RecordInvalid => e
    @auction_listing = AuctionListing.new(listing_params)
    @professions = Profession.order(:name)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def show
    @auction_listing = authorize AuctionListing.find(params[:id])
    @auction_bid = AuctionBid.new
  end

  private

  def listing_params
    params.require(:auction_listing).permit(
      :item_name,
      :quantity,
      :currency_type,
      :starting_bid,
      :buyout_price,
      :ends_at,
      :location_key,
      :required_profession_id,
      :required_skill_level,
      :commission_scope,
      :override_inflation_controls,
      item_metadata: {}
    )
  end

  def filter_params
    params.fetch(:filter, {}).permit(:item_type, :rarity, :currency_type, :stat_key, :stat_min)
  end
end
