# frozen_string_literal: true

class UserSession < ApplicationRecord
  belongs_to :user

  validates :device_id, :signed_in_at, presence: true
  validates :device_id, uniqueness: {scope: :user_id}

  scope :recent, -> { where(signed_out_at: nil).where("user_sessions.last_seen_at > ?", 5.minutes.ago) }

  # A heartbeat may arrive after logout or after a newer heartbeat. Update only
  # an existing open row without moving its server-observed timestamp backward.
  # Explicit authentication through UserSessionManager owns reopening a row.
  def mark_seen!(timestamp: Time.current)
    return false unless persisted?

    self.class.where(id:, signed_out_at: nil)
      .where("last_seen_at IS NULL OR last_seen_at <= ?", timestamp)
      .update_all(last_seen_at: timestamp, updated_at: timestamp) == 1
  end

  def close!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      signed_out_at: timestamp
    )
  end
end
