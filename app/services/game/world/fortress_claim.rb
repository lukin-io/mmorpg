# frozen_string_literal: true

module Game
  module World
    # Claim / siege a fortress. Requires clan membership. Attack window 14:00–22:00.
    # Whole clan may register on attack or defense for the current wave.
    # When the siege timer ends, a random attacking clan that still has living
    # registrants wins ownership; buildings persist on the fortress.
    class FortressClaim
      SIEGE_DURATION = 1.hour
      Result = Struct.new(:success, :message, :fortress, keyword_init: true)

      def initialize(character:, fortress_key:, side: "attack")
        @character = character
        @fortress_key = fortress_key.to_s
        @side = side.to_s
      end

      def call
        fortress = WorldFortress.active.find_by(fortress_key: fortress_key)
        return failure(I18n.t("game.world.fortress_missing")) unless fortress
        return failure(I18n.t("game.world.character_unavailable")) unless character&.position
        return failure(I18n.t("game.world.fortress_wrong_cell")) unless on_cell?(fortress)

        membership = character.clan_membership
        return failure(I18n.t("game.world.fortress_needs_clan")) unless membership

        clan = membership.clan
        resolve_expired_siege!(fortress)

        character.with_lock do
          fortress.lock!
          fortress.reload
          fortress.ensure_default_buildings!
          Game::Quests::Journal.new(character:).record_fortress_visit!

          if fortress.owner_clan_id.blank?
            claim_empty!(fortress, clan)
          elsif fortress.owner_clan_id == clan.id
            register_defense!(fortress, clan)
          else
            start_or_join_attack!(fortress, clan)
          end
        end
      end

      private

      attr_reader :character, :fortress_key, :side

      def on_cell?(fortress)
        pos = character.position
        pos.zone.name == fortress.zone && pos.x == fortress.x && pos.y == fortress.y
      end

      def claim_empty!(fortress, clan)
        fortress.update!(
          owner_clan: clan,
          owner_character: clan.leader_character,
          siege_ends_at: nil,
          siege_attacker_id: nil,
          siege_wave_key: nil
        )
        success(I18n.t("game.world.fortress_claimed", name: fortress.name), fortress)
      end

      def register_defense!(fortress, clan)
        unless fortress.under_siege?
          return success(I18n.t("game.world.fortress_already_yours", name: fortress.name), fortress)
        end

        register_participant!(fortress, clan, "defense")
        success(I18n.t("game.world.fortress_defense_joined", name: fortress.name), fortress)
      end

      def start_or_join_attack!(fortress, clan)
        unless fortress.siege_window_open?
          return failure(I18n.t(
            "game.world.fortress_window_closed",
            open: WorldFortress::SIEGE_OPEN_HOUR,
            close: WorldFortress::SIEGE_CLOSE_HOUR
          ))
        end

        if fortress.under_siege?
          register_participant!(fortress, clan, "attack")
          return success(I18n.t("game.world.fortress_siege_joined", name: fortress.name), fortress)
        end

        wave = "wave_#{Time.current.to_i}_#{fortress.id}"
        fortress.update!(
          siege_attacker_id: character.id,
          siege_ends_at: SIEGE_DURATION.from_now,
          siege_wave_key: wave,
          siege_opens_at: Time.current,
          siege_closes_at: SIEGE_DURATION.from_now
        )
        register_participant!(fortress, clan, "attack", wave_key: wave)
        # Auto-register defending clan leader as defense if present.
        if fortress.owner_clan
          fortress.owner_clan.characters.limit(50).find_each do |member|
            FortressSiegeParticipant.find_or_create_by!(
              world_fortress: fortress,
              character: member,
              wave_key: wave
            ) do |row|
              row.clan = fortress.owner_clan
              row.side = "defense"
            end
          end
        end
        success(I18n.t("game.world.fortress_siege_started", name: fortress.name), fortress)
      end

      def register_participant!(fortress, clan, participant_side, wave_key: fortress.siege_wave_key)
        return if wave_key.blank?

        FortressSiegeParticipant.find_or_create_by!(
          world_fortress: fortress,
          character:,
          wave_key:
        ) do |row|
          row.clan = clan
          row.side = participant_side
        end
      end

      def resolve_expired_siege!(fortress)
        return unless fortress.siege_ends_at.present? && fortress.siege_ends_at <= Time.current
        return if fortress.siege_wave_key.blank?

        wave = fortress.siege_wave_key
        scores = fortress.metadata.to_h.dig("siege_scores", wave).to_h
        winner = nil
        if scores.any?
          top = scores.values.map(&:to_i).max
          top_clan_ids = scores.select { |_id, pts| pts.to_i == top }.keys.map(&:to_i)
          winner = Clan.find_by(id: top_clan_ids.sample) if top_clan_ids.any?
        end
        unless winner
          attackers = FortressSiegeParticipant.where(
            world_fortress_id: fortress.id, wave_key: wave, side: "attack"
          )
          clan_ids = attackers.distinct.pluck(:clan_id)
          winner = Clan.find_by(id: clan_ids.sample) if clan_ids.any?
        end

        if winner
          fortress.update!(
            owner_clan: winner,
            owner_character: winner.leader_character,
            siege_attacker_id: nil,
            siege_ends_at: nil,
            siege_wave_key: nil,
            siege_opens_at: nil,
            siege_closes_at: nil
          )
        else
          fortress.update!(
            siege_attacker_id: nil,
            siege_ends_at: nil,
            siege_wave_key: nil,
            siege_opens_at: nil,
            siege_closes_at: nil
          )
        end
      end

      def success(message, fortress)
        Result.new(success: true, message:, fortress:)
      end

      def failure(message)
        Result.new(success: false, message:, fortress: nil)
      end
    end
  end
end
