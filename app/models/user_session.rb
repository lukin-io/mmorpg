# frozen_string_literal: true

class UserSession < ApplicationRecord
  belongs_to :user

  validates :device_id, :signed_in_at, presence: true
  validates :device_id, uniqueness: {scope: :user_id}

  scope :recent, -> { where(signed_out_at: nil).where("user_sessions.last_seen_at > ?", 5.minutes.ago) }

  def mark_seen!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      signed_out_at: nil
    )
  end

  def close!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      signed_out_at: timestamp
    )
  end
end
