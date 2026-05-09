# frozen_string_literal: true

# MovementCommand stores server-authoritative movement offers and travel state.
class MovementCommand < ApplicationRecord
  DIRECTIONS = %w[north south east west northeast southeast southwest northwest].freeze
  OFFER_TTL = 10.minutes

  enum :status, {
    queued: 0,
    processing: 1,
    processed: 2,
    failed: 3,
    offered: 4,
    moving: 5,
    completed: 6,
    cancelled: 7
  }

  belongs_to :character
  belongs_to :zone

  validates :direction, inclusion: {in: DIRECTIONS}
  validates :action_key, uniqueness: true, allow_blank: true
  validates :from_x, :from_y, :target_x, :target_y, numericality: {only_integer: true}, if: :travel_lifecycle?
  validates :travel_seconds, numericality: {only_integer: true, greater_than: 0}, if: :travel_lifecycle?
  validates :action_key, presence: true, if: :offered?

  scope :pending, -> { queued.order(:created_at) }
  scope :active_travel, -> { moving.order(:ends_at) }

  def predicted_position
    return unless predicted_x && predicted_y

    [predicted_x, predicted_y]
  end

  def source_position
    return unless from_x && from_y

    [from_x, from_y]
  end

  def target_position
    return unless target_x && target_y

    [target_x, target_y]
  end

  def expired_offer?
    offered? && created_at <= OFFER_TTL.ago
  end

  def remaining_seconds
    return 0 unless moving? && ends_at

    (ends_at - Time.current).ceil.clamp(0, Game::Movement::TravelTime::MAX_TRAVEL_SECONDS)
  end

  def travel_lifecycle?
    offered? || moving? || completed? || cancelled?
  end
end
