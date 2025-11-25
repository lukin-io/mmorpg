# frozen_string_literal: true

class Achievement < ApplicationRecord
  CATEGORIES = %w[combat crafting exploration social economy].freeze

  enum :category, CATEGORIES.index_with(&:to_s)

  has_many :achievement_grants, dependent: :destroy
  belongs_to :title_reward, class_name: "Title", optional: true

  validates :key, :name, presence: true
  validates :key, uniqueness: true

  scope :ordered_for_showcase, -> { order(display_priority: :desc, points: :desc) }
end
