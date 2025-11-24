# frozen_string_literal: true

class Profession < ApplicationRecord
  CATEGORIES = {
    production: "production",
    gathering: "gathering",
    support: "support"
  }.freeze

  enum :category, CATEGORIES

  has_many :profession_progresses, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :gathering_nodes, dependent: :destroy
  has_many :profession_tools, dependent: :destroy

  scope :gathering, -> { where(category: "gathering") }
  scope :primary_tracks, -> { where.not(category: "gathering") }

  validates :name, :category, presence: true
  validates :category, inclusion: {in: CATEGORIES.values}
  validates :healing_bonus, numericality: {greater_than_or_equal_to: 0}

  def slot_kind
    return "gathering" if gathering?
    support? ? "support" : "primary"
  end

  def primary_slot?
    !gathering?
  end
end
