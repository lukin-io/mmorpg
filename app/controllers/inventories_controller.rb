# frozen_string_literal: true

# Controller for inventory management.
#
# Neverlands-style equipment/bag interface with server-authorized wear/remove
# actions.
#
class InventoriesController < ApplicationController
  include CurrentCharacterContext
  include OutdoorActionAvailability

  before_action :ensure_active_character!
  around_action :with_available_outdoor_actions
  rescue_from ActiveRecord::RecordNotFound, with: :item_missing

  # GET /inventory
  def show
    @inventory = current_character.inventory || current_character.create_inventory!
    @category = current_category
    @subcategory = current_subcategory
    @info_mode = current_info_mode
    @items = filtered_inventory_items(@inventory, @category, @subcategory)
    @equipment = current_character_equipment
    @equipment_sets = Game::Inventory::EquipmentSetService.new(character: current_character).all
    Game::Professions::Templates.ensure_craft_items!
    junk_rows = Game::Shop::JunkBuyback.offer_rows_for(current_character)
    @junk_offer_count = junk_rows.size
    @junk_offer_total = junk_rows.sum { |row| row[:quantity].to_i * row[:price].to_i }
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

          render turbo_stream: [inventory_grid_stream, character_sheet_stream]
        end
        format.html { redirect_to inventory_redirect_path, notice: I18n.t("game.flashes.item_worn") }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: {type: :alert, message: result[:error]}
          ), status: :unprocessable_content
        end
        format.html { redirect_to inventory_redirect_path(equip_denied: 1), alert: result[:error] }
      end
    end
  end

  # POST /inventory/unequip
  def unequip
    slot = params[:slot].presence&.to_sym

    result = Game::Inventory::EquipmentService.new(
      character: current_character,
      slot: slot
    ).unequip!

    respond_to do |format|
      if result[:success]
        format.turbo_stream do
          @inventory = current_character.inventory.reload

          render turbo_stream: [inventory_grid_stream, character_sheet_stream]
        end
        format.html { redirect_to inventory_redirect_path, notice: I18n.t("game.flashes.item_removed") }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: {type: :alert, message: result[:error]}
          ), status: :unprocessable_content
        end
        format.html { redirect_to inventory_redirect_path(equip_denied: 1), alert: result[:error] }
      end
    end
  end

  # POST /inventory/unequip_all
  def unequip_all
    result = Game::Inventory::EquipmentService.new(character: current_character).unequip_all!

    redirect_to inventory_redirect_path, notice: I18n.t("game.flashes.unequip_all", count: result[:count])
  end

  # POST /inventory/use
  def use
    item = current_character.inventory.inventory_items.find(params[:item_id])

    result = Game::Inventory::Manager.use_item(current_character, item)

    respond_to do |format|
      if result[:success]
        if result[:redirect].present?
          format.html { redirect_to result[:redirect], notice: result[:message] }
          format.turbo_stream { redirect_to result[:redirect], notice: result[:message] }
        else
          format.turbo_stream do
            @inventory = current_character.inventory.reload

            render turbo_stream: [
              inventory_grid_stream,
              character_sheet_stream,
              turbo_stream.update("flash", partial: "shared/flash", locals: {type: "notice", message: result[:message]})
            ]
          end
          format.html { redirect_to inventory_redirect_path, notice: result[:message] }
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: {type: "alert", message: result[:error]}
          )
        end
        format.html { redirect_to inventory_redirect_path(use_denied: 1), alert: result[:error] }
      end
    end
  end

  # POST /inventory/buy_scroll
  def buy_scroll
    result = Game::Shop::PremiumScrollPurchase.new(
      character: current_character,
      item_key: params[:item_key]
    ).call

    redirect_to inventory_redirect_path, flash_for_result(result)
  end

  # DELETE /inventory/:id
  def destroy
    item = current_character.inventory.inventory_items.find(params[:id])

    result = Game::Inventory::Manager.discard_item(item)

    if result[:success]
      redirect_to inventory_redirect_path, notice: result[:message]
    else
      redirect_to inventory_redirect_path(use_denied: 1), alert: result[:error]
    end
  end

  # POST /inventory/sort
  def sort
    sort_type = params[:sort_type] || "type"

    Game::Inventory::Manager.sort_inventory!(current_character.inventory, by: sort_type.to_sym)

    redirect_to inventory_redirect_path, notice: I18n.t("game.flashes.inventory_sorted")
  end

  def save_equipment_set
    result = Game::Inventory::EquipmentSetService.new(character: current_character).save!(params[:set_name])

    redirect_after_set_mutation(result)
  end

  def wear_equipment_set
    result = Game::Inventory::EquipmentSetService.new(character: current_character).wear!(params[:set_name])

    redirect_after_set_mutation(result)
  end

  def delete_equipment_set
    result = Game::Inventory::EquipmentSetService.new(character: current_character).delete!(params[:set_name])

    redirect_after_set_mutation(result)
  end

  def transfer_item
    item = current_character.inventory.inventory_items.find(params[:item_id])
    result = transfer_service.transfer_item!(
      item:,
      recipient_name: params[:recipient_name],
      quantity: transfer_quantity
    )

    redirect_after_transfer(result)
  end

  def gift_item
    item = current_character.inventory.inventory_items.find(params[:item_id])
    result = transfer_service.transfer_item!(
      item:,
      recipient_name: params[:recipient_name],
      quantity: transfer_quantity,
      gift: true
    )

    redirect_after_transfer(result)
  end

  def sell_to_player
    item = current_character.inventory.inventory_items.find(params[:item_id])
    result = transfer_service.sell_item!(
      item:,
      recipient_name: params[:recipient_name],
      quantity: transfer_quantity,
      price: params[:price]
    )

    redirect_after_transfer(result)
  end

  def transfer_money
    result = transfer_service.transfer_money!(
      recipient_name: params[:recipient_name],
      amount: params[:amount]
    )

    redirect_after_transfer(result)
  end

  private

  # Both fragments below are re-rendered together after any equip/use action:
  # the carried list and the whole character sheet, because equipping changes
  # the doll, the stat breakdown, and the combat chips at once.
  def inventory_grid_stream
    turbo_stream.update(
      "inventory_grid",
      partial: "inventories/grid",
      locals: {
        items: filtered_inventory_items(@inventory, current_category, current_subcategory),
        inventory: @inventory,
        category: current_category,
        subcategory: current_subcategory,
        info_mode: current_info_mode
      }
    )
  end

  def character_sheet_stream
    turbo_stream.update(
      "equipment_panel",
      partial: "shared/neverlands_character_sheet",
      locals: {
        character: current_character,
        equipment: current_character_equipment,
        interactive: true,
        show_money: true,
        category: current_category,
        subcategory: current_subcategory,
        info_mode: current_info_mode
      }
    )
  end

  def filtered_inventory_items(inventory, category, subcategory)
    items = inventory.inventory_items.where(equipped: false).joins(:item_template).includes(:item_template).order(:slot_index)
    return items if category == "all"

    filtered = items.select { |item| item.item_template.inventory_family == category }
    filtered = filtered.select { |item| item.item_template.inventory_subcategory == subcategory } if subcategory.present? && subcategory != "all"
    InventoryItem.where(id: filtered.map(&:id)).includes(:item_template).order(:slot_index)
  end

  def normalize_category(category)
    case category.to_s
    when "", "all"
      "all"
    when "equipment"
      "things"
    when "consumables"
      "elixirs"
    when "materials"
      "resources"
    else
      category.to_s
    end
  end

  def current_category
    normalize_category(params[:category].presence || "all")
  end

  def current_subcategory
    params[:subcategory].presence || "all"
  end

  def current_info_mode
    params[:info].presence == "short" ? "short" : "full"
  end

  def inventory_redirect_path(**extra)
    category = current_category
    base =
      if category == "all"
        {}
      else
        {category:, subcategory: current_subcategory, info: current_info_mode}
      end
    inventory_path(**base.merge(extra.compact))
  end

  def redirect_after_set_mutation(result)
    extra = result.success ? {} : {set_denied: 1}
    redirect_to inventory_redirect_path(**extra), flash_for_result(result)
  end

  def redirect_after_transfer(result)
    extra = result.success ? {} : {transfer_denied: 1}
    redirect_to inventory_redirect_path(**extra), flash_for_result(result)
  end

  def item_missing
    redirect_to inventory_path(item_denied: 1),
      alert: I18n.t("game.inventory.item_not_found"),
      status: :see_other
  end

  def current_character_equipment
    equipment = EquipmentSlots::ORDERED.to_h do |slot|
      [slot.key.to_sym, equipped_item(slot.key)]
    end

    main_hand = equipment[:main_hand]
    equipment[:off_hand] ||= main_hand if main_hand&.two_handed?
    equipment
  end

  def equipped_item(slot)
    current_character.inventory.inventory_items.find_by(equipped: true, equipment_slot: slot)
  end

  def transfer_service
    @transfer_service ||= Game::Inventory::TransferService.new(character: current_character)
  end

  def transfer_quantity
    params[:quantity].to_i.clamp(1, 99)
  end

  def flash_for_result(result)
    result.success ? {notice: result.message} : {alert: result.message}
  end
end
