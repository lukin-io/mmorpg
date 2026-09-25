# frozen_string_literal: true

module Game
  module Clans
    # Invite a free character into the clan (leader/deputy).
    class Invite
      Result = Struct.new(:success, :message, :invitation, keyword_init: true)

      def initialize(actor:, target_name:)
        @actor = actor
        @target_name = target_name.to_s.strip
      end

      def call
        membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless membership
        return fail!(I18n.t("game.clans.invite_denied")) unless membership.clan.can_invite?(actor)

        target = Character.find_by("LOWER(name) = ?", target_name.downcase)
        return fail!(I18n.t("game.clans.invite_missing", name: target_name)) unless target
        return fail!(I18n.t("game.clans.invite_self")) if target.id == actor.id
        return fail!(I18n.t("game.clans.invite_already_member")) if target.clan_membership

        clan = membership.clan
        if ClanInvitation.pending.exists?(clan:, invitee_character: target)
          return fail!(I18n.t("game.clans.invite_duplicate"))
        end

        invitation = ClanInvitation.create!(
          clan:,
          inviter_character: actor,
          invitee_character: target,
          status: "pending"
        )
        Result.new(
          success: true,
          message: I18n.t("game.clans.invite_sent", name: target.name),
          invitation:
        )
      rescue ActiveRecord::RecordInvalid => error
        fail!(error.record.errors.full_messages.to_sentence)
      end

      private

      attr_reader :actor, :target_name

      def fail!(message)
        Result.new(success: false, message:, invitation: nil)
      end
    end
  end
end
