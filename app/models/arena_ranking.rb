# frozen_string_literal: true

# ArenaRanking tracks per-character ladder progress for arena tournaments/duels.
class ArenaRanking < ApplicationRecord
  belongs_to :character

  validates :rating, :wins, :losses, :streak, numericality: {greater_than_or_equal_to: 0}
end

