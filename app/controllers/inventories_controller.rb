# frozen_string_literal: true

# Controller for inventory management.
#
# Full equipment/bag interface with drag-drop support.
#
class InventoriesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # GET /inventory
  def show
    @inventory = current_character.inventory || current_character.create_inventory!
    @items = @inventory.inventory_items.includes(:item_template).order(:slot_index)
    @equipment = current_character_equipment
    @stats = Characters::VitalsService.new(current_character).stats_summary
  end

  # POST /inventory/equip
  def equip
    item = current_character.inventory.inventory_items.find(params[:item_id])

    result = Game::Inventory::EquipmentService.new(
      character: current_character,
      item: item
    ).equip!

    if result[:success]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inventory_grid", partial: "inventories/grid", locals: {items: current_character.inventory.inventory_items.reload}),
            turbo_stream.replace("equipment_panel", partial: "inventories/equipment", locals: {equipment: current_character_equipment}),
            turbo_stream.replace("stats_panel", partial: "inventories/stats", locals: {stats: Characters::VitalsService.new(current_character).stats_summary})
          ]
        end
        format.html { redirect_to inventory_path, notice: "Item equipped!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :alert, message: result[:error]}) }
        format.html { redirect_to inventory_path, alert: result[:error] }
      end
    end
  end

  # POST /inventory/unequip
  def unequip
    slot = params[:slot].to_sym

    result = Game::Inventory::EquipmentService.new(
      character: current_character,
      slot: slot
    ).unequip!

    if result[:success]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("inventory_grid", partial: "inventories/grid", locals: {items: current_character.inventory.inventory_items.reload}),
            turbo_stream.replace("equipment_panel", partial: "inventories/equipment", locals: {equipment: current_character_equipment}),
            turbo_stream.replace("stats_panel", partial: "inventories/stats", locals: {stats: Characters::VitalsService.new(current_character).stats_summary})
          ]
        end
        format.html { redirect_to inventory_path, notice: "Item unequipped!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("notifications", partial: "shared/notification", locals: {type: :alert, message: result[:error]}) }
        format.html { redirect_to inventory_path, alert: result[:error] }
      end
    end
  end

  # POST /inventory/use
  def use
    item = current_character.inventory.inventory_items.find(params[:item_id])

    result = Game::Inventory::Manager.use_item(current_character, item)

    if result[:success]
      redirect_to inventory_path, notice: result[:message]
    else
      redirect_to inventory_path, alert: result[:error]
    end
  end

  # DELETE /inventory/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])

    if item.destroy
      redirect_to inventory_path, notice: "Item discarded."
    else
      redirect_to inventory_path, alert: "Cannot discard item."
    end
  end

  # POST /inventory/sort
  def sort
    sort_type = params[:sort_type] || "type"

    Game::Inventory::Manager.sort_inventory!(current_character.inventory, by: sort_type.to_sym)

    redirect_to inventory_path, notice: "Inventory sorted."
  end

  private

  def current_character_equipment
    {
      head: equipped_item(:head),
      chest: equipped_item(:chest),
      legs: equipped_item(:legs),
      feet: equipped_item(:feet),
      hands: equipped_item(:hands),
      main_hand: equipped_item(:main_hand),
      off_hand: equipped_item(:off_hand),
      ring_1: equipped_item(:ring_1),
      ring_2: equipped_item(:ring_2),
      amulet: equipped_item(:amulet)
    }
  end

  def equipped_item(slot)
    current_character.inventory.inventory_items.find_by(equipped: true, equipment_slot: slot)
  end
end
