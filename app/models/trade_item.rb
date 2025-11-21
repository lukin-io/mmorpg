# frozen_string_literal: true

class TradeItem < ApplicationRecord
  belongs_to :trade_session
  belongs_to :owner, class_name: "User"

  validates :quantity, numericality: {greater_than: 0}
end

