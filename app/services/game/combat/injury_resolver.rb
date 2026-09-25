# frozen_string_literal: true

module Game
  module Combat
    # Applies injury outcomes after a completed fight.
    #
    # PvP: severity comes only from the assault scroll kind on the match.
    # PvE: light chance of light or medium only — never heavy/combat.
    class InjuryResolver
      Result = Struct.new(:applied, :severity, :message, keyword_init: true)
      PVE_INJURY_CHANCE = 18
      PVE_MEDIUM_SHARE = 6

      def initialize(match:, rng: Random.new, clock: -> { Time.current })
        @match = match
        @rng = rng
        @clock = clock
      end

      def call
        applied = []

        match.arena_participations.players.includes(:character).find_each do |participation|
          character = participation.character
          next unless character

          outcome = resolve_for(participation)
          next unless outcome

          InjuryState.new(character:, clock:).apply!(
            severity: outcome.fetch(:severity),
            duration: outcome.fetch(:duration),
            source_match_id: match.id
          )
          applied << Result.new(
            applied: true,
            severity: outcome.fetch(:severity),
            message: outcome.fetch(:message)
          )
        end

        applied
      end

      private

      attr_reader :match, :rng, :clock

      def resolve_for(participation)
        return unless participation.result.to_s == "defeat"

        if pve_fight?
          pve_defeat_outcome
        else
          pvp_defeat_outcome
        end
      end

      def pve_fight?
        meta = match.metadata.to_h
        meta["source"].to_s == "world_npc" ||
          meta["is_npc_fight"] == true ||
          match.arena_participations.npcs.exists?
      end

      def assault_kind
        meta = match.metadata.to_h
        kind = meta["assault_scroll_kind"].presence
        return AssaultScrolls.normalize_kind(kind) if kind

        return "bloody" if truthy?(meta["combat_trauma"])

        "peaceful"
      end

      def pve_defeat_outcome
        roll = rng.rand(100)
        return if roll >= PVE_INJURY_CHANCE

        if roll < PVE_MEDIUM_SHARE
          {
            severity: "medium",
            duration: 90.minutes,
            message: I18n.t("game.injuries.applied_medium")
          }
        else
          {
            severity: "light",
            duration: 45.minutes,
            message: I18n.t("game.injuries.applied_light")
          }
        end
      end

      def pvp_defeat_outcome
        case assault_kind
        when "peaceful"
          return if rng.rand(100) >= 8

          {
            severity: "light",
            duration: 20.minutes,
            message: I18n.t("game.injuries.applied_light")
          }
        when "bloody"
          {
            severity: "heavy",
            duration: 3.hours,
            message: I18n.t("game.injuries.applied_heavy")
          }
        else # normal
          roll = rng.rand(100)
          if roll < 35
            {
              severity: "medium",
              duration: 2.hours,
              message: I18n.t("game.injuries.applied_medium")
            }
          elsif roll < 70
            {
              severity: "light",
              duration: 45.minutes,
              message: I18n.t("game.injuries.applied_light")
            }
          end
        end
      end

      def truthy?(value)
        value == true || value.to_s == "true" || value.to_i == 1
      end
    end
  end
end
