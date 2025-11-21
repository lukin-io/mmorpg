# frozen_string_literal: true

class AchievementGrant < ApplicationRecord
  belongs_to :user
  belongs_to :achievement

  validates :source, presence: true
end
