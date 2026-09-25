# frozen_string_literal: true

# Player auction listing — items sold for NV (Ashen Trade Hub).
class AuctionListing < ApplicationRecord
  CRAFT_GEAR_PREFIXES = %w[ash_ranger_ ash_warden_ ash_battle_ ash_forager_].freeze
  RARE_MATERIAL_KEYS = %w[
    ash_wolf_pelt mist_spider_silk cinder_drake_scale veil_boar_hide
    ember_cedar_plank drift_alder_wood
  ].freeze

  belongs_to :seller_character, class_name: "Character"
  belongs_to :item_template
  belongs_to :buyer_character, class_name: "Character", optional: true

  validates :price_nv, numericality: {greater_than: 0}
  validates :quantity, numericality: {greater_than: 0}
  validates :status, inclusion: {in: %w[open sold cancelled]}
  validate :item_template_is_craft_trade_good

  scope :open, -> { where(status: "open") }
  scope :craft_goods, -> {
    joins(:item_template).where(
      CRAFT_GEAR_PREFIXES.map { "item_templates.key LIKE ?" }.join(" OR ") +
        " OR item_templates.key IN (?)",
      *CRAFT_GEAR_PREFIXES.map { |prefix| "#{prefix}%" },
      RARE_MATERIAL_KEYS
    )
  }

  def self.listable_template?(template)
    key = template&.key.to_s
    CRAFT_GEAR_PREFIXES.any? { |prefix| key.start_with?(prefix) } || RARE_MATERIAL_KEYS.include?(key)
  end

  private

  def item_template_is_craft_trade_good
    return if self.class.listable_template?(item_template)

    errors.add(:item_template, :invalid)
  end
end
