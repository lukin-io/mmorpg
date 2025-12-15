# frozen_string_literal: true

# ItemTemplate defines the base attributes for all game items.
# Equipment items have stat modifiers, while materials are used for crafting.
#
# Purpose: Define base item properties and behaviors.
#
# Inputs:
#   - name: unique item name
#   - item_type: equipment, material, or consumable
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
  ITEM_TYPES = %w[equipment material consumable].freeze
  EQUIPMENT_SLOTS = %w[head chest legs feet hands main_hand off_hand ring_1 ring_2 amulet].freeze
  RARITIES = %w[common uncommon rare epic legendary].freeze

  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :rarity, presence: true, inclusion: {in: RARITIES}
  validates :stat_modifiers, presence: true, unless: :material?
  validates :weight, numericality: {greater_than: 0}
  validates :stack_limit, numericality: {greater_than: 0}
  validate :premium_stat_cap
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

  def premium_stat_cap
    return unless premium?
    return if material? # Materials don't have stats to cap

    total = stat_modifiers.to_h.values.compact.map(&:to_i).sum
    errors.add(:stat_modifiers, "premium artifacts must stay cosmetic-balanced") if total > 10
  end

  def equipment_slot_validity
    return unless equipment?
    return if EQUIPMENT_SLOTS.include?(slot) || slot == "none"

    errors.add(:slot, "must be a valid equipment slot for equipment items")
  end
end
