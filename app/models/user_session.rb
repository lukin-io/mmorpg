# frozen_string_literal: true

class UserSession < ApplicationRecord
  STATUS_VALUES = {
    online: "online",
    idle: "idle",
    busy: "busy",
    offline: "offline"
  }.freeze

  belongs_to :user

  enum :status, STATUS_VALUES, suffix: :status

  validates :device_id, :signed_in_at, presence: true
  validates :device_id, uniqueness: {scope: :user_id}

  scope :active, -> { where(status: %w[online idle busy]) }

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

  def mark_busy!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      status: STATUS_VALUES[:busy]
    )
  end

  def mark_offline!(timestamp: Time.current)
    update!(
      last_seen_at: timestamp,
      signed_out_at: timestamp,
      status: STATUS_VALUES[:offline]
    )
  end

  def update_location!(zone: nil, location_label: nil, character: nil)
    update!(
      current_zone_id: zone&.id,
      current_zone_name: zone&.respond_to?(:name) ? zone.name : zone,
      current_location_label: location_label,
      last_character_id: character&.id,
      last_character_name: character&.respond_to?(:name) ? character.name : character,
      last_activity_at: Time.current
    )
  end

  def presence_snapshot
    {
      status: status,
      zone_name: current_zone_name,
      location: current_location_label,
      last_activity_at: last_activity_at,
      character_name: last_character_name
    }
  end
end
