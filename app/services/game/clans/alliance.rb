# frozen_string_literal: true

module Game
  module Clans
    # Soft Mist-style alliance pact between two clans (metadata ledger).
    # Does not invent full diplomacy trees — declare / accept / break only.
    class Alliance
      Result = Struct.new(:success, :message, keyword_init: true)
      META_KEY = "alliances"

      def initialize(actor:)
        @actor = actor
      end

      def propose!(target_tag:)
        clan = actor.clan
        return failure(I18n.t("game.clans.need_clan")) unless clan
        return failure(I18n.t("game.clans.alliance_leader_only")) unless actor.clan_membership&.role.in?(%w[leader deputy])

        target = Clan.find_by(tag: target_tag.to_s.upcase.strip)
        return failure(I18n.t("game.clans.alliance_missing")) unless target
        return failure(I18n.t("game.clans.alliance_self")) if target.id == clan.id

        bag = alliances_for(clan)
        return failure(I18n.t("game.clans.alliance_exists")) if bag["accepted"]&.include?(target.id)
        return failure(I18n.t("game.clans.alliance_pending")) if bag["outgoing"]&.include?(target.id)

        bag["outgoing"] = Array(bag["outgoing"]) | [target.id]
        write!(clan, bag)

        their = alliances_for(target)
        their["incoming"] = Array(their["incoming"]) | [clan.id]
        write!(target, their)

        Result.new(success: true, message: I18n.t("game.clans.alliance_proposed", tag: target.tag))
      end

      def accept!(from_clan_id:)
        clan = actor.clan
        return failure(I18n.t("game.clans.need_clan")) unless clan
        return failure(I18n.t("game.clans.alliance_leader_only")) unless actor.clan_membership&.role.in?(%w[leader deputy])

        from_id = from_clan_id.to_i
        bag = alliances_for(clan)
        return failure(I18n.t("game.clans.alliance_no_invite")) unless Array(bag["incoming"]).include?(from_id)

        other = Clan.find_by(id: from_id)
        return failure(I18n.t("game.clans.alliance_missing")) unless other

        bag["incoming"] = Array(bag["incoming"]) - [from_id]
        bag["accepted"] = Array(bag["accepted"]) | [from_id]
        write!(clan, bag)

        theirs = alliances_for(other)
        theirs["outgoing"] = Array(theirs["outgoing"]) - [clan.id]
        theirs["accepted"] = Array(theirs["accepted"]) | [clan.id]
        write!(other, theirs)

        Result.new(success: true, message: I18n.t("game.clans.alliance_accepted", tag: other.tag))
      end

      def break!(other_clan_id:)
        clan = actor.clan
        return failure(I18n.t("game.clans.need_clan")) unless clan
        return failure(I18n.t("game.clans.alliance_leader_only")) unless actor.clan_membership&.role.in?(%w[leader deputy])

        other_id = other_clan_id.to_i
        bag = alliances_for(clan)
        return failure(I18n.t("game.clans.alliance_not_active")) unless Array(bag["accepted"]).include?(other_id)

        other = Clan.find_by(id: other_id)
        bag["accepted"] = Array(bag["accepted"]) - [other_id]
        write!(clan, bag)
        if other
          theirs = alliances_for(other)
          theirs["accepted"] = Array(theirs["accepted"]) - [clan.id]
          write!(other, theirs)
        end
        Result.new(success: true, message: I18n.t("game.clans.alliance_broken"))
      end

      def self.snapshot_for(clan)
        return {accepted: [], incoming: [], outgoing: []} unless clan

        bag = clan.metadata.to_h[META_KEY].to_h
        {
          accepted: Clan.where(id: Array(bag["accepted"])).pluck(:id, :tag, :name),
          incoming: Clan.where(id: Array(bag["incoming"])).pluck(:id, :tag, :name),
          outgoing: Clan.where(id: Array(bag["outgoing"])).pluck(:id, :tag, :name)
        }
      end

      private

      attr_reader :actor

      def alliances_for(clan)
        clan.metadata.to_h[META_KEY].to_h
      end

      def write!(clan, bag)
        clan.update!(metadata: clan.metadata.to_h.merge(META_KEY => bag))
      end

      def failure(message)
        Result.new(success: false, message:)
      end
    end
  end
end
