# frozen_string_literal: true

# Server-authored, short-lived action key for tile-local world actions.
class WorldActionOffer < ApplicationRecord
  ACTION_TYPES = %w[
    attack_npc
    enter_building
    search_resources
    fish
    drink
    dig
    city_transition
    enter_city_building
    exit_city
  ].freeze

  OFFER_TTL = 10.minutes

  enum :status, {
    offered: 0,
    accepted: 1,
    completed: 2,
    failed: 3,
    cancelled: 4
  }

  belongs_to :character
  belongs_to :zone
  belongs_to :target, polymorphic: true, optional: true

  validates :x, :y, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :action_type, inclusion: {in: ACTION_TYPES}
  validates :action_key, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :coordinates_within_zone_bounds

  scope :live, -> { offered.where("expires_at > ?", Time.current) }
  scope :at_tile, ->(zone, x, y) { where(zone:, x:, y:) }

  def expired?
    expires_at <= Time.current
  end

  def matches_position?(position)
    position.present? &&
      position.zone_id == zone_id &&
      position.x == x &&
      position.y == y
  end

  def accept!
    update!(status: :accepted, accepted_at: Time.current, error_message: nil)
  end

  def complete!
    update!(status: :completed, completed_at: Time.current, error_message: nil)
  end

  def fail!(message)
    update!(status: :failed, error_message: message)
  end

  private

  def coordinates_within_zone_bounds
    return unless zone && x.is_a?(Integer) && y.is_a?(Integer)

    errors.add(:x, "must be within zone bounds") unless x < zone.width
    errors.add(:y, "must be within zone bounds") unless y < zone.height
  end
end
