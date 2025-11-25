# frozen_string_literal: true

class SocialHubEvent < ApplicationRecord
  enum :status, {
    scheduled: 0,
    live: 1,
    completed: 2,
    cancelled: 3
  }

  belongs_to :social_hub

  validates :title, :starts_at, presence: true

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(starts_at: :asc) }
end
