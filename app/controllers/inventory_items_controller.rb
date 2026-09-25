# frozen_string_literal: true

# Controller for individual inventory item actions (destroy).
class InventoryItemsController < ApplicationController
  include CurrentCharacterContext
  include OutdoorActionAvailability

  before_action :ensure_active_character!
  around_action :with_available_outdoor_actions
  rescue_from ActiveRecord::RecordNotFound, with: :item_missing

  # DELETE /inventory/items/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])
    result = Game::Inventory::Manager.discard_item(item)

    if result[:success]
      redirect_to inventory_redirect_path, notice: result[:message]
    else
      redirect_to inventory_redirect_path(item_denied: 1), alert: result[:error]
    end
  end

  private

  def item_missing
    redirect_to inventory_path(item_denied: 1),
      alert: I18n.t("game.inventory.item_not_found"),
      status: :see_other
  end

  def inventory_redirect_path(**extra)
    category = params[:category].presence
    base =
      if category.blank? || category == "all"
        {}
      else
        {category:, subcategory: params[:subcategory], info: params[:info]}
      end
    inventory_path(**base.merge(extra.compact))
  end
end
