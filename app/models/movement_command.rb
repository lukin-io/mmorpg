# frozen_string_literal: true

# MovementCommand stores server-authoritative movement offers and travel state.
class MovementCommand < ApplicationRecord
  DIRECTIONS = %w[north south east west northeast southeast southwest northwest].freeze
  OFFER_TTL = 10.minutes

  enum :status, {
    offered: 0,
    moving: 1,
    completed: 2,
    cancelled: 3,
    failed: 4
  }

  belongs_to :character
  belongs_to :zone

  validates :direction, inclusion: {in: DIRECTIONS}
  validates :action_key, presence: true, uniqueness: true
  validates :from_x, :from_y, :target_x, :target_y, numericality: {only_integer: true}
  validates :travel_seconds, numericality: {only_integer: true, greater_than: 0}

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

    (ends_at - Time.current).ceil.clamp(0, travel_seconds)
  end
end
