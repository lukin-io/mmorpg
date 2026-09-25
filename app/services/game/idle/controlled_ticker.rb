# frozen_string_literal: true

module Game
  module Idle
    # Controlled settle ticker — arm/disarm/run-once like Ashen Veil admin idle-settle.
    class ControlledTicker
      CIRCUIT_ERROR_TICKS = 5

      def self.instance!
        IdleTickControl.first_or_create!(armed: false, tick_ms: 60_000, batch_size: 25)
      end

      def status
        ctrl = self.class.instance!
        {
          armed: ctrl.armed,
          tick_ms: ctrl.tick_ms,
          batch: ctrl.batch_size,
          last_tick_at: ctrl.last_tick_at,
          last_ran: ctrl.last_ran,
          last_errors: ctrl.last_errors,
          consecutive_error_ticks: ctrl.consecutive_error_ticks,
          circuit_open: ctrl.consecutive_error_ticks >= CIRCUIT_ERROR_TICKS
        }
      end

      def arm!(tick_ms: nil, batch: nil)
        ctrl = self.class.instance!
        ctrl.update!(
          armed: true,
          tick_ms: (tick_ms || ctrl.tick_ms).to_i.clamp(15_000, 600_000),
          batch_size: (batch || ctrl.batch_size).to_i.clamp(1, 200),
          consecutive_error_ticks: 0
        )
        status
      end

      def disarm!
        self.class.instance!.update!(armed: false)
        status
      end

      def run_once!(batch: nil)
        ctrl = self.class.instance!
        limit = (batch || ctrl.batch_size).to_i.clamp(1, 200)
        ran = 0
        errors = 0
        Character.order(:id).limit(limit).each do |character|
          Game::Activity::Tracker.new(character:).ensure_daily_contracts!
          Game::Activity::Tracker.new(character:).record!(kind: "idle_tick", amount: 1)
          ran += 1
        rescue StandardError
          errors += 1
        end
        consecutive = errors.positive? ? ctrl.consecutive_error_ticks + 1 : 0
        ctrl.update!(
          last_tick_at: Time.current,
          last_ran: ran,
          last_errors: errors,
          consecutive_error_ticks: consecutive,
          armed: consecutive >= CIRCUIT_ERROR_TICKS ? false : ctrl.armed
        )
        status.merge(ran: ran, errors: errors)
      end
    end
  end
end
