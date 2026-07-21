# frozen_string_literal: true

# Tracks the authoritative tile location/state for a character inside a zone.
class CharacterPosition < ApplicationRecord
  enum :state, {
    active: 0
  }

  belongs_to :character
  belongs_to :zone

  validates :x, :y, numericality: {only_integer: true}
  validates :last_turn_number, numericality: {greater_than_or_equal_to: 0}
  validate :coordinates_within_zone_bounds

  def ready_for_action?(cooldown_seconds:)
    active? && (last_action_at.nil? || last_action_at <= cooldown_seconds.seconds.ago)
  end

  private

  def coordinates_within_zone_bounds
    return unless zone && x.is_a?(Integer) && y.is_a?(Integer)

    errors.add(:x, "must be within zone bounds") unless x.between?(0, zone.width - 1)
    errors.add(:y, "must be within zone bounds") unless y.between?(0, zone.height - 1)
  end
end
