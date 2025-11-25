# frozen_string_literal: true

class HousingDecorItem < ApplicationRecord
  enum :decor_type, {
    furniture: "furniture",
    trophy: "trophy",
    storage: "storage",
    utility: "utility"
  }

  belongs_to :housing_plot

  validates :name, presence: true
  validates :decor_type, presence: true
  validates :placement, presence: true
  validate :utility_slot_within_limits

  scope :trophy, -> { where(decor_type: :trophy) }
  scope :utility, -> { where(decor_type: :utility) }

  store_accessor :metadata, :buff_key, :storage_capacity

  private

  def utility_slot_within_limits
    return unless decor_type == "utility"

    available = housing_plot.utility_slots - housing_plot.housing_decor_items.utility.where.not(id:).count
    errors.add(:base, "No utility slots available") if available <= 0
  end
end
