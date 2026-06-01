# frozen_string_literal: true

# ItemTemplate defines the base attributes for all game items.
# Equipment items have stat modifiers, while materials cover observed loot.
#
# Purpose: Define base item properties and behaviors.
#
# Inputs:
#   - name: unique item name
#   - item_type: equipment, material, consumable, or misc
#   - slot: equipment slot (head, chest, main_hand, etc.) or "none" for non-equipment
#
# Usage:
#   ItemTemplate.find_by(key: "rat_tail")
#   ItemTemplate.where(item_type: "material")
#   template.equippable?  # => true for equipment items
#   template.equipment_slot  # => "main_hand"
#
class ItemTemplate < ApplicationRecord
  ITEM_TYPES = %w[equipment material consumable misc].freeze
  EQUIPMENT_SLOTS = EquipmentSlots::KEYS
  SLOT_ALIASES = {
    "ring" => "ring_1",
    "weapon" => "main_hand",
    "two_handed" => "main_hand",
    "shield" => "off_hand",
    "weapon_shield" => "off_hand",
    "armor" => "chest",
    "helmet" => "head",
    "boots" => "feet",
    "gloves" => "hands",
    "pants" => "legs",
    "necklace" => "amulet",
    "neck" => "amulet",
    "belt_item" => "belt_1",
    "pocket_item" => "pocket_1"
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :stat_modifiers, presence: true, if: :equipment?
  validates :weight, numericality: {greater_than: 0}
  validates :base_price, :durability_max, numericality: {greater_than_or_equal_to: 0}
  validates :stack_limit, numericality: {greater_than: 0}
  validate :equipment_slot_validity

  scope :materials, -> { where(item_type: "material") }
  scope :equipment, -> { where(item_type: "equipment") }
  scope :consumables, -> { where(item_type: "consumable") }

  # Check if this item is a material
  #
  # @return [Boolean] true if item_type is "material"
  def material?
    item_type == "material"
  end

  # Check if this item is equipment.
  #
  # @return [Boolean] true if item_type is "equipment"
  def equipment?
    item_type == "equipment"
  end

  # Check if this item is a consumable
  #
  # @return [Boolean] true if item_type is "consumable"
  def consumable?
    item_type == "consumable"
  end

  def inventory_category
    inventory_family
  end

  # Check if this item can be equipped
  #
  # @return [Boolean] true if item is equipment with a valid slot
  def equippable?
    equipment? && EQUIPMENT_SLOTS.include?(equipment_slot)
  end

  # Get the equipment slot for this item
  # Maps the `slot` column to standard equipment slot names
  #
  # @return [String] equipment slot name (head, chest, main_hand, etc.)
  def equipment_slot
    return nil unless equipment?

    # The slot column stores the equipment slot directly, with a few
    # Neverlands-facing family aliases for multi-slot groups.
    SLOT_ALIASES.fetch(slot.to_s, slot)
  end

  def two_handed?
    return false unless equipment?

    slot.to_s == "two_handed" ||
      truthy_rule?(stat_modifiers.to_h["two_handed"]) ||
      truthy_rule?(enhancement_rules.to_h["two_handed"]) ||
      truthy_rule?(display_properties["two_handed"])
  end

  def inventory_family
    explicit = enhancement_rules.to_h["inventory_family"]
    return explicit if explicit.present?

    case item_type
    when "equipment"
      "things"
    when "consumable"
      consumable_inventory_family
    when "material"
      "resources"
    else
      "misc"
    end
  end

  def inventory_subcategory
    explicit = enhancement_rules.to_h["subcategory"]
    return explicit if explicit.present?

    case item_type
    when "equipment"
      equipment_subcategory
    when "consumable"
      "potions"
    when "material"
      "resources"
    else
      "misc"
    end
  end

  def display_properties
    enhancement_rules.to_h.fetch("properties", {})
  end

  def description
    enhancement_rules.to_h["description"].presence
  end

  def shop_stock
    enhancement_rules.to_h["shop_stock"].presence || {}
  end

  def shop_stock_limited?
    shop_stock.key?("current") || shop_stock.key?("max")
  end

  def shop_stock_current
    return nil unless shop_stock_limited?

    shop_stock.fetch("current", shop_stock.fetch("max", 0)).to_i
  end

  def shop_stock_max
    return nil unless shop_stock_limited?

    shop_stock.fetch("max", shop_stock_current).to_i
  end

  def out_of_stock?
    shop_stock_limited? && shop_stock_current.to_i <= 0
  end

  def decrement_shop_stock!(quantity)
    return unless shop_stock_limited?

    update_shop_stock!([shop_stock_current.to_i - quantity.to_i, 0].max)
  end

  def increment_shop_stock!(quantity)
    return unless shop_stock_limited?

    max = shop_stock_max
    next_value = shop_stock_current.to_i + quantity.to_i
    next_value = [next_value, max].min if max
    update_shop_stock!(next_value)
  end

  private

  def equipment_slot_validity
    return unless equipment?
    return if EQUIPMENT_SLOTS.include?(slot) || SLOT_ALIASES.key?(slot.to_s) || slot == "none"

    errors.add(:slot, "must be a valid equipment slot for equipment items")
  end

  def consumable_inventory_family
    subcategory = enhancement_rules.to_h["subcategory"].to_s
    return "things" if %w[scrolls aid_kits runes books quest_items].include?(subcategory)

    "elixirs"
  end

  def equipment_subcategory
    return "knives" if stat_modifiers.to_h["weapon_family"].to_s == "knife"

    case equipment_slot
    when "main_hand" then "weapons"
    when "off_hand" then "shields"
    when "head" then "helmets"
    when "chest" then "armor"
    when "feet" then "boots"
    when "legs" then "pants"
    when "belt" then "belts"
    when "hands" then "gloves"
    when "bracers" then "bracers"
    when "amulet", "ring_1", "ring_2", "ring_3", "ring_4" then "jewelry"
    when "relic" then "relics"
    else "misc"
    end
  end

  def update_shop_stock!(current)
    next_stock = shop_stock.merge("current" => current.to_i, "max" => shop_stock_max.to_i)
    update!(enhancement_rules: enhancement_rules.to_h.merge("shop_stock" => next_stock))
  end

  def truthy_rule?(value)
    value == true || value.to_s == "true" || value.to_i == 1
  end
end
