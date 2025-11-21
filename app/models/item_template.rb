# frozen_string_literal: true

class ItemTemplate < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slot, presence: true
  validates :rarity, presence: true
  validates :stat_modifiers, presence: true
end
