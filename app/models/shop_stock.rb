# frozen_string_literal: true

# Durable count of one item at one Shop. A missing maximum is uncaptured
# capacity, never an unlimited quantity or permission to accept player sales.
class ShopStock < ApplicationRecord
  belongs_to :shop_account
  belongs_to :item_template

  validates :item_template_id, uniqueness: {scope: :shop_account_id}
  validates :current, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :maximum, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validate :current_within_capacity

  def out_of_stock?
    current.nil? || current.zero?
  end

  def full?
    maximum.present? && current.present? && current >= maximum
  end

  def accepts_return?
    maximum.present? && current.present? && current < maximum
  end

  private

  def current_within_capacity
    return if current.nil? || maximum.nil? || current <= maximum

    errors.add(:current, "cannot exceed maximum")
  end
end
