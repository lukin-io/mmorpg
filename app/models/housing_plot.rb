# frozen_string_literal: true

class HousingPlot < ApplicationRecord
  belongs_to :user
  has_many :housing_decor_items, dependent: :destroy

  validates :plot_type, :location_key, presence: true
  validates :upkeep_gold_cost, numericality: {greater_than: 0}

  def upkeep_due?
    next_upkeep_due_at.nil? || next_upkeep_due_at <= Time.current
  end
end
