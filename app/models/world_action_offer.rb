# frozen_string_literal: true

# Server-authored, short-lived capability for location-bound World and Shop actions.
class WorldActionOffer < ApplicationRecord
  ACTION_TYPES = %w[
    enter_building
    search_resources
    fish
    drink
    dig
    city_transition
    enter_city_building
    open_location_feature
    exit_city
    board_airship
    shop_buy
    shop_sell
    scroll_attack
  ].freeze
  TIMED_LOCAL_ACTION_TYPES = %w[search_resources fish drink].freeze

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
  validate :local_action_deadline_is_valid

  scope :live, -> { offered.where("expires_at > ?", Time.current) }
  scope :at_tile, ->(zone, x, y) { where(zone:, x:, y:) }
  scope :timed_local_actions, -> {
    accepted.where(action_type: TIMED_LOCAL_ACTION_TYPES).where("metadata ? 'local_action_ends_at'")
  }

  def local_action_ends_at
    value = metadata.to_h["local_action_ends_at"]
    Time.iso8601(value) if value.is_a?(String)
  rescue ArgumentError
    nil
  end

  def local_action_remaining_seconds(at: Time.current)
    deadline = local_action_ends_at
    deadline ? [(deadline - at).ceil, 0].max : 0
  end

  def local_action_result
    value = metadata.to_h["local_action_result"]
    value if value.is_a?(String)
  end

  # Returns the saved immediate result once, serializing concurrent deliveries.
  # The caller resolves ownership/current cell first. Consumption records only
  # presentation delivery; it never changes the accepted result or deadline.
  def consume_local_action_result!(at: Time.current)
    with_lock do
      next unless TIMED_LOCAL_ACTION_TYPES.include?(action_type) && (accepted? || completed?) &&
        local_action_ends_at && local_action_result.present?
      next if metadata.to_h.key?("local_action_result_delivered_at")

      result = local_action_result
      update!(metadata: metadata.to_h.merge("local_action_result_delivered_at" => at.iso8601(6)))
      result
    end
  end

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

  def local_action_deadline_is_valid
    return unless accepted? && metadata.to_h.key?("local_action_ends_at")

    unless TIMED_LOCAL_ACTION_TYPES.include?(action_type) && accepted_at && local_action_ends_at && local_action_ends_at > accepted_at
      errors.add(:metadata, "must have a valid accepted local action deadline")
    end
    errors.add(:metadata, "must have a local action result") if local_action_result.blank?
  end

  def coordinates_within_zone_bounds
    return unless zone && x.is_a?(Integer) && y.is_a?(Integer)

    errors.add(:x, "must be within zone bounds") unless x < zone.width
    errors.add(:y, "must be within zone bounds") unless y < zone.height
  end
end
