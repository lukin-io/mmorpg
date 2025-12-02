# frozen_string_literal: true

# ItemTemplate defines the base attributes for all game items.
# Equipment items have stat modifiers, while materials are used for crafting.
#
# Usage:
#   ItemTemplate.find_by(key: "iron_ore")
#   ItemTemplate.where(item_type: "material")
#
class ItemTemplate < ApplicationRecord
  ITEM_TYPES = %w[equipment material consumable].freeze

  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :rarity, presence: true
  validates :stat_modifiers, presence: true, unless: :material?
  validates :weight, numericality: {greater_than: 0}
  validates :stack_limit, numericality: {greater_than: 0}
  validate :premium_stat_cap

  scope :materials, -> { where(item_type: "material") }
  scope :equipment, -> { where(item_type: "equipment") }

  def material?
    item_type == "material"
  end

  def equipment?
    item_type == "equipment" || item_type.nil?
  end

  private

  def premium_stat_cap
    return unless premium?
    return if material? # Materials don't have stats to cap

    total = stat_modifiers.to_h.values.compact.map(&:to_i).sum
    errors.add(:stat_modifiers, "premium artifacts must stay cosmetic-balanced") if total > 10
  end
end
