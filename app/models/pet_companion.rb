# frozen_string_literal: true

class PetCompanion < ApplicationRecord
  belongs_to :user
  belongs_to :pet_species

  validates :level, numericality: {greater_than_or_equal_to: 1}
end

