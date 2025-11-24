# frozen_string_literal: true

class TradeItem < ApplicationRecord
  QUALITY_VALUES = %w[common uncommon rare epic legendary mythical].freeze
  CURRENCY_TYPES = %w[gold silver premium_tokens].freeze

  belongs_to :trade_session
  belongs_to :owner, class_name: "User"

  validates :quantity, numericality: {greater_than: 0}, if: -> { item_name.present? }
  validates :currency_amount, numericality: {greater_than: 0}, if: -> { currency_type.present? }
  validates :currency_type, inclusion: {in: CURRENCY_TYPES}, allow_nil: true
  validates :item_name, presence: true, unless: -> { currency_type.present? }
  validates :currency_type, presence: true, unless: -> { item_name.present? }
  validates :item_quality, inclusion: {in: QUALITY_VALUES}, allow_nil: true

  def currency?
    currency_type.present?
  end

  def premium_token?
    currency_type == "premium_tokens"
  end
end
