# frozen_string_literal: true

# Controller for pop-up marketplace kiosks.
#
# Kiosks are quick-access points for buying/selling in the world.
# Provides a simplified auction house interface.
#
class MarketplaceKiosksController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_kiosk, only: [:show, :quick_buy]

  # GET /marketplace_kiosks/:id
  def show
    @featured_listings = AuctionListing.live
      .where(location_key: @kiosk[:zone])
      .order(:ends_at)
      .limit(10)

    @quick_buy_items = Marketplace::QuickBuyItems.for_zone(@kiosk[:zone])
    @sell_prices = Marketplace::SellPriceCalculator.for_inventory(current_character.inventory)
  end

  # POST /marketplace_kiosks/:id/quick_buy
  def quick_buy
    item_key = params[:item_key]
    quantity = params[:quantity].to_i

    result = Marketplace::KioskPurchaseService.new(
      character: current_character,
      item_key: item_key,
      quantity: quantity
    ).purchase!

    if result[:success]
      redirect_to marketplace_kiosk_path(@kiosk[:id]), notice: "Purchased #{quantity}x #{item_key.titleize}!"
    else
      redirect_to marketplace_kiosk_path(@kiosk[:id]), alert: result[:error]
    end
  end

  # POST /marketplace_kiosks/:id/quick_sell
  def quick_sell
    item_id = params[:item_id]

    item = current_character.inventory.inventory_items.find(item_id)
    result = Marketplace::KioskSellService.new(
      character: current_character,
      item: item
    ).sell!

    if result[:success]
      redirect_to marketplace_kiosk_path(@kiosk[:id]), notice: "Sold for #{result[:amount]} gold!"
    else
      redirect_to marketplace_kiosk_path(@kiosk[:id]), alert: result[:error]
    end
  end

  private

  def set_kiosk
    @kiosk = Marketplace::Kiosks.find(params[:id])
    redirect_to world_path, alert: "Kiosk not found" unless @kiosk
  end
end
