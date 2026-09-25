# frozen_string_literal: true

module Game
  module Clans
    # Leader assigns deputy / treasurer / worker. Cannot demote self away from leader here.
    class SetRole
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:, member_character_id:, role:)
        @actor = actor
        @member_character_id = member_character_id.to_i
        @role = role.to_s
      end

      def call
        return fail!(I18n.t("game.clans.role_invalid")) unless Clan::ROLES.include?(role)
        return fail!(I18n.t("game.clans.role_leader_fixed")) if role == "leader"

        actor_membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless actor_membership
        return fail!(I18n.t("game.clans.manage_denied")) unless actor_membership.role == "leader"

        target = actor_membership.clan.clan_memberships.find_by(character_id: member_character_id)
        return fail!(I18n.t("game.clans.member_missing")) unless target
        return fail!(I18n.t("game.clans.role_self")) if target.character_id == actor.id

        target.update!(role:)
        Result.new(
          success: true,
          message: I18n.t("game.clans.role_set", name: target.character.name, role: I18n.t("game.clans.roles.#{role}"))
        )
      rescue ActiveRecord::RecordInvalid => error
        fail!(error.record.errors.full_messages.to_sentence)
      end

      private

      attr_reader :actor, :member_character_id, :role

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
