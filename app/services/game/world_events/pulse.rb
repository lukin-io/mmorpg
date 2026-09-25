# frozen_string_literal: true

module Game
  module WorldEvents
    # Spawns Mist-War-style living-world announcements: profession tournaments,
    # chaotic level-band duels, random outdoor ambushes, and city attacks.
    # Ashen rules/copy only — no Mist War IP.
    class Pulse
      TOURNAMENT_FISH_HOURS = 2
      TOURNAMENT_CHAOS_MINUTES = 25
      CITY_ATTACK_MINUTES = 20
      AMBUSH_COOLDOWN = 45.minutes

      def initialize(clock: -> { Time.current }, publisher: Chat::EventPublisher.new, rng: Random.new)
        @clock = clock
        @publisher = publisher
        @rng = rng
      end

      def call(scope: :full)
        expire_stale!
        ensure_tournament_fish!
        ensure_tournament_chaos!
        ensure_season_fair!
        ensure_sector_siege!
        if scope.to_sym == :full
          maybe_random_ambush!
          maybe_city_attack!
        end
        WorldLiveEvent.active.order(starts_at: :desc).limit(8).to_a
      end

      private

      attr_reader :clock, :publisher, :rng

      def now
        clock.call
      end

      def expire_stale!
        WorldLiveEvent.where(status: "active").where("ends_at <= ?", now).find_each(&:end!)
      end

      def ensure_tournament_fish!
        return if WorldLiveEvent.active.of_kind("tournament_fish").exists?

        ends = now + TOURNAMENT_FISH_HOURS.hours
        create_event!(
          kind: "tournament_fish",
          ends_at: ends,
          title_ru: "Турнир рыбаков",
          title_en: "Fisherman tournament",
          body_ru: "На просторах Пепельной Завесы запущен турнир среди рыбаков на сбор Пепельной рыбы. Продлится до #{ends.strftime("%H:%M:%S")} — успей принять участие! Сезон Завесы даёт XP за ежедневные контракты.",
          body_en: "An Ashen Shore fisherman tournament for Ashen catch is live until #{ends.strftime("%H:%M:%S")}. Join in time! Veil Season grants XP from daily contracts.",
          payload: {"resource" => "fish", "score_key" => "tournament_fish_score", "season" => Game::Seasons::Catalog.current_key}
        )
      end

      def ensure_tournament_chaos!
        return if WorldLiveEvent.active.of_kind("tournament_chaos").exists?

        band_lo = [1, rng.rand(8..28)].max
        band_hi = band_lo + 3
        ends = now + TOURNAMENT_CHAOS_MINUTES.minutes
        create_event!(
          kind: "tournament_chaos",
          ends_at: ends,
          title_ru: "Хаотический поединок",
          title_en: "Chaotic duel",
          body_ru: "Хаотический поединок для персонажей #{band_lo}–#{band_hi} уровней запущен. Готовность #{TOURNAMENT_CHAOS_MINUTES} мин. Арена Пепла ждёт.",
          body_en: "Chaotic duel for levels #{band_lo}–#{band_hi} is open for #{TOURNAMENT_CHAOS_MINUTES} min. Ash Arena awaits.",
          payload: {"level_min" => band_lo, "level_max" => band_hi}
        )
      end

      # Mist biweekly cadence: while a season is live, keep a short "fair" FOMO
      # window so the world feels refreshed about every two weeks.
      def ensure_season_fair!
        return unless Game::Seasons::Catalog.active?
        return if WorldLiveEvent.active.of_kind("season_fair").exists?

        season = Game::Seasons::Catalog.current
        starts = Date.iso8601(season.fetch("starts_on"))
        day_index = (now.to_date - starts).to_i
        return unless (day_index % 14).zero? || day_index < 2

        ends = now + 36.hours
        create_event!(
          kind: "season_fair",
          ends_at: ends,
          title_ru: "Ярмарка сезона",
          title_en: "Season fair",
          body_ru: "Ярмарка «#{season["title_ru"]}»: лотки ремесленников, спрос на бирже и XP сезона за турниры. До #{ends.strftime("%d.%m %H:%M")}!",
          body_en: "Fair for «#{season["title_en"]}»: crafter stalls, exchange demand, and season XP from tournaments until #{ends.strftime("%d.%m %H:%M")}!",
          payload: {
            "season" => Game::Seasons::Catalog.current_key,
            "cadence_days" => 14,
            "hint" => "market_stalls"
          }
        )
      end

      # Mist board FOMO: keep at least one fortress under siege for /wars + shell W.
      # Does not transfer ownership — FortressClaim remains the only claim path.
      def ensure_sector_siege!
        live = WorldFortress.active.select(&:under_siege?)
        if live.any?
          return if WorldLiveEvent.active.of_kind("sector_siege").exists?

          fort = live.first
          create_sector_siege_event!(fort, ends_at: fort.siege_ends_at || (now + 1.hour))
          return
        end

        return if WorldLiveEvent.active.of_kind("sector_siege").exists?

        fort = WorldFortress.active.order(:fortress_key).first
        return unless fort

        ends = now + 1.hour
        wave = "pulse:#{now.to_i}"
        scores = {
          "attack" => rng.rand(4..14),
          "defense" => rng.rand(3..12)
        }
        fort.update!(
          siege_ends_at: ends,
          siege_wave_key: wave,
          metadata: fort.metadata.to_h.merge(
            "pulse_siege" => true,
            "siege_scores" => fort.metadata.to_h.fetch("siege_scores", {}).to_h.merge(wave => scores)
          )
        )
        create_sector_siege_event!(fort, ends_at: ends)
      end

      def create_sector_siege_event!(fort, ends_at:)
        create_event!(
          kind: "sector_siege",
          ends_at:,
          title_ru: "Осада сектора",
          title_en: "Sector siege",
          body_ru: "Крепость «#{fort.name}» под осадой до #{ends_at.strftime("%H:%M")}. Открой доску Войн и держи давление!",
          body_en: "Fortress «#{fort.name}» is under siege until #{ends_at.strftime("%H:%M")}. Open the Wars board and hold the pressure!",
          payload: {
            "fortress_key" => fort.fortress_key,
            "zone" => fort.zone,
            "x" => fort.x,
            "y" => fort.y,
            "pulse" => true
          }
        )
      end

      def maybe_random_ambush!
        last = WorldLiveEvent.of_kind("random_ambush").order(starts_at: :desc).first
        return if last&.starts_at && last.starts_at > AMBUSH_COOLDOWN.ago
        return if rng.rand > 0.35

        candidate = outdoor_online_character
        return unless candidate

        npc_label = [
          "Пепельный Оборотень",
          "Храм-Тень II",
          "Соляной Сквернитель",
          "Угольный Страж"
        ].fetch(rng.rand(4))

        fight = AmbushFight.new(character: candidate, npc_label:, rng:).call
        return unless fight.ok && fight.match

        ends = now + 10.minutes
        create_event!(
          kind: "random_ambush",
          ends_at: ends,
          title_ru: "Случайное боевое событие!",
          title_en: "Random combat event!",
          body_ru: "Монстр «#{npc_label}» напал на персонажа #{candidate.name}.",
          body_en: "Monster «#{npc_label}» attacked character #{candidate.name}.",
          payload: {
            "character_id" => candidate.id,
            "character_name" => candidate.name,
            "npc_label" => npc_label,
            "match_id" => fight.match.id
          }
        )
      end

      def maybe_city_attack!
        return if WorldLiveEvent.active.of_kind("city_attack").exists?
        return if rng.rand > 0.22

        ends = now + CITY_ATTACK_MINUTES.minutes
        create_event!(
          kind: "city_attack",
          ends_at: ends,
          title_ru: "Город атакован!",
          title_en: "City under attack!",
          body_ru: "Площадь Угольных Огней под ударом Завесы. Защита доступна у Арены и Зала Клана — соберитесь!",
          body_en: "Coal Fires Square is under Veil assault. Defense open at Arena and Clan Hall — gather!",
          payload: {"zone" => "Город Под Пеплом", "defense" => %w[arena clan_hall]}
        )
      end

      def outdoor_online_character
        recent_ids = UserSession.recent.distinct.pluck(:user_id)
        return if recent_ids.empty?

        Character.joins(:position, :user)
          .where(users: {id: recent_ids})
          .merge(CharacterPosition.joins(:zone).where(zones: {location_type: "outdoor"}))
          .order(Arel.sql("RANDOM()"))
          .limit(1)
          .first
      rescue StandardError
        Character.joins(:user).where(users: {id: recent_ids}).order(Arel.sql("RANDOM()")).first
      end

      def create_event!(kind:, ends_at:, title_ru:, title_en:, body_ru:, body_en:, payload:)
        key = "#{kind}:#{now.to_i}:#{SecureRandom.hex(4)}"
        event = WorldLiveEvent.create!(
          kind:,
          status: "active",
          title_ru:,
          title_en:,
          body_ru:,
          body_en:,
          payload:,
          starts_at: now,
          ends_at:,
          event_key: key
        )
        publisher.world_announcement!(
          body: "#{title_ru} #{body_ru}",
          event_key: "world-live:#{key}",
          payload: payload.merge("kind" => kind, "world_live_event_id" => event.id)
        )
        event
      end
    end
  end
end
