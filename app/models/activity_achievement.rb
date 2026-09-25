# frozen_string_literal: true

class ActivityAchievement < ApplicationRecord
  belongs_to :character

  validates :achievement_key, presence: true
  validates :progress, :required, numericality: {greater_than_or_equal_to: 0}
end
