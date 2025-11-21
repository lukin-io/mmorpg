# frozen_string_literal: true

class Leaderboard < ApplicationRecord
  has_many :leaderboard_entries, dependent: :destroy

  validates :name, :scope, :season, :starts_at, :ends_at, presence: true
end

