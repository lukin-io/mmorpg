# frozen_string_literal: true

class ClanTreasuryItem < ApplicationRecord
  belongs_to :clan
  belongs_to :item_template
  belongs_to :deposited_by_character, class_name: "Character", optional: true

  validates :quantity, numericality: {only_integer: true, greater_than: 0}
end
