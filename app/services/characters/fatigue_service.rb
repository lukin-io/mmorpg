# frozen_string_literal: true

module Characters
  # Neverlands wilderness fatigue: travel adds one or two points, one point
  # naturally clears every three minutes, and Move/Look/Enter lock at 86%.
  class FatigueService
    def initialize(character:, rules: Game::World::Rules.default)
      @character = character
      @parameters = rules.fatigue
    end

    def current_percent(at: Time.current)
      stored = character.fatigue_percent.to_i.clamp(0, 100)
      return stored if stored.zero?

      elapsed = [at - fatigue_anchor(at:), 0].max
      recovered = (elapsed / parameters.fetch("recovery_interval_seconds")).floor * parameters.fetch("recovery_points")
      [stored - recovered, 0].max
    end

    def outdoor_actions_blocked?(at: Time.current)
      current_percent(at:) >= parameters.fetch("outdoor_action_lock_percent")
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

    # Applies an explicit source-backed recovery after elapsed natural recovery.
    # Returns the effective points actually removed (bounded at zero). The
    # owning action must serialize and record its one-time effect with its offer.
    def recover!(amount:, at: Time.current)
      unless amount.is_a?(Integer) && amount.positive?
        raise ArgumentError, "Fatigue recovery must be a positive integer"
      end

      character.with_lock do
        character.reload
        current = current_percent(at:)
        updated = [current - amount, 0].max
        character.update!(fatigue_percent: updated, fatigue_updated_at: at)
        current - updated
      end
    end

    private

    attr_reader :character, :parameters

    def fatigue_anchor(at:)
      character.fatigue_updated_at || character.updated_at || character.created_at || at
    end
  end
end
