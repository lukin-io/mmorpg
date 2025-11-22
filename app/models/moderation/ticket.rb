# frozen_string_literal: true

module Moderation
  # Ticket persists every player report regardless of entry point (chat, profile, combat log, NPC).
  # Usage:
  #   Moderation::Ticket.create!(reporter:, category: :chat_abuse, source: :chat, description: "...", evidence: {})
  # Returns:
  #   Moderation::Ticket
  class Ticket < ApplicationRecord
    BROADCAST_STREAM = "moderation_tickets"

    enum :category, {
      chat_abuse: "chat_abuse",
      botting: "botting",
      griefing: "griefing",
      exploit: "exploit",
      inappropriate_name: "inappropriate_name",
      payment_dispute: "payment_dispute",
      other: "other"
    }, prefix: true

    enum :source, {
      chat: "chat",
      profile: "profile",
      combat_log: "combat_log",
      npc: "npc",
      system: "system"
    }, prefix: true

    enum :status, {
      open: "open",
      triage: "triage",
      investigating: "investigating",
      action_taken: "action_taken",
      appealed: "appealed",
      closed: "closed"
    }, prefix: true

    enum :priority, {
      low: "low",
      normal: "normal",
      high: "high",
      urgent: "urgent"
    }, prefix: true

    belongs_to :reporter, class_name: "User"
    belongs_to :subject_user, class_name: "User", optional: true
    belongs_to :subject_character, class_name: "Character", optional: true
    belongs_to :assigned_moderator, class_name: "User", optional: true

    has_many :actions, class_name: "Moderation::Action", dependent: :destroy, inverse_of: :ticket
    has_many :appeals, class_name: "Moderation::Appeal", dependent: :destroy, inverse_of: :ticket

    has_many :chat_reports, foreign_key: :moderation_ticket_id, dependent: :nullify
    has_many :npc_reports, foreign_key: :moderation_ticket_id, dependent: :nullify

    validates :description, presence: true
    validates :category, :status, :source, :priority, presence: true

    scope :recent, -> { order(created_at: :desc) }
    scope :open_queue, lambda {
      actionable_statuses = statuses.slice("open", "triage", "investigating", "appealed").values
      where(status: actionable_statuses)
    }
    scope :for_zone, ->(zone_key) { where(zone_key:) if zone_key.present? }

    after_create_commit -> { Moderation::TicketBroadcastJob.perform_later(id, event: :created) }
    after_update_commit :broadcast_lifecycle_side_effects

    def reopen!(actor:)
      update!(status: :investigating, assigned_moderator: actor, responded_at: Time.current)
    end

    def mark_action_taken!(actor:)
      update!(status: :action_taken, responded_at: Time.current, assigned_moderator: actor)
    end

    def record_resolution!(actor:)
      update!(status: :closed, resolved_at: Time.current, assigned_moderator: actor)
    end

    def pending_response?
      responded_at.blank?
    end

    def actionable?
      status_open? || status_triage? || status_investigating?
    end

    def should_alert_zone_surge?
      zone_key.present? && created_at >= 1.hour.ago
    end

    private

    def broadcast_lifecycle_side_effects
      event = if saved_change_to_status?
        Moderation::TicketStatusNotifierJob.perform_later(id)
        :status_changed
      else
        :updated
      end

      Moderation::TicketBroadcastJob.perform_later(id, event:)
    end
  end
end
