# frozen_string_literal: true

class AuctionListingsController < ApplicationController
  def index
    @auction_listings = policy_scope(AuctionListing).live.order(ends_at: :asc)
  end

  def new
    @auction_listing = authorize AuctionListing.new
  end

  def create
    authorize AuctionListing
    listing = Marketplace::ListingEngine.new(user: current_user, params: listing_params).create!
    redirect_to auction_listing_path(listing), notice: "Listing created."
  rescue ActiveRecord::RecordInvalid => e
    @auction_listing = AuctionListing.new(listing_params)
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
      item_metadata: {}
    )
  end
end

