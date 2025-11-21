# frozen_string_literal: true

class CompetitionBracket < ApplicationRecord
  enum :status, {
    seeding: 0,
    running: 1,
    finished: 2
  }

  belongs_to :game_event
  has_many :competition_matches, dependent: :destroy
end

