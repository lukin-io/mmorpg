# frozen_string_literal: true

# Controller for individual inventory item actions (destroy).
class InventoryItemsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # DELETE /inventory/items/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])

    if item.destroy
      redirect_to inventory_path, notice: "Item discarded."
    else
      redirect_to inventory_path, alert: "Cannot discard item."
    end
  end
end
