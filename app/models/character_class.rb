# frozen_string_literal: true

class CharacterClass < ApplicationRecord
  has_many :abilities, dependent: :destroy
  has_many :characters, dependent: :nullify
  has_many :skill_trees, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :base_stats, presence: true
  validates :resource_type, presence: true
end
