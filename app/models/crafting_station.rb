# frozen_string_literal: true

class CraftingStation < ApplicationRecord
  has_many :crafting_jobs, dependent: :destroy

  validates :name, :city, :station_type, presence: true

  scope :in_city, ->(city_name) { where(city: city_name) }
end
