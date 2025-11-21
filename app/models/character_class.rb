# frozen_string_literal: true

class CharacterClass < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :base_stats, presence: true
end
