# frozen_string_literal: true

class GameEvent < ApplicationRecord
  enum :status, {
    upcoming: 0,
    active: 1,
    completed: 2,
    cancelled: 3
  }

  has_many :event_schedules, dependent: :destroy
  has_many :competition_brackets, dependent: :destroy

  validates :name, :slug, :starts_at, :ends_at, presence: true
  validates :slug, uniqueness: true

  def feature_flag
    feature_flag_key.presence || "events:#{slug}"
  end
end

