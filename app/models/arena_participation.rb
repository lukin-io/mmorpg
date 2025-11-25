# frozen_string_literal: true

class ArenaParticipation < ApplicationRecord
  RESULTS = {
    pending: 0,
    victory: 1,
    defeat: 2,
    draw: 3
  }.freeze

  enum :result, RESULTS

  belongs_to :arena_match
  belongs_to :character
  belongs_to :user

  validates :team, presence: true
end
