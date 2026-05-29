# frozen_string_literal: true

# Helpers for inventory views.
module InventoriesHelper
  INVENTORY_CATEGORIES = [
    ["all", "All"],
    ["equipment", "Things"],
    ["consumables", "Elixirs"],
    ["materials", "Materials"]
  ].freeze

  SLOT_ICONS = {
    head: "Helm",
    amulet: "Neck",
    main_hand: "Wpn",
    belt: "Belt",
    belt_1: "B1",
    belt_2: "B2",
    belt_3: "B3",
    feet: "Boot",
    pocket: "Pckt",
    pocket_1: "P1",
    bracers: "Brac",
    hands: "Glove",
    off_hand: "Shield",
    ring_1: "R1",
    ring_2: "R2",
    ring_3: "R3",
    ring_4: "R4",
    chest: "Armor",
    legs: "Pants",
    relic: "Relic"
  }.freeze

  ITEM_TYPE_ICONS = {
    "equipment" => "EQ",
    "weapon" => "WP",
    "armor" => "AR",
    "accessory" => "AC",
    "consumable" => "EL",
    "material" => "RS",
    "misc" => "IT"
  }.freeze

  def equipment_slot_icon(slot)
    SLOT_ICONS[slot.to_sym] || "◻️"
  end

  def item_slot_icon(item_template)
    # Use item's icon if set, otherwise derive from type
    return item_template.icon if item_template.respond_to?(:icon) && item_template.icon.present?

    ITEM_TYPE_ICONS[item_template.item_type] || "IT"
  end

  def inventory_category_options
    INVENTORY_CATEGORIES
  end

  def inventory_item_properties(item)
    template = item.item_template
    lines = []
    lines << ["Quantity", item.quantity] if item.quantity.to_i > 1
    lines << ["Price", "#{template.base_price} NV"] if template.base_price.to_i.positive?
    lines << ["Durability", inventory_item_durability(item)] if inventory_item_durability(item)

    template.stat_modifiers.to_h.each do |stat, value|
      next if value.blank?

      lines << [stat.to_s.titleize, signed_value(value)]
    end

    item.properties.to_h.fetch("properties", {}).each do |label, value|
      lines << [label.to_s.titleize, value]
    end

    lines.presence || [["Description", template.item_type.to_s.titleize]]
  end

  def inventory_item_requirements(item)
    template = item.item_template
    requirements = template.requirements.to_h.merge(item.properties.to_h.fetch("requirements", {}))
    weight = item.weight.to_i.positive? ? item.weight : template.weight
    lines = [["Mass", weight]]

    requirements.each do |label, value|
      lines << [label.to_s.titleize, value]
    end

    lines
  end

  def inventory_item_durability(item)
    current = item.properties["durability"] || item.properties["current_durability"]
    maximum = item.properties["max_durability"] || item.item_template.durability_max
    return nil if current.blank? && maximum.blank?
    return nil if current.to_i.zero? && maximum.to_i.zero?

    [current || maximum, maximum || current].join("/")
  end

  def inventory_item_durability_percent(item)
    current = (item.properties["durability"] || item.properties["current_durability"]).to_f
    maximum = (item.properties["max_durability"] || item.item_template.durability_max).to_f
    return 100 if maximum <= 0
    return 0 if current <= 0

    ((current / maximum) * 100).clamp(0, 100)
  end

  def signed_value(value)
    numeric = value.to_i
    return value unless numeric.to_s == value.to_s

    numeric.positive? ? "+#{numeric}" : numeric.to_s
  end
end
