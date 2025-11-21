# frozen_string_literal: true

class HousingPlot < ApplicationRecord
  belongs_to :user
  has_many :housing_decor_items, dependent: :destroy

  validates :plot_type, :location_key, presence: true
end
