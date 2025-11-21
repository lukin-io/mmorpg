# frozen_string_literal: true

class UserSession < ApplicationRecord
  STATUS_VALUES = {
    online: "online",
    idle: "idle",
    offline: "offline"
  }.freeze

  belongs_to :user

  enum :status, STATUS_VALUES, suffix: :status

  validates :device_id, :signed_in_at, presence: true
  validates :device_id, uniqueness: {scope: :user_id}

  scope :active, -> { where(status: %w[online idle]) }

  def mark_active!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      status: STATUS_VALUES[:online],
      signed_out_at: nil
    )
  end

  def mark_idle!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      status: STATUS_VALUES[:idle]
    )
  end

  def mark_offline!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      signed_out_at: timestamp,
      status: STATUS_VALUES[:offline]
    )
  end
end
