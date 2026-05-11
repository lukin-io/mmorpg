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
      redirect_to inventory_path(category: params[:category].presence), notice: result[:message]
    else
      redirect_to inventory_path(category: params[:category].presence), alert: result[:error]
    end
  end
end
