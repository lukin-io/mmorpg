# frozen_string_literal: true

# Helpers for inventory views.
module InventoriesHelper
  SLOT_ICONS = {
    head: "🎩",
    chest: "👕",
    legs: "👖",
    feet: "👢",
    hands: "🧤",
    main_hand: "⚔️",
    off_hand: "🛡️",
    ring_1: "💍",
    ring_2: "💍",
    amulet: "📿"
  }.freeze

  ITEM_TYPE_ICONS = {
    "weapon" => "⚔️",
    "armor" => "🛡️",
    "accessory" => "💍",
    "consumable" => "🧪",
    "material" => "📦",
    "quest" => "📜",
    "misc" => "📄"
  }.freeze

  def equipment_slot_icon(slot)
    SLOT_ICONS[slot.to_sym] || "◻️"
  end

  def item_slot_icon(item_template)
    # Use item's icon if set, otherwise derive from type
    return item_template.icon if item_template.respond_to?(:icon) && item_template.icon.present?

    ITEM_TYPE_ICONS[item_template.item_type] || "📦"
  end
end
