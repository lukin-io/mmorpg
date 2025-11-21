# frozen_string_literal: true

class PetSpecies < ApplicationRecord
  has_many :pet_companions, dependent: :destroy

  validates :name, :ability_type, presence: true
end
