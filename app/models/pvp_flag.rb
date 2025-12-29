# frozen_string_literal: true

# PvpFlag tracks player PVP status and combat flags.
# A player flagged for PVP can be attacked by other players in PVP-enabled zones.
#
# Flag Types:
#   - voluntary: Player manually enabled PVP mode
#   - hostile_action: Auto-flagged for attacking another player
#   - zone_flag: Flagged by entering a PVP zone
#   - faction_war: Flagged during faction warfare events
#
# Usage:
#   character.pvp_flags.active.exists?  # Check if flagged
#   character.enable_pvp!               # Enable voluntary PVP
#   character.auto_flag_pvp!(:hostile_action, duration: 5.minutes)
#
class PvpFlag < ApplicationRecord
  # Flag duration constants
  VOLUNTARY_DURATION = nil # Permanent until disabled
  HOSTILE_ACTION_DURATION = 5.minutes
  ZONE_FLAG_DURATION = 30.seconds # Lingers after leaving zone
  FACTION_WAR_DURATION = 10.minutes

  belongs_to :character

  enum :flag_type, {
    voluntary: 0,
    hostile_action: 1,
    zone_flag: 2,
    faction_war: 3
  }

  validates :flag_type, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  # Check if flag is currently active
  def active?
    expires_at.nil? || expires_at > Time.current
  end

  # Check if flag has expired
  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Time remaining until flag expires
  def time_remaining
    return nil if expires_at.nil?

    [(expires_at - Time.current).to_i, 0].max
  end

  # Extend flag duration
  def extend!(additional_time)
    return unless expires_at

    update!(expires_at: expires_at + additional_time)
  end

  # Cancel flag early (for voluntary flags)
  def cancel!
    destroy if voluntary?
  end

  class << self
    # Clean up expired flags (called by background job)
    def cleanup_expired!
      expired.delete_all
    end
  end
end
