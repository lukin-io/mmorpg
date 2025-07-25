class Item < ApplicationRecord
  validates :name, :item_type, :rarity, presence: true

end
