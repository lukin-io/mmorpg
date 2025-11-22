# frozen_string_literal: true

class ArenaTournament < ApplicationRecord
  enum :status, {
    scheduled: 0,
    running: 1,
    completed: 2,
    cancelled: 3
  }

  belongs_to :event_instance
  belongs_to :competition_bracket

  validates :name, presence: true
end
