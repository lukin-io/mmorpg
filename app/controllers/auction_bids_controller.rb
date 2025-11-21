# frozen_string_literal: true

class AuctionBidsController < ApplicationController
  def create
    listing = AuctionListing.find(params[:auction_listing_id])
    authorize listing, :bid?

    bid = listing.auction_bids.create!(bidder: current_user, amount: bid_params[:amount])
    redirect_to listing, notice: "Bid placed for #{bid.amount}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to listing, alert: e.message
  end

  private

  def bid_params
    params.require(:auction_bid).permit(:amount)
  end
end
