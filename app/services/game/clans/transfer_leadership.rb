# frozen_string_literal: true

module Game
  module Clans
    # Leader transfers leadership to another member, becoming deputy.
    class TransferLeadership
      Result = Struct.new(:success, :message, keyword_init: true)

      def initialize(actor:, successor_character_id:)
        @actor = actor
        @successor_character_id = successor_character_id.to_i
      end

      def call
        actor_membership = actor.clan_membership
        return fail!(I18n.t("game.clans.need_clan")) unless actor_membership
        return fail!(I18n.t("game.clans.transfer_not_leader")) unless actor_membership.role == "leader"

        clan = actor_membership.clan
        successor = clan.clan_memberships.find_by(character_id: successor_character_id)
        return fail!(I18n.t("game.clans.member_missing")) unless successor
        return fail!(I18n.t("game.clans.transfer_self")) if successor.character_id == actor.id

        ActiveRecord::Base.transaction do
          clan.lock!
          actor_membership.lock!
          successor.lock!
          successor.update!(role: "leader")
          actor_membership.update!(role: "deputy")
          clan.update!(leader_character: successor.character)
        end
        Result.new(
          success: true,
          message: I18n.t("game.clans.transferred", name: successor.character.name)
        )
      rescue ActiveRecord::RecordInvalid => error
        fail!(error.record.errors.full_messages.to_sentence)
      end

      private

      attr_reader :actor, :successor_character_id

      def fail!(message)
        Result.new(success: false, message:)
      end
    end
  end
end
