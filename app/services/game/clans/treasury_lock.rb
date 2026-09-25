# frozen_string_literal: true

module Game
  module Clans
    # Lock / unlock clan treasury. Leader, deputy, and treasurer may toggle.
    class TreasuryLock
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:, locked:)
        @actor = actor
        @locked = ActiveModel::Type::Boolean.new.cast(locked)
      end

      def call
        membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless membership
        clan = membership.clan
        return fail!(I18n.t("game.clans.treasury_lock_denied")) unless clan.can_lock_treasury?(actor)

        clan.update!(treasury_locked: locked)
        Result.new(
          success: true,
          message: I18n.t(locked ? "game.clans.treasury_locked" : "game.clans.treasury_unlocked")
        )
      end

      private

      attr_reader :actor, :locked

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
