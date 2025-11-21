# frozen_string_literal: true

class EventSchedule < ApplicationRecord
  belongs_to :game_event

  validates :schedule_type, presence: true
end
