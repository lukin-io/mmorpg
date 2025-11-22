# frozen_string_literal: true

# ClassSpecialization defines advanced specializations unlocked via quests.
class ClassSpecialization < ApplicationRecord
  belongs_to :character_class
  has_many :characters, foreign_key: :secondary_specialization_id, dependent: :nullify

  validates :name, presence: true
end
