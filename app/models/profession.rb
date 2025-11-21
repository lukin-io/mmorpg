# frozen_string_literal: true

class Profession < ApplicationRecord
  has_many :profession_progresses, dependent: :destroy
  has_many :recipes, dependent: :destroy

  validates :name, :category, presence: true
end

