# frozen_string_literal: true

# InventoryItem tracks stack counts, equipment state, durability, and per-item
# overrides.
class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item_template

  scope :equipped, -> { where(equipped: true) }

  validates :quantity, numericality: {greater_than: 0}
  validates :weight, numericality: {greater_than_or_equal_to: 0}

  def requirements
    item_template.requirements.to_h.merge(properties.to_h.fetch("requirements", {}))
  end

  def effect_modifiers
    item_template.stat_modifiers.to_h
      .merge(properties.to_h.fetch("stat_modifiers", {}))
      .merge(properties.to_h.fetch("effects", {}))
  end

  def current_durability
    stored = properties.to_h["current_durability"] || properties.to_h["durability"]
    stored.presence || max_durability
  end

  def max_durability
    stored = properties.to_h["max_durability"]
    stored.presence || item_template.durability_max
  end

  def durable?
    max_durability.to_i.positive?
  end

  def two_handed?
    item_template.two_handed?
  end

  def broken?
    durable? && current_durability.to_i <= 0
  end

  # A corrected template maximum must not turn an inconsistent historical item
  # into an inflated Shop payout. This rejects the sale without repairing it.
  def valid_sale_durability?
    !durable? || current_durability.to_d.between?(0, max_durability.to_d)
  end

  def expired?
    expires_at = properties.to_h["expires_at"] || properties.to_h["expires_on"]
    return false if expires_at.blank?

    parsed = Time.zone.parse(expires_at.to_s)
    parsed.present? && parsed.past?
  rescue ArgumentError
    false
  end

  def protected_from_discard?
    equipped? ||
      bound? ||
      truthy_property?("protected") ||
      truthy_property?("locked")
  end

  # Some source consumables expose Use/Delete but no Transfer/Gift/Sell. Keep
  # this restriction separate from binding, which also prevents discarding.
  def tradable?
    !protected_from_discard? && item_template.enhancement_rules.to_h["personal_only"] != true
  end

  def decrement_durability!(amount = 1)
    with_lock do
      next current_durability unless durable?

      new_value = [current_durability.to_i - amount.to_i, 0].max
      update!(properties: properties.to_h.merge("current_durability" => new_value))
      update!(equipped: false, equipment_slot: nil) if new_value.zero? && equipped?
      new_value
    end
  end

  def reset_durability!
    with_lock do
      next unless durable?

      update!(properties: properties.to_h.merge("current_durability" => max_durability.to_i))
    end
  end

  private

  def truthy_property?(key)
    value = properties.to_h[key]
    value == true || value.to_s == "true" || value.to_i == 1
  end
end
