# frozen_string_literal: true

class ItemTemplate < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :rarity, presence: true
  validates :stat_modifiers, presence: true
  validates :weight, numericality: {greater_than: 0}
  validates :stack_limit, numericality: {greater_than: 0}
  validate :premium_stat_cap

  private

  def premium_stat_cap
    return unless premium?

    total = stat_modifiers.values.compact.map(&:to_i).sum
    errors.add(:stat_modifiers, "premium artifacts must stay cosmetic-balanced") if total > 10
  end
end
