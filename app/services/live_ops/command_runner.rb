# frozen_string_literal: true

module LiveOps
  # CommandRunner executes GM commands requested via LiveOps::Event records.
  # Usage:
  #   LiveOps::CommandRunner.new.call(event: live_ops_event)
  class CommandRunner
    def initialize(standing_rollback: LiveOps::StandingRollback.new, webhook_dispatcher: Moderation::WebhookDispatcher)
      @standing_rollback = standing_rollback
      @webhook_dispatcher = webhook_dispatcher
    end

    def call(event:)
      @event = event
      case event.event_type
      when "spawn_npc"
        spawn_npc(event.payload)
      when "trigger_event"
        trigger_event(event.payload)
      when "seed_rewards"
        seed_rewards(event.payload)
      when "pause_arena"
        pause_arenas(event.payload)
      when "rollback_standings"
        rollback(event.payload)
      when "escalation_webhook"
        send_escalation(event.payload)
      else
        raise ArgumentError, "Unknown event_type #{event.event_type}"
      end
    end

    private

    attr_reader :standing_rollback, :webhook_dispatcher, :event

    def spawn_npc(payload)
      npc_key = payload.fetch("npc_key")
      zone_key = payload.fetch("zone_key")
      location = payload.fetch("location")
      Game::World::PopulationDirectory.instance.spawn_ephemeral(npc_key:, zone_key:, location:)
    end

    def trigger_event(payload)
      slug = payload.fetch("event_slug")
      event = GameEvent.find_by!(slug:)
      event.update!(status: :active)
      Moderation::Instrumentation.track("live_ops.event_triggered", event_id: event.id, slug:)
    end

    def seed_rewards(payload)
      user_ids = Array(payload["user_ids"])
      user_ids.each do |user_id|
        recipient = User.find_by(id: user_id)
        next unless recipient

        MailMessage.create!(
          sender: event.requested_by,
          recipient:,
          subject: "Live Ops Reward",
          body: payload["message"] || "A GM has granted you a reward.",
          delivered_at: Time.current
        )
      end
    end

    def pause_arenas(payload)
      reason = payload["reason"] || "Paused by GM"
      ArenaTournament.running.update_all(status: ArenaTournament.statuses[:completed])
      Moderation::Instrumentation.track("live_ops.pause_arena", reason:)
    end

    def rollback(payload)
      standing_rollback.call(target_type: payload.fetch("target_type"), target_id: payload.fetch("target_id"))
    end

    def send_escalation(payload)
      webhook_dispatcher.post!(
        message: payload.fetch("message"),
        severity: payload["severity"] || "critical",
        context: payload["context"] || {}
      )
    end
  end
end
