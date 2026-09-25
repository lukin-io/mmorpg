# frozen_string_literal: true

module Game
  module Clans
    # Leave clan (non-leader) or kick a lower-rank member (leader/deputy).
    class MembershipChange
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:, action:, target_character_id: nil)
        @actor = actor
        @action = action.to_s
        @target_character_id = target_character_id.to_i
      end

      def call
        case action
        when "leave" then leave!
        when "kick" then kick!
        else
          fail!(I18n.t("game.clans.membership_bad_action"))
        end
      end

      private

      attr_reader :actor, :action, :target_character_id

      def leave!
        membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless membership
        return fail!(I18n.t("game.clans.leader_cannot_leave")) if membership.role == "leader"

        name = membership.clan.name
        membership.destroy!
        Result.new(success: true, message: I18n.t("game.clans.left", name:))
      end

      def kick!
        actor_membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless actor_membership
        return fail!(I18n.t("game.clans.manage_denied")) unless actor_membership.clan.can_manage?(actor)

        target = actor_membership.clan.clan_memberships.find_by(character_id: target_character_id)
        return fail!(I18n.t("game.clans.member_missing")) unless target
        return fail!(I18n.t("game.clans.kick_self")) if target.character_id == actor.id
        return fail!(I18n.t("game.clans.kick_leader")) if target.role == "leader"

        actor_rank = Clan::ROLE_RANK.fetch(actor_membership.role, 0)
        target_rank = Clan::ROLE_RANK.fetch(target.role, 0)
        return fail!(I18n.t("game.clans.kick_rank")) if target_rank >= actor_rank

        name = target.character.name
        target.destroy!
        Result.new(success: true, message: I18n.t("game.clans.kicked", name:))
      end

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
