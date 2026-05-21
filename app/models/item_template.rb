# frozen_string_literal: true

# ItemTemplate defines the base attributes for all game items.
# Equipment items have stat modifiers, while materials are used for crafting.
#
# Purpose: Define base item properties and behaviors.
#
# Inputs:
#   - name: unique item name
#   - item_type: equipment, material/resource, consumable, or misc
#   - slot: equipment slot (head, chest, main_hand, etc.) or "none" for non-equipment
#   - rarity: common, uncommon, rare, epic, legendary
#
# Usage:
#   ItemTemplate.find_by(key: "iron_ore")
#   ItemTemplate.where(item_type: "material")
#   template.equippable?  # => true for equipment items
#   template.equipment_slot  # => "main_hand"
#
class ItemTemplate < ApplicationRecord
  ITEM_TYPES = %w[equipment material resource consumable misc].freeze
  EQUIPMENT_SLOTS = EquipmentSlots::KEYS
  RARITIES = %w[common uncommon rare epic legendary].freeze

  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :rarity, presence: true, inclusion: {in: RARITIES}
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
    %w[material resource].include?(item_type)
  end

  # Check if this item is equipment
  #
  # @return [Boolean] true if item_type is "equipment" or nil
  def equipment?
    item_type == "equipment" || item_type.nil?
  end

  # Check if this item is a consumable
  #
  # @return [Boolean] true if item_type is "consumable"
  def consumable?
    item_type == "consumable"
  end

  def inventory_category
    case item_type
    when "equipment"
      "equipment"
    when "consumable"
      "consumables"
    when "material", "resource"
      "materials"
    else
      "other"
    end
  end

  # Check if this item can be equipped
  #
  # @return [Boolean] true if item is equipment with a valid slot
  def equippable?
    equipment? && EQUIPMENT_SLOTS.include?(equipment_slot)
  end

  def resource_respawn_seconds
    positive_template_integer("resource_respawn_seconds") ||
      positive_template_integer("respawn_seconds")
  end

  def resource_spawn_weight
    positive_template_integer("resource_spawn_weight") ||
      positive_template_integer("spawn_weight") ||
      positive_template_integer("spawn_chance")
  end

  # Get the equipment slot for this item
  # Maps the `slot` column to standard equipment slot names
  #
  # @return [String] equipment slot name (head, chest, main_hand, etc.)
  def equipment_slot
    return nil unless equipment?

    # The slot column stores the equipment slot directly
    slot
  end

  private

  def positive_template_integer(key)
    value = template_integer(key)
    value if value&.positive?
  end

  def template_integer(key)
    value = enhancement_rules&.dig(key) ||
      enhancement_rules&.dig("resource", key) ||
      requirements&.dig(key) ||
      requirements&.dig("resource", key)
    return if value.blank?

    Integer(value)
  rescue ArgumentError, TypeError
    nil
  end

  def equipment_slot_validity
    return unless equipment?
    return if EQUIPMENT_SLOTS.include?(slot) || slot == "none"

    errors.add(:slot, "must be a valid equipment slot for equipment items")
  end
end
