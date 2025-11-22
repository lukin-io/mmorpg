# frozen_string_literal: true

class Profession < ApplicationRecord
  has_many :profession_progresses, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :gathering_nodes, dependent: :destroy

  validates :name, :category, presence: true
  validates :healing_bonus, numericality: {greater_than_or_equal_to: 0}
end
