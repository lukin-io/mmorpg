# frozen_string_literal: true

class Mount < ApplicationRecord
  enum :summon_state, {
    stabled: "stabled",
    summoned: "summoned",
    cooldown: "cooldown"
  }

  belongs_to :user
  belongs_to :mount_stable_slot, optional: true

  validates :name, :mount_type, :faction_key, :rarity, presence: true
  validates :speed_bonus, numericality: {greater_than_or_equal_to: 0}

  scope :with_variant, ->(variant) { where(cosmetic_variant: variant) if variant.present? }

  def travel_multiplier
    1.0 + (speed_bonus.to_f / 100.0)
  end
end
