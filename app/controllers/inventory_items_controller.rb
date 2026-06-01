# frozen_string_literal: true

# Controller for individual inventory item actions (destroy).
class InventoryItemsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # DELETE /inventory/items/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])
    result = Game::Inventory::Manager.discard_item(item)

    if result[:success]
      redirect_to inventory_redirect_path, notice: result[:message]
    else
      redirect_to inventory_redirect_path, alert: result[:error]
    end
  end

  private

  def inventory_redirect_path
    category = params[:category].presence
    return inventory_path if category.blank? || category == "all"

    inventory_path(category:, subcategory: params[:subcategory], info: params[:info])
  end
end
