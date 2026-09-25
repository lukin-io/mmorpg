# frozen_string_literal: true

module Game
  module Clans
    # Leader dissolves the clan: memberships, invites, and treasury rows go away.
    # Owned fortresses become unowned (buildings persist on the fortress record).
    class Dissolve
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:)
        @actor = actor
      end

      def call
        membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless membership
        return fail!(I18n.t("game.clans.dissolve_not_leader")) unless membership.role == "leader"

        clan = membership.clan
        name = clan.name
        ActiveRecord::Base.transaction do
          clan.lock!
          WorldFortress.where(owner_clan_id: clan.id).find_each do |fort|
            fort.update!(owner_clan_id: nil, owner_character_id: nil)
          end
          clan.clan_invitations.delete_all
          clan.clan_treasury_items.delete_all
          clan.clan_memberships.delete_all
          clan.destroy!
        end
        Result.new(success: true, message: I18n.t("game.clans.dissolved", name:))
      end

      private

      attr_reader :actor

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
