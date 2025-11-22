# frozen_string_literal: true

module LiveOps
  # Event stores GM-triggered operational commands (spawn NPCs, pause arenas, rollbacks).
  # Usage:
  #   LiveOps::Event.create!(requested_by:, event_type: :spawn_npc, payload: {npc_key: "gm_guard"})
  # Returns:
  #   LiveOps::Event
  class Event < ApplicationRecord
    enum :event_type, {
      spawn_npc: "spawn_npc",
      trigger_event: "trigger_event",
      seed_rewards: "seed_rewards",
      pause_arena: "pause_arena",
      rollback_standings: "rollback_standings",
      escalation_webhook: "escalation_webhook"
    }, prefix: true

    enum :status, {
      pending: "pending",
      executing: "executing",
      completed: "completed",
      failed: "failed"
    }, prefix: true

    enum :severity, {
      normal: "normal",
      elevated: "elevated",
      critical: "critical"
    }, prefix: true

    belongs_to :requested_by, class_name: "User"

    validates :payload, presence: true

    def execute!(runner: LiveOps::CommandRunner.new)
      update!(status: :executing)
      runner.call(event: self)
      update!(status: :completed, executed_at: Time.current)
    rescue => e
      update!(status: :failed, notes: [notes, e.message].compact.join("\n"))
      Moderation::Instrumentation.track("live_ops.failed", event_id: id, error: e.message)
      raise
    end
  end
end
