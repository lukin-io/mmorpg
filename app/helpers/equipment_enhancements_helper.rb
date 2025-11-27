# frozen_string_literal: true

# Helpers for equipment enhancement views.
module EquipmentEnhancementsHelper
  def success_rate_class(rate)
    case rate
    when 80..100 then "high"
    when 50..79 then "medium"
    when 20..49 then "low"
    else "very-low"
    end
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

  def has_materials?(required)
    material = current_character.inventory.inventory_items
      .joins(:item_template)
      .find_by(item_templates: {item_key: required[:material_key]})

    material && material.quantity >= required[:quantity]
  end
end
