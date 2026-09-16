# frozen_string_literal: true

module Arena
  # Called by the guarded match finalizer. Persists at most one injury per
  # defeated player/match and returns injuries for rich log/event projection.
  class InjuryAwarder
    def initialize(match:, rng: Random.new, clock: -> { Time.current })
      @match, @rng, @clock = match, rng, clock
    end

    def call
      @match.arena_participations.players.where(result: :defeat).includes(:character).filter_map do |participation|
        character = participation.character
        character.with_lock do
          next if character.character_injuries.exists?(arena_match: @match)

          count = character.character_injuries.active_at(@clock.call).count
          next if count >= 99

          combat = @match.metadata.to_h["injury_risk"] == "combat"
          risk = @match.trauma_percent.to_i.clamp(0, 100)
          timeout_injury = @match.timed_out? && @match.winning_team.present? && risk.positive?
          severity = if combat
            "combat"
          elsif timeout_injury
            "heavy"
          else
            Game::Combat::Calibration.injury_severity(risk:, chance_roll: @rng.rand(100), severity_roll: @rng.rand(100))
          end
          next unless severity
          duration, penalty, name = {
            "light" => [30.minutes, 5, "Chest muscle hematoma"],
            "medium" => [2.hours, 15, "Muscle strain"],
            "heavy" => [6.hours, 30, "Fracture"],
            "combat" => [24.hours, 40, "Combat injury"]
          }.fetch(severity)
          # Float division preserves fractional duration parts when Rails adds
          # them to a timestamp (2.hours / 4 can otherwise lose half an hour).
          duration += count * (combat ? 6.hours : duration / 4.0)
          character.character_injuries.create!(arena_match: @match, severity:, name:,
            stat_penalty_percent: penalty, expires_at: @clock.call + duration)
        end
      end
    end
  end
end
