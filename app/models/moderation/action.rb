# frozen_string_literal: true

module Moderation
  # Action stores a discrete enforcement decision (warnings, bans, mutes, refunds, notes).
  # Usage:
  #   Moderation::Action.create!(ticket:, actor:, action_type: :warning, reason: "Abuse in chat")
  # Returns:
  #   Moderation::Action
  class Action < ApplicationRecord
    enum :action_type, {
      warning: "warning",
      temp_ban: "temp_ban",
      permanent_ban: "permanent_ban",
      mute: "mute",
      trade_lock: "trade_lock",
      premium_refund: "premium_refund",
      quest_adjustment: "quest_adjustment",
      note: "note"
    }, prefix: true

    belongs_to :ticket, class_name: "Moderation::Ticket"
    belongs_to :actor, class_name: "User"
    belongs_to :target_user, class_name: "User", optional: true
    belongs_to :target_character, class_name: "Character", optional: true

    validates :action_type, :reason, presence: true

    before_validation :backfill_targets
    before_save :set_expiration_from_duration

    after_commit :notify_ticket_state, on: :create

    scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

    private

    def backfill_targets
      self.target_user ||= ticket.subject_user
      self.target_character ||= ticket.subject_character
    end

    def set_expiration_from_duration
      return if duration_seconds.blank? || expires_at.present?

      self.expires_at = Time.current + duration_seconds.seconds
    end

    def notify_ticket_state
      Moderation::PenaltyNotifier.call(action: self)
    end
  end
end
