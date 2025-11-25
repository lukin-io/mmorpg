# frozen_string_literal: true

class SocialHub < ApplicationRecord
  HUB_TYPES = %w[tavern arena marketplace event_space].freeze

  belongs_to :zone, optional: true
  has_many :social_hub_events, dependent: :destroy

  validates :name, :slug, :hub_type, presence: true
  validates :hub_type, inclusion: {in: HUB_TYPES}

  scope :with_upcoming_events, -> { joins(:social_hub_events).merge(SocialHubEvent.upcoming).distinct }

  def label
    "#{name} (#{hub_type.titleize})"
  end
end
