# frozen_string_literal: true

# Immutable gameplay information projected into the persistent chat timeline.
# Gameplay records remain authoritative; this record is a durable player-facing
# notification and audit aid, not an event-sourcing state store.
class GameEvent < ApplicationRecord
  EVENT_TYPES = %w[fight_finished item_found money_found system_information world_announcement].freeze

  enum :event_type, EVENT_TYPES.index_with(&:itself), validate: true

  belongs_to :recipient, class_name: "User", inverse_of: :game_events, optional: true

  validates :event_key, :body, :occurred_at, presence: true
  validates :event_key, length: {maximum: 255}
  validate :payload_must_be_an_object
  validate :audience_must_match_event_type

  scope :visible_to, ->(user) { where(recipient_id: [nil, user&.id].uniq) }
  scope :latest_first, -> { order(occurred_at: :desc, id: :desc) }

  after_create_commit :broadcast_timeline_entry

  def global?
    recipient_id.nil?
  end

  def timeline_at
    occurred_at
  end

  def readonly?
    persisted?
  end

  def destroy
    raise ActiveRecord::ReadOnlyRecord, "game events are immutable"
  end

  private

  def payload_must_be_an_object
    errors.add(:payload, "must be an object") unless payload.is_a?(Hash)
  end

  def audience_must_match_event_type
    if world_announcement? && recipient.present?
      errors.add(:recipient, "must be empty for world announcements")
    elsif !world_announcement? && recipient.nil?
      errors.add(:recipient, "is required for personal game events")
    end
  end

  def broadcast_timeline_entry
    Chat::TimelineBroadcaster.game_event_created(self)
  end
end
