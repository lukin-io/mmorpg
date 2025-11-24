# frozen_string_literal: true

# ArenaRanking tracks per-character ladder progress for arena tournaments/duels.
class ArenaRanking < ApplicationRecord
  LADDER_TYPES = %w[arena duel skirmish clan].freeze

  belongs_to :character

  validates :rating, :wins, :losses, :streak, numericality: {greater_than_or_equal_to: 0}
  validates :ladder_type, presence: true, inclusion: {in: LADDER_TYPES}

  scope :for_ladder, ->(ladder_type) { where(ladder_type:) }
end
