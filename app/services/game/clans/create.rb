# frozen_string_literal: true

module Game
  module Clans
    # Creates a clan at the city Clan Hall: name, tag, light/dark side, optional crest.
    class Create
      Result = Struct.new(:success, :message, :clan, keyword_init: true)

      def initialize(character:, name:, tag:, alignment:, icon_io: nil, require_clan_hall: true)
        @character = character
        @name = name.to_s.strip
        @tag = tag.to_s.strip.upcase
        @alignment = alignment.to_s
        @icon_io = icon_io
        @require_clan_hall = require_clan_hall
      end

      def call
        return fail!(I18n.t("game.clans.already_member")) if character.clan_membership
        return fail!(I18n.t("game.clans.name_blank")) if name.blank?
        return fail!(I18n.t("game.clans.tag_invalid")) unless tag.match?(/\A[A-Z0-9]{2,6}\z/)
        return fail!(I18n.t("game.clans.alignment_invalid")) unless %w[light dark].include?(alignment)
        if require_clan_hall && !Game::World::CityBuildingCatalog.accessible?(
          character:, building_key: "clan_hall"
        )
          return fail!(I18n.t("game.clans.need_clan_hall"))
        end

        clan = nil
        ActiveRecord::Base.transaction do
          key = "clan_#{tag.downcase}_#{SecureRandom.hex(3)}"
          icon_path = nil
          if icon_io.present?
            compressed = IconCompressor.new(io: icon_io, clan_key: key).call
            return fail!(compressed.message) unless compressed.success

            icon_path = compressed.path
          end

          clan = Clan.create!(
            key:,
            name:,
            tag:,
            alignment:,
            icon_path:,
            treasury_locked: true,
            treasury_nv: 0,
            leader_character: character
          )
          ClanMembership.create!(clan:, character:, role: "leader", joined_at: Time.current)
          if character.alignment.to_s == "none" || character.alignment.blank?
            character.update!(alignment:)
          end
        end
        Result.new(success: true, message: I18n.t("game.clans.created", name: clan.name, tag: clan.tag), clan:)
      rescue ActiveRecord::RecordInvalid => error
        fail!(error.record.errors.full_messages.to_sentence)
      end

      private

      attr_reader :character, :name, :tag, :alignment, :icon_io, :require_clan_hall

      def fail!(message)
        Result.new(success: false, message:, clan: nil)
      end
    end
  end
end
