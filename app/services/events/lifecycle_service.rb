# frozen_string_literal: true

module Events
  # Transitions events between lifecycle states.
  #
  # Usage:
  #   Events::LifecycleService.new(event).activate!
  class LifecycleService
    def initialize(event)
      @event = event
    end

    def activate!
      update_state!(:active)
    end

    def conclude!(result_payload: {})
      update_state!(:completed, metadata: event.metadata.merge("result" => result_payload))
    end

    private

    attr_reader :event

    def update_state!(state, metadata: event.metadata)
      event.update!(status: state, metadata:)
    end
  end
end
