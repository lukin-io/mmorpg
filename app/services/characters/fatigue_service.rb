# frozen_string_literal: true

module Characters
  # Neverlands wilderness fatigue: travel adds one or two points, one point
  # naturally clears every three minutes, and Move/Look/Enter lock at 86%.
  class FatigueService
    RECOVERY_INTERVAL = 3.minutes
    OUTDOOR_ACTION_LOCK_PERCENT = 86

    def initialize(character:)
      @character = character
    end

    def current_percent(at: Time.current)
      stored = character.fatigue_percent.to_i.clamp(0, 100)
      return stored if stored.zero?

      elapsed = [at - fatigue_anchor, 0].max
      recovered = (elapsed / RECOVERY_INTERVAL).floor
      [stored - recovered, 0].max
    end

    def outdoor_actions_blocked?(at: Time.current)
      current_percent(at:) >= OUTDOOR_ACTION_LOCK_PERCENT
    end

    def increase!(amount:, at: Time.current)
      points = Integer(amount, exception: false)
      raise ArgumentError, "Fatigue increase must be a positive integer" unless points&.positive?

      character.with_lock do
        character.reload
        updated = [current_percent(at:) + points, 100].min
        character.update!(fatigue_percent: updated, fatigue_updated_at: at)
        updated
      end
    end

    private

    attr_reader :character

    def fatigue_anchor
      character.fatigue_updated_at || character.updated_at || character.created_at || Time.current
    end
  end
end
