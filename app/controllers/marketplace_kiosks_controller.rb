# frozen_string_literal: true

class MarketplaceKiosksController < ApplicationController
  def index
    @kiosks = policy_scope(MarketplaceKiosk).order(expires_at: :asc)
  end

  def create
    @kiosk = authorize MarketplaceKiosk.new(kiosk_params.merge(seller: current_user))
    if @kiosk.save
      redirect_to marketplace_kiosks_path, notice: "Listing added to kiosk."
    else
      @kiosks = policy_scope(MarketplaceKiosk)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def kiosk_params
    params.require(:marketplace_kiosk).permit(:city, :item_name, :quantity, :price, :expires_at)
  end
end

