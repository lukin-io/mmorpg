# frozen_string_literal: true

module Events
  # Transitions events between lifecycle states and toggles feature flags when applicable.
  #
  # Usage:
  #   Events::LifecycleService.new(event).activate!
  class LifecycleService
    def initialize(event, flipper: Flipper)
      @event = event
      @flipper = flipper
    end

    def activate!
      update_state!(:active)
      toggle_flag(true)
    end

    def conclude!(result_payload: {})
      update_state!(:completed, metadata: event.metadata.merge("result" => result_payload))
      toggle_flag(false)
    end

    private

    attr_reader :event, :flipper

    def update_state!(state, metadata: event.metadata)
      event.update!(status: state, metadata:)
    end

    def toggle_flag(enabled)
      return unless event.feature_flag_key

      enabled ? flipper.enable(event.feature_flag) : flipper.disable(event.feature_flag)
    end
  end
end
