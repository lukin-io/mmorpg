# frozen_string_literal: true

# Periodic settle when admin arms the controlled tick.
class IdleTickJob < ApplicationJob
  queue_as :default

  def perform
    ctrl = Game::Idle::ControlledTicker.instance!
    return unless ctrl.armed
    return if ctrl.consecutive_error_ticks >= Game::Idle::ControlledTicker::CIRCUIT_ERROR_TICKS

    Game::Idle::ControlledTicker.new.run_once!
    IdleTickJob.set(wait: (ctrl.tick_ms / 1000.0).seconds).perform_later if ctrl.reload.armed
  end
end
