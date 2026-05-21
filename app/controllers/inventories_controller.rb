# frozen_string_literal: true

# Controller for inventory management.
#
# Neverlands-style equipment/bag interface with server-authorized wear/remove
# actions.
#
class InventoriesController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!

  # GET /inventory
  def show
    @inventory = current_character.inventory || current_character.create_inventory!
    @category = params[:category].presence || "all"
    @items = filtered_inventory_items(@inventory, @category)
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

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          @inventory = current_character.inventory.reload
          items = filtered_inventory_items(@inventory, current_category)
          stats = Characters::VitalsService.new(current_character).stats_summary

          render turbo_stream: [
            turbo_stream.update("inventory_grid", partial: "inventories/grid", locals: {items:, inventory: @inventory, category: current_category}),
            turbo_stream.update("equipment_panel", partial: "inventories/equipment", locals: {equipment: current_character_equipment}),
            turbo_stream.update("stats_panel", partial: "inventories/stats", locals: {stats: stats})
          ]
        end
        format.html { redirect_to inventory_redirect_path, notice: "Item worn!" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "notifications",
            partial: "shared/notification",
            locals: {type: :alert, message: result[:error]}
          )
        end
        format.html { redirect_to inventory_redirect_path, alert: result[:error] }
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

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          @inventory = current_character.inventory.reload
          items = filtered_inventory_items(@inventory, current_category)
          stats = Characters::VitalsService.new(current_character).stats_summary

          render turbo_stream: [
            turbo_stream.update("inventory_grid", partial: "inventories/grid", locals: {items:, inventory: @inventory, category: current_category}),
            turbo_stream.update("equipment_panel", partial: "inventories/equipment", locals: {equipment: current_character_equipment}),
            turbo_stream.update("stats_panel", partial: "inventories/stats", locals: {stats: stats})
          ]
        end
        format.html { redirect_to inventory_redirect_path, notice: "Item removed!" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "notifications",
            partial: "shared/notification",
            locals: {type: :alert, message: result[:error]}
          )
        end
        format.html { redirect_to inventory_redirect_path, alert: result[:error] }
      end
    end
  end

  # POST /inventory/use
  def use
    item = current_character.inventory.inventory_items.find(params[:item_id])

    result = Game::Inventory::Manager.use_item(current_character, item)

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          @inventory = current_character.inventory.reload
          items = filtered_inventory_items(@inventory, current_category)
          stats = Characters::VitalsService.new(current_character).stats_summary

          render turbo_stream: [
            turbo_stream.update("inventory_grid", partial: "inventories/grid", locals: {items:, inventory: @inventory, category: current_category}),
            turbo_stream.update("stats_panel", partial: "inventories/stats", locals: {stats: stats}),
            turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: result[:message]})
          ]
        end
        format.html { redirect_to inventory_redirect_path, notice: result[:message] }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: {type: "alert", message: result[:error]}
          )
        end
        format.html { redirect_to inventory_redirect_path, alert: result[:error] }
      end
    end
  end

  # DELETE /inventory/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])

    result = Game::Inventory::Manager.discard_item(item)

    if result[:success]
      redirect_to inventory_redirect_path, notice: result[:message]
    else
      redirect_to inventory_redirect_path, alert: result[:error]
    end
  end

  # POST /inventory/sort
  def sort
    sort_type = params[:sort_type] || "type"

    Game::Inventory::Manager.sort_inventory!(current_character.inventory, by: sort_type.to_sym)

    redirect_to inventory_redirect_path, notice: "Inventory sorted."
  end

  private

  def filtered_inventory_items(inventory, category)
    items = inventory.inventory_items.joins(:item_template).includes(:item_template).order(:slot_index)
    return items if category == "all"

    item_types = inventory_category_item_types(category)
    return items if item_types.empty?

    items.where(item_templates: {item_type: item_types})
  end

  def current_category
    params[:category].presence || "all"
  end

  def inventory_redirect_path
    category = current_category
    return inventory_path if category == "all"

    inventory_path(category: category)
  end

  def inventory_category_item_types(category)
    case category
    when "equipment"
      ["equipment"]
    when "consumables"
      ["consumable"]
    when "materials"
      ["material"]
    else
      []
    end
  end

  def current_character_equipment
    EquipmentSlots::ORDERED.to_h do |slot_key, _label|
      [slot_key.to_sym, equipped_item(slot_key)]
    end
  end

  def equipped_item(slot)
    current_character.inventory.inventory_items.find_by(equipped: true, equipment_slot: slot)
  end
end
