# frozen_string_literal: true

module Game
  module WorldEvents
    # Authoritative tournament scoreboard + end-of-event announcements.
    class TournamentScore
      Result = Struct.new(:ok, :message, :score, keyword_init: true)

      def self.record_fish!(character:, amount: 1)
        new.record!(character:, kind: "tournament_fish", amount:)
      end

      def self.record_chaos_win!(character:)
        new.record!(character:, kind: "tournament_chaos", amount: 1)
      end

      def record!(character:, kind:, amount: 1)
        event = WorldLiveEvent.active.of_kind(kind).order(starts_at: :desc).first
        return Result.new(ok: false, message: "inactive") unless event

        if kind == "tournament_chaos"
          band_lo = event.payload.to_h["level_min"].to_i
          band_hi = event.payload.to_h["level_max"].to_i
          lvl = character.level.to_i
          return Result.new(ok: false, message: "band") if band_lo.positive? && (lvl < band_lo || lvl > band_hi)
        end

        scores = event.payload.to_h.fetch("scores", {})
        key = character.id.to_s
        scores[key] = scores[key].to_i + amount.to_i
        event.update!(payload: event.payload.to_h.merge("scores" => scores))
        grant_season_xp!(character)
        Result.new(ok: true, score: scores[key])
      end

      def self.finalize!(event)
        new.finalize!(event)
      end

      def finalize!(event)
        return unless event
        return if event.payload.to_h["finalized"].present?

        scores = event.payload.to_h.fetch("scores", {})
        ranked = scores.sort_by { |_id, pts| -pts.to_i }.first(3)
        lines = ranked.map.with_index(1) do |(id, pts), place|
          name = Character.find_by(id: id.to_i)&.name || "##{id}"
          "#{place}. #{name} — #{pts}"
        end
        body = if lines.empty?
          "Турнир «#{event.title_ru}» завершён без участников."
        else
          "Турнир «#{event.title_ru}» завершён! #{lines.join("; ")}"
        end
        Chat::EventPublisher.new.world_announcement!(
          body:,
          event_key: "world-live-final:#{event.event_key}",
          payload: {"kind" => "#{event.kind}_final", "world_live_event_id" => event.id, "ranking" => ranked}
        )
        event.update!(payload: event.payload.to_h.merge("finalized" => true, "ranking" => ranked))
      end

      private

      def grant_season_xp!(character)
        return unless Game::Seasons::Catalog.active?

        xp = Game::Seasons::Catalog.current.fetch("xp_per_pulse_hour", 10).to_i
        return unless xp.positive?

        Game::Seasons::Progress.new(character:).add_xp!(xp)
      end
    end
  end
end
