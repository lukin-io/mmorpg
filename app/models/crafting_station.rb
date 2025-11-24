# frozen_string_literal: true

class CraftingStation < ApplicationRecord
  ARCHETYPES = {
    city: "city",
    guild_hall: "guild_hall",
    field_kit: "field_kit"
  }.freeze

  enum :station_archetype, ARCHETYPES

  has_many :crafting_jobs, dependent: :destroy

  validates :name, :city, :station_type, presence: true
  validates :station_archetype, inclusion: {in: ARCHETYPES.values}
  validates :time_penalty_multiplier, numericality: {greater_than_or_equal_to: 1}
  validates :success_penalty, numericality: {greater_than_or_equal_to: 0}

  scope :in_city, ->(city_name) { where(city: city_name) }

  def portable?
    self[:portable]
  end

  def duration_for(base_seconds)
    (base_seconds * time_penalty_multiplier.to_f).ceil
  end
end
