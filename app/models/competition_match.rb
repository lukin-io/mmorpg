# frozen_string_literal: true

class CompetitionMatch < ApplicationRecord
  belongs_to :competition_bracket

  validates :round_number, :scheduled_at, presence: true
end
