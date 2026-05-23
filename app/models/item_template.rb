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
    case item_type
    when "equipment"
      "equipment"
    when "consumable"
      "consumables"
    when "material"
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

  def equipment_slot_validity
    return unless equipment?
    return if EQUIPMENT_SLOTS.include?(slot) || slot == "none"

    errors.add(:slot, "must be a valid equipment slot for equipment items")
  end
end
