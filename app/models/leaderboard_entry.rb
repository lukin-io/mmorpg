# frozen_string_literal: true

class LeaderboardEntry < ApplicationRecord
  belongs_to :leaderboard

  validates :entity_type, :entity_id, presence: true
  validates :score, numericality: true
end
