# frozen_string_literal: true

module Game
  module World
    # Starts a real arena duel between a registered siege attacker and defender
    # on the fortress cell. Wins accumulate siege_points on the wave; timer end
    # awards the fortress to the clan with the most points (ties → random).
    class FortressSiegeBattle
      class SiegeViolationError < StandardError; end
      Result = Struct.new(:success, :message, :match, keyword_init: true)

      def initialize(attacker:, defender_id:)
        @attacker = attacker
        @defender_id = defender_id.to_i
      end

      def call
        defender = Character.find_by(id: defender_id)
        validate!(defender)

        fortress = fortress_at(attacker.position)
        wave = fortress.siege_wave_key
        attack_part = FortressSiegeParticipant.find_by(
          world_fortress: fortress, character: attacker, wave_key: wave, side: "attack"
        )
        defense_part = FortressSiegeParticipant.find_by(
          world_fortress: fortress, character: defender, wave_key: wave, side: "defense"
        )
        raise SiegeViolationError, I18n.t("game.world.siege_not_registered") unless attack_part && defense_part

        match = nil
        ActiveRecord::Base.transaction do
          attacker.with_lock do
            defender.with_lock do
              match = create_match!(fortress, defender)
              create_participations!(match, defender)
              Arena::CombatProcessor.new(match).start_match
            end
          end
        end
        Result.new(success: true, message: I18n.t("game.world.siege_battle_started", name: fortress.name), match:)
      rescue SiegeViolationError => error
        Result.new(success: false, message: error.message, match: nil)
      end

      def self.record_victory!(match:, winning_team:)
        meta = match.metadata.to_h
        return unless meta["fight_kind"] == "fortress_siege"
        return if winning_team.blank?

        fortress = WorldFortress.find_by(id: meta["fortress_id"])
        return unless fortress&.siege_wave_key.to_s == meta["siege_wave_key"].to_s

        winner = match.arena_participations.players.find_by(team: winning_team)&.character
        return unless winner&.clan_membership

        clan_id = winner.clan_membership.clan_id
        scores = fortress.metadata.to_h.fetch("siege_scores", {})
        wave_scores = scores[fortress.siege_wave_key].to_h
        wave_scores[clan_id.to_s] = wave_scores[clan_id.to_s].to_i + 1
        scores[fortress.siege_wave_key] = wave_scores
        fortress.update!(metadata: fortress.metadata.to_h.merge("siege_scores" => scores))
      end

      private

      attr_reader :attacker, :defender_id

      def validate!(defender)
        raise SiegeViolationError, I18n.t("game.world.assault_missing_target") unless defender
        raise SiegeViolationError, I18n.t("game.world.assault_self") if defender.id == attacker.id
        raise SiegeViolationError, I18n.t("game.flashes.fight_still_active") if StartPlayerAssault.active_match_for?(attacker)
        raise SiegeViolationError, I18n.t("game.world.assault_target_fighting") if StartPlayerAssault.active_match_for?(defender)
        raise SiegeViolationError, I18n.t("game.world.assault_not_nearby") unless StartPlayerAssault.co_located?(attacker, defender)

        fortress = fortress_at(attacker.position)
        raise SiegeViolationError, I18n.t("game.world.fortress_missing") unless fortress
        raise SiegeViolationError, I18n.t("game.world.siege_not_active") unless fortress.under_siege?
      end

      def fortress_at(position)
        return nil unless position

        WorldFortress.active.find_by(zone: position.zone.name, x: position.x, y: position.y)
      end

      def create_match!(fortress, defender)
        ArenaMatch.create!(
          zone: attacker.position.zone,
          match_type: :duel,
          status: :pending,
          turn_timeout_seconds: ArenaMatch::DEFAULT_TURN_TIMEOUT,
          trauma_percent: 5,
          metadata: {
            "source" => "world_pvp",
            "fight_kind" => "fortress_siege",
            "fortress_id" => fortress.id,
            "fortress_key" => fortress.fortress_key,
            "siege_wave_key" => fortress.siege_wave_key,
            "return_context" => "world",
            "zone" => attacker.position.zone.name,
            "x" => attacker.position.x,
            "y" => attacker.position.y,
            "attacker_id" => attacker.id,
            "defender_id" => defender.id
          }
        )
      end

      def create_participations!(match, defender)
        ArenaParticipation.create!(
          arena_match: match, character: attacker, user: attacker.user, team: "a", joined_at: Time.current
        )
        ArenaParticipation.create!(
          arena_match: match, character: defender, user: defender.user, team: "b", joined_at: Time.current
        )
      end
    end
  end
end
