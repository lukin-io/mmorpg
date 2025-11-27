# frozen_string_literal: true

# Controller for equipment enhancement/upgrade workflow.
#
# Allows players to upgrade equipment stats using materials and gold.
#
class EquipmentEnhancementsController < ApplicationController
  include CurrentCharacterContext

  before_action :ensure_active_character!
  before_action :set_item, only: [:show, :enhance, :preview]

  # GET /equipment_enhancements
  def index
    @enhanceable_items = current_character.inventory.inventory_items
      .includes(:item_template)
      .where(item_templates: {enhanceable: true})
      .order("inventory_items.enhanced_level DESC")
    @materials = current_character.inventory.inventory_items
      .includes(:item_template)
      .where(item_templates: {item_type: "material"})
  end

  # GET /equipment_enhancements/:id
  def show
    @current_level = @item.enhanced_level.to_i
    @next_level = @current_level + 1
    @enhancement_cost = calculate_enhancement_cost(@item, @next_level)
    @success_rate = calculate_success_rate(@item, @next_level)
    @required_materials = calculate_required_materials(@item, @next_level)
    @can_enhance = can_enhance?(@item)
  end

  # POST /equipment_enhancements/:id/preview
  def preview
    @current_level = @item.enhanced_level.to_i
    @next_level = @current_level + 1

    @current_stats = @item.item_template.stats || {}
    @preview_stats = calculate_enhanced_stats(@item, @next_level)
    @stat_changes = calculate_stat_changes(@current_stats, @preview_stats)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("enhancement_preview", partial: "equipment_enhancements/preview", locals: {
          item: @item,
          current_stats: @current_stats,
          preview_stats: @preview_stats,
          stat_changes: @stat_changes
        })
      end
    end
  end

  # POST /equipment_enhancements/:id/enhance
  def enhance
    result = Game::Inventory::EnhancementService.new(
      character: current_character,
      item: @item
    ).enhance!

    if result[:success]
      message = result[:level_up] ? "✨ Enhancement successful! +#{@item.reload.enhanced_level}" : "💥 Enhancement failed!"
      redirect_to equipment_enhancement_path(@item), notice: message
    else
      redirect_to equipment_enhancement_path(@item), alert: result[:error]
    end
  end

  private

  def set_item
    @item = current_character.inventory.inventory_items.find(params[:id])
  end

  def calculate_enhancement_cost(item, level)
    base_cost = 100
    multiplier = 1.5**level
    (base_cost * multiplier * (item.item_template.rarity_multiplier || 1)).to_i
  end

  def calculate_success_rate(item, level)
    base_rate = 100
    rate = base_rate - (level * 8)
    rate += (current_character.luck || 0) / 10
    rate.clamp(5, 100)
  end

  def calculate_required_materials(item, level)
    material_key = case item.item_template.item_type
    when "weapon" then "weapon_stone"
    when "armor" then "armor_stone"
    else "enhancement_stone"
    end

    quantity = [level, 1].max
    {material_key: material_key, quantity: quantity}
  end

  def calculate_enhanced_stats(item, level)
    base_stats = item.item_template.stats || {}
    enhanced = {}

    base_stats.each do |stat, value|
      bonus = (value * 0.1 * level).to_i
      enhanced[stat] = value + bonus
    end

    enhanced
  end

  def calculate_stat_changes(current, preview)
    changes = {}
    preview.each do |stat, new_value|
      old_value = current[stat] || 0
      changes[stat] = new_value - old_value
    end
    changes
  end

  def can_enhance?(item)
    return false unless item.item_template.enhanceable?
    return false if item.enhanced_level.to_i >= max_enhancement_level(item)

    cost = calculate_enhancement_cost(item, item.enhanced_level.to_i + 1)
    return false if current_character.gold < cost

    materials = calculate_required_materials(item, item.enhanced_level.to_i + 1)
    has_materials?(materials)
  end

  def max_enhancement_level(item)
    case item.item_template.rarity
    when "common" then 5
    when "uncommon" then 7
    when "rare" then 10
    when "epic" then 12
    when "legendary" then 15
    else 5
    end
  end

  def has_materials?(required)
    material = current_character.inventory.inventory_items
      .joins(:item_template)
      .find_by(item_templates: {item_key: required[:material_key]})

    material && material.quantity >= required[:quantity]
  end
end
