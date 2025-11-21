# frozen_string_literal: true

class HousingDecorItem < ApplicationRecord
  belongs_to :housing_plot

  validates :name, presence: true
end
