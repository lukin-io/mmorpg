# frozen_string_literal: true

# MedicalSupplyPool tracks consumable stock per zone infirmary so doctor services
# can deduct crafted supplies when stabilizing players.
class MedicalSupplyPool < ApplicationRecord
  belongs_to :zone

  validates :item_name, presence: true
  validates :available_quantity, numericality: {greater_than_or_equal_to: 0}

  scope :for_zone, ->(zone) { where(zone: zone) }

  def withdraw!(amount)
    raise ArgumentError, "amount must be positive" unless amount.to_i.positive?
    raise StandardError, "insufficient supply" if available_quantity < amount

    decrement!(:available_quantity, amount)
  end

  def restock!(amount)
    raise ArgumentError, "amount must be positive" unless amount.to_i.positive?

    update!(
      available_quantity: available_quantity + amount,
      last_restocked_at: Time.current
    )
  end
end
