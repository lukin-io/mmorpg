# frozen_string_literal: true

# InventoryItem tracks stack counts, equipment state, and enhancement metadata.
class InventoryItem < ApplicationRecord
  belongs_to :inventory
  belongs_to :item_template

  scope :equipped, -> { where(equipped: true) }

  validates :quantity, numericality: {greater_than: 0}
  validates :weight, :enhancement_level, numericality: {greater_than_or_equal_to: 0}

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

  def broken?
    durable? && current_durability.to_i <= 0
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
      item_template.item_type == "quest" ||
      truthy_property?("quest_item") ||
      truthy_property?("protected") ||
      truthy_property?("locked")
  end

  def decrement_durability!(amount = 1)
    return current_durability unless durable?

    new_value = [current_durability.to_i - amount.to_i, 0].max
    update!(properties: properties.to_h.merge("current_durability" => new_value))
    update!(equipped: false, equipment_slot: nil) if new_value.zero? && equipped?
    new_value
  end

  def reset_durability!
    return unless durable?

    update!(properties: properties.to_h.merge("current_durability" => max_durability.to_i))
  end

  private

  def truthy_property?(key)
    value = properties.to_h[key]
    value == true || value.to_s == "true" || value.to_i == 1
  end
end
